import Combine
import CoreML
import Foundation
import UIKit
import WatchConnectivity

extension SleepSessionManager {
    // MARK: - Session Reset

    func resetSession() {
        performOnProcessingQueueSync {
            self.currentEpochPayloads.removeAll()
            self.epochHistory.removeAll()
            self.rawPredictions.removeAll()
            self.rawPredictionHistory.removeAll()
            self.smoothedPredictionHistory.removeAll()
            self.processedPayloadIDSet.removeAll()
            self.processedPayloadIDs.removeAll()
            self.processedWatchEpochDiagnosticIDSet.removeAll()
            self.processedWatchEpochDiagnosticIDs.removeAll()
            self.activeWakeTargetDate = nil
            self.dynamicAlarmTriggered = false
            self.hasLoggedStaleDynamicSkip = false
            self.isConfirming = false
            self.confirmationBuffer.removeAll()
            self.lastHRJumpEpochIndex = 0
            self.sessionStartDate = nil
            self.lastAcceptedPayloadAt = nil
            self.lastWatchStatusTimestamp = 0
            self.sessionState = .idle
            self.clearPersistedSessionState()

            DispatchQueue.main.async {
                self.rawStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                self.officialStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                self.latestEpochSummary = "No 30-second epoch yet".localized(for: self.preferredLang)
                self.latestFeatureSummary = "No features computed yet".localized(for: self.preferredLang)
                self.confirmationProgress = "Idle"
                self.replayStatus = "No backlog activity"
                self.ackStatus = "No acknowledgements yet"
                self.watchQueuedStartDate = nil
                self.watchReadyStartDate = nil
                self.watchPendingPayloadCount = 0
                self.sessionStateDisplay = AnalysisSessionState.idle.label
            }
        }
    }

    // MARK: - Utilities

    func shouldProcessPayload(withID id: UUID) -> Bool {
        guard !processedPayloadIDSet.contains(id) else {
            return false
        }

        processedPayloadIDs.append(id)
        processedPayloadIDSet.insert(id)
        if processedPayloadIDs.count > maxTrackedPayloadIDs {
            let overflowCount = processedPayloadIDs.count - maxTrackedPayloadIDs
            let removedIDs = processedPayloadIDs.prefix(overflowCount)
            processedPayloadIDs.removeFirst(overflowCount)
            removedIDs.forEach { processedPayloadIDSet.remove($0) }
        }
        return true
    }

    func shouldProcessWatchEpochDiagnostic(withID id: UUID) -> Bool {
        guard !processedWatchEpochDiagnosticIDSet.contains(id) else {
            return false
        }

        processedWatchEpochDiagnosticIDs.append(id)
        processedWatchEpochDiagnosticIDSet.insert(id)
        if processedWatchEpochDiagnosticIDs.count > maxTrackedPayloadIDs {
            let overflowCount = processedWatchEpochDiagnosticIDs.count - maxTrackedPayloadIDs
            let removedIDs = processedWatchEpochDiagnosticIDs.prefix(overflowCount)
            processedWatchEpochDiagnosticIDs.removeFirst(overflowCount)
            removedIDs.forEach { processedWatchEpochDiagnosticIDSet.remove($0) }
        }
        return true
    }

    func scheduledMonitoringStartDate(for wakeTargetDate: Date) -> Date {
        let requestedStart = wakeTargetDate.addingTimeInterval(-SmartAlarmManager.monitoringLeadTime)
        if requestedStart <= Date() {
            return Date().addingTimeInterval(2)
        }
        return requestedStart
    }

    func makeWatchCommand(action: String, extra: [String: Any] = [:]) -> [String: Any] {
        var command = extra
        command["action"] = action
        command["commandSequence"] = nextWatchCommandSequence()
        return command
    }

    func nextWatchCommandSequence() -> Int {
        let nextValue = UserDefaults.standard.integer(forKey: WatchCommandKey.sequence) + 1
        UserDefaults.standard.set(nextValue, forKey: WatchCommandKey.sequence)
        return nextValue
    }

    func cancelOutstandingWatchControlTransfers(on session: WCSession) {
        let controlActions: Set<String> = ["startSession", "stopSession", "pauseMonitoring", "syncAlarmState", "stopAlarm"]
        for transfer in session.outstandingUserInfoTransfers {
            guard
                let action = transfer.userInfo["action"] as? String,
                controlActions.contains(action)
            else {
                continue
            }
            transfer.cancel()
        }
    }

    func log(_ message: String) {
        DispatchQueue.main.async {
            self.logs.insert("[\(Date().formatted(date: .omitted, time: .standard))] \(message)", at: 0)
            if self.logs.count > 5000 {
                self.logs.removeLast()
            }
            self.engineLog = message
            self.requestPersistedSessionSave()
        }
    }

    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.epochHistory.removeAll()
            self.rawPredictionHistory.removeAll()
            self.smoothedPredictionHistory.removeAll()
            self.rawPredictions.removeAll()
            self.confirmationBuffer.removeAll()
            self.processedWatchEpochDiagnosticIDSet.removeAll()
            self.processedWatchEpochDiagnosticIDs.removeAll()
            self.requestPersistedSessionSave()
        }
    }

    func extendBackgroundTask() {
        let application = UIApplication.shared
        let previousTask = currentBackgroundTask

        currentBackgroundTask = application.beginBackgroundTask(withName: "SleepProcessing") {
            application.endBackgroundTask(self.currentBackgroundTask)
            self.currentBackgroundTask = .invalid
            self.log("Background task expired")
        }

        if previousTask != .invalid {
            application.endBackgroundTask(previousTask)
        }
    }

    func updateModelStatus(_ status: String) {
        DispatchQueue.main.async {
            self.modelStatus = status
        }
        log(status)
    }

    // MARK: - Math Helpers

    func mean(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    func stdDev(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let avg = mean(of: values)
        let variance = values.reduce(0) { partialResult, value in
            partialResult + pow(value - avg, 2)
        } / Double(values.count)
        return sqrt(variance)
    }

    func log1p(_ x: Double) -> Double {
        return Foundation.log1p(max(x, 0))
    }

    // MARK: - Test Mode

    /// Starts test mode: loads test6.csv and feeds pre-computed features
    /// directly to the model at 0.5s intervals (simulating ~60× real-time).
    func startTestMode() {
        guard !isTestModeRunning else { return }

        guard let csvURL = Bundle.main.url(forResource: "test6", withExtension: "csv") else {
            log("❌ test6.csv not found in bundle")
            return
        }

        guard let csvString = try? String(contentsOf: csvURL, encoding: .utf8) else {
            log("❌ Failed to read test6.csv")
            return
        }

        // Parse CSV
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else {
            log("❌ test6.csv is empty")
            return
        }

        let header = lines[0].replacingOccurrences(of: "\r", with: "").components(separatedBy: ",")

        var rows: [[String: Double]] = []
        var labels: [Int] = []

        for i in 1..<lines.count {
            let cleaned = lines[i].replacingOccurrences(of: "\r", with: "")
            let values = cleaned.components(separatedBy: ",")
            guard values.count == header.count else { continue }

            var row: [String: Double] = [:]
            for (j, col) in header.enumerated() {
                if col == "target" {
                    labels.append(Int(Double(values[j]) ?? 0))
                } else {
                    row[col] = Double(values[j]) ?? 0
                }
            }
            rows.append(row)
        }

        guard !rows.isEmpty else {
            log("❌ No valid rows in test6.csv")
            return
        }

        // Reset state
        resetSession()
        activeWakeTargetDate = Date().addingTimeInterval(3600) // fake target
        dynamicAlarmTriggered = false
        rawPredictions.removeAll()
        rawPredictionHistory.removeAll()
        smoothedPredictionHistory.removeAll()
        sessionStartDate = Date()
        setSessionState(.recording, detail: "Recording (test mode)")
        updateSessionRecoveryStatus("Session restarted")

        testModeRows = rows
        testModeLabels = labels
        testModeIndex = 0

        DispatchQueue.main.async {
            self.isTestModeRunning = true
            self.testModeProgress = "0/\(rows.count)"
        }

        log("🧪 TEST MODE started — \(rows.count) epochs from test6.csv")
        log("🧪 Feeding pre-computed features directly to modello25 at 0.5s/epoch")
        requestPersistedSessionSave()

        // Start timer on main thread (0.5s per epoch = ~60× real-time)
        DispatchQueue.main.async {
            self.testModeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.processNextTestRow()
            }
        }
    }

    func stopTestMode() {
        testModeTimer?.invalidate()
        testModeTimer = nil
        testModeRows.removeAll()
        testModeLabels.removeAll()
        testModeIndex = 0

        DispatchQueue.main.async {
            self.isTestModeRunning = false
            self.testModeProgress = ""
        }

        log("🧪 TEST MODE stopped")
    }

    func processNextTestRow() {
        guard testModeIndex < testModeRows.count else {
            log("🧪 TEST MODE complete — all \(testModeRows.count) epochs processed")
            stopTestMode()
            return
        }

        guard !dynamicAlarmTriggered else {
            log("🧪 ALARM TRIGGERED — stopping test mode at epoch \(testModeIndex)")
            stopTestMode()
            return
        }

        guard let stageModel else {
            log("❌ Model not loaded")
            stopTestMode()
            return
        }

        let featureRow = testModeRows[testModeIndex]
        let groundTruth = testModeIndex < testModeLabels.count ? testModeLabels[testModeIndex] : -1
        let groundTruthLabel = SleepStage(rawValue: groundTruth)?.title ?? "?"

        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: featureRow as [String: NSNumber])
            let prediction = try stageModel.prediction(from: provider)

            guard
                let rawValue = prediction.featureValue(for: "target")?.int64Value,
                let rawStage = SleepStage(rawValue: Int(rawValue))
            else {
                log("🧪 [\(testModeIndex)] Prediction output missing target")
                testModeIndex += 1
                return
            }

            // Smoothing
            rawPredictions.append(rawStage)
            if rawPredictions.count > smoothingWindowSize {
                rawPredictions.removeFirst(rawPredictions.count - smoothingWindowSize)
            }
            let smoothed = modeStage(from: rawPredictions) ?? rawStage
            rawPredictionHistory.append(rawStage)
            if rawPredictionHistory.count > maxStoredPredictionHistory {
                rawPredictionHistory.removeFirst(rawPredictionHistory.count - maxStoredPredictionHistory)
            }
            smoothedPredictionHistory.append(smoothed)
            if smoothedPredictionHistory.count > maxStoredPredictionHistory {
                smoothedPredictionHistory.removeFirst(smoothedPredictionHistory.count - maxStoredPredictionHistory)
            }

            // Match indicator
            let match = rawStage.rawValue == groundTruth ? "✅" : "❌"

            log("🧪 [\(testModeIndex)] Pred: \(rawStage.title) | Smoothed: \(smoothed.title) | True: \(groundTruthLabel) \(match)")

            // Update UI
            DispatchQueue.main.async {
                self.rawStageDisplay = rawStage.title
                self.officialStageDisplay = smoothed.title
                self.testModeProgress = "\(self.testModeIndex + 1)/\(self.testModeRows.count)"
                self.latestFeatureSummary = "Test epoch \(self.testModeIndex) | True: \(groundTruthLabel)"
            }

        } catch {
            log("🧪 [\(testModeIndex)] Prediction error: \(error.localizedDescription)")
        }

        testModeIndex += 1
    }
}

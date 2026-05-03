import Combine
import CoreML
import Foundation
import UIKit
import WatchConnectivity

extension SleepSessionManager {
    // MARK: - Cross-Device Intent Handlers
    
    func handleRelayIntent(_ action: String, payload: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        Task { @MainActor in
            do {
                let dialog = try await NinetyAlarmIntentService.dialogForRelay(
                    action: action,
                    payload: payload
                )
                self.log("Relayed Siri intent: \(action)")
                replyHandler?(["dialog": dialog])
            } catch {
                let message = error.localizedDescription
                self.log("Relayed Siri intent failed: \(action) - \(message)")
                replyHandler?(["error": message])
            }
        }
    }

    // MARK: - Epoch Aggregation

    func recordRawWatchPayload(_ payload: SensorPayload) {
        lastAcceptedPayloadAt = payload.timestamp
        requestPersistedSessionSave()
    }

    func consume(watchEpochDiagnostic diagnostic: WatchEpochDiagnostic) {
        defer {
            requestPersistedSessionSave()
        }

        let stage = diagnostic.smoothedStage.flatMap { SleepStage(rawValue: $0) }
        let rawStage = diagnostic.rawStage.flatMap { SleepStage(rawValue: $0) }
        let stageText = stage?.title ?? diagnostic.stageTitle
        let rawStageText = rawStage?.title ?? diagnostic.stageTitle

        let epoch = EpochAggregate(
            timestamp: diagnostic.timestamp,
            processedAt: diagnostic.processedAt,
            heartRateMean: diagnostic.heartRateMean,
            heartRateStd: diagnostic.heartRateStd,
            heartRateRange: diagnostic.heartRateRange,
            motionMagMean: diagnostic.motionMagMean,
            motionMagMax: diagnostic.motionMagMax,
            motionJerk: diagnostic.motionJerk,
            modelStage: stageText,
            isWatchTestInjected: diagnostic.isTestInjected
        )

        if let lastEpoch = epochHistory.last, diagnostic.timestamp.timeIntervalSince(lastEpoch.timestamp) > 300 {
            epochHistory.removeAll()
            rawPredictions.removeAll()
            rawPredictionHistory.removeAll()
            smoothedPredictionHistory.removeAll()
            currentEpochPayloads.removeAll()
            lastHRJumpEpochIndex = 0
            log("Large Watch epoch gap. Resetting displayed history.")
        }

        currentEpochPayloads.removeAll()
        epochHistory.append(epoch)

        if let rawStage {
            rawPredictions.append(rawStage)
            if rawPredictions.count > smoothingWindowSize {
                rawPredictions.removeFirst(rawPredictions.count - smoothingWindowSize)
            }
            rawPredictionHistory.append(rawStage)
            if rawPredictionHistory.count > maxStoredPredictionHistory {
                rawPredictionHistory.removeFirst(rawPredictionHistory.count - maxStoredPredictionHistory)
            }
        }

        if let stage {
            smoothedPredictionHistory.append(stage)
            if smoothedPredictionHistory.count > maxStoredPredictionHistory {
                smoothedPredictionHistory.removeFirst(smoothedPredictionHistory.count - maxStoredPredictionHistory)
            }
        }

        updateEpochSummary(for: epoch)

        let featureSummary = String(
            format: "Watch epoch | HR %.1f bpm | Motion %.1f | Jerk %.2f",
            epoch.heartRateMean,
            epoch.motionMagMean,
            epoch.motionJerk
        )

        DispatchQueue.main.async {
            self.rawStageDisplay = rawStageText
            self.officialStageDisplay = stageText
            self.latestFeatureSummary = featureSummary
            self.modelStatus = "Watch-side model active"
        }

        log("Watch epoch displayed. Stage: \(stageText)")
    }

    func consume(payload: SensorPayload) {
        defer {
            requestPersistedSessionSave()
        }

        // 1. Inactivity Timeout: If the gap is > 5 minutes, reset buffers
        if let lastTimestamp = currentEpochPayloads.last?.timestamp ?? epochHistory.last?.timestamp {
            let gap = payload.timestamp.timeIntervalSince(lastTimestamp)
            if gap > 300 {
                log("⚠️ Large data gap (\(Int(gap/60)) min). Resetting model history.")
                epochHistory.removeAll()
                rawPredictions.removeAll()
                rawPredictionHistory.removeAll()
                smoothedPredictionHistory.removeAll()
                currentEpochPayloads.removeAll()
                lastHRJumpEpochIndex = 0 // Critical precision fix: must reset this tracking index too!
                
                DispatchQueue.main.async {
                    self.rawStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                    self.officialStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                }
            }
        }
        
        currentEpochPayloads.append(payload)
        let epochStart = currentEpochPayloads.first?.timestamp ?? payload.timestamp
        let epochElapsed = payload.timestamp.timeIntervalSince(epochStart)

        guard epochElapsed >= epochDuration else {
            return
        }

        // Aggregate HR across all payloads in this epoch
        let hrValues = currentEpochPayloads.flatMap(\.hrSamples)
        var hrMean = hrValues.isEmpty ? 0 : hrValues.reduce(0, +) / Double(hrValues.count)
        var hrStd = stdDev(of: hrValues)
        var hrRange = hrValues.isEmpty ? 0 : (hrValues.max()! - hrValues.min()!)

        // 2. Off-wrist detection / Forward-filling (Expected Apple Watch Behavior)
        if hrMean < 30 {
            if let prevEpoch = epochHistory.last {
                hrMean = prevEpoch.heartRateMean
                hrStd = prevEpoch.heartRateStd
                hrRange = prevEpoch.heartRateRange
                // Forward filling standard gaps silently
            } else {
                hrMean = 60.0
                hrStd = 0.0
                hrRange = 0.0
                // Defaulting silently for first epoch if Apple Watch hasn't generated HR yet
            }
        }

        // Aggregate motion magnitude across payloads
        let motionValues = currentEpochPayloads.map(\.motionCount)
        let motionMagMean = motionValues.reduce(0, +) / max(Double(motionValues.count), 1)
        let motionMagMax = motionValues.max() ?? 0

        // Compute jerk (change in motion from previous epoch)
        let previousMotion = epochHistory.last?.motionMagMean ?? motionMagMean
        let motionJerk = abs(motionMagMean - previousMotion)

        let epoch = EpochAggregate(
            timestamp: payload.timestamp,
            processedAt: Date(),
            heartRateMean: hrMean,
            heartRateStd: hrStd,
            heartRateRange: hrRange,
            motionMagMean: motionMagMean,
            motionMagMax: motionMagMax,
            motionJerk: motionJerk,
            modelStage: nil,
            isWatchTestInjected: false
        )

        currentEpochPayloads.removeAll()
        epochHistory.append(epoch)

        // Detect HR jump for minutes_since_last_hr_jump feature
        if epochHistory.count >= 2 {
            let prev = epochHistory[epochHistory.count - 2].heartRateMean
            let curr = epoch.heartRateMean
            if abs(curr - prev) > 5.0 { // >5 BPM jump
                lastHRJumpEpochIndex = epochHistory.count - 1
            }
        }

        updateEpochSummary(for: epoch)

        guard epochHistory.count >= minimumEpochsForFeatures else {
            log("Epoch \(epochHistory.count)/\(minimumEpochsForFeatures) captured. Warming feature buffer.")
            return
        }

        guard let prediction = makePrediction(forEpochAt: epochHistory.count - 1) else {
            return
        }

        updatePredictionState(prediction)
    }

    // MARK: - Feature Engineering

    /// Computes the 25 features required by NeuralWakeUP.mlmodel for a given epoch index.
    ///
    /// Rolling windows:
    ///  - hist2m  = 4 epochs  (4 × 30s = 2 min)
    ///  - hist5m  = 10 epochs (10 × 30s = 5 min)
    ///  - hist10m = 20 epochs (20 × 30s = 10 min)
    func createPaddedWindow(endIndex: Int, requiredCount: Int) -> [EpochAggregate] {
        let availableCount = endIndex + 1
        var window = Array(epochHistory[max(0, endIndex - requiredCount + 1)...endIndex])
        
        // Edge padding: artificially duplicate the earliest known state
        // to stabilize mathematical rolling sums/deviations during abbreviated warmup.
        if availableCount < requiredCount, let earliestKnown = window.first {
            let paddingCount = requiredCount - availableCount
            let padding = Array(repeating: earliestKnown, count: paddingCount)
            window = padding + window
        }
        return window
    }

    func computeFeatures(forEpochAt index: Int) -> [String: Double] {
        let epoch = epochHistory[index]

        // --- Rolling windows (Padded automatically for early predictions) ---
        let epochs2m  = createPaddedWindow(endIndex: index, requiredCount: 4)   // 2 min
        let epochs5m  = createPaddedWindow(endIndex: index, requiredCount: 10)  // 5 min
        let epochs10m = createPaddedWindow(endIndex: index, requiredCount: 20)  // 10 min

        // --- Motion arrays ---
        let motionMags2m  = epochs2m.map(\.motionMagMean)
        let motionMags5m  = epochs5m.map(\.motionMagMean)
        let motionMags10m = epochs10m.map(\.motionMagMean)
        let jerk5m        = epochs5m.map(\.motionJerk)

        // --- HR arrays ---
        let hrMeans5m  = epochs5m.map(\.heartRateMean)
        let hrMeans10m = epochs10m.map(\.heartRateMean)
        let hrStds5m   = epochs5m.map(\.heartRateStd)
        let hrRanges5m = epochs5m.map(\.heartRateRange)

        // --- Motion features ---
        let motionEpochMagMean = epoch.motionMagMean
        let motionEpochMagMax  = epoch.motionMagMax

        let motionHist2mMagMean = mean(of: motionMags2m)
        let motionHist2mMagStd  = stdDev(of: motionMags2m)
        let motionHist5mMagMean = mean(of: motionMags5m)
        let motionHist5mMagStd  = stdDev(of: motionMags5m)
        let motionHist5mMagMax  = motionMags5m.max() ?? 0
        let motionHist5mMagSum  = motionMags5m.reduce(0, +)
        let motionHist10mMagMean = mean(of: motionMags10m)
        let motionHist10mMagStd  = stdDev(of: motionMags10m)

        let motionHist5mJerkStd = stdDev(of: jerk5m)

        let motionEpochJerkMinusHist5mMean = epoch.motionJerk - mean(of: jerk5m)
        let motionEpochMagMinusHist5mMean  = motionEpochMagMean - motionHist5mMagMean
        let motionEpochMagMinusHist2mMean  = motionEpochMagMean - motionHist2mMagMean

        // --- HR features ---
        let hrHist5mMean  = mean(of: hrMeans5m)
        let hrHist5mStd   = stdDev(of: hrMeans5m)
        let hrHist10mMean = mean(of: hrMeans10m)
        let hrHist10mStd  = stdDev(of: hrMeans10m)
        let hrHist5mCV    = hrHist5mMean > 0 ? hrHist5mStd / hrHist5mMean : 0
        let hrHist10mCV   = hrHist10mMean > 0 ? hrHist10mStd / hrHist10mMean : 0

        let hrEpochRangeMinusHist5mRange = epoch.heartRateRange - mean(of: hrRanges5m)
        let hrEpochStdMinusHist5mStd = epoch.heartRateStd - mean(of: hrStds5m)
        let hrEpochMeanDivHist10mMean = hrHist10mMean > 0 ? epoch.heartRateMean / hrHist10mMean : 1.0

        // --- Time features ---
        let startDate = sessionStartDate ?? epochHistory.first?.timestamp ?? epoch.timestamp
        let elapsedMinutes = epoch.timestamp.timeIntervalSince(startDate) / 60.0
        let timeHoursFromStart = elapsedMinutes / 60.0

        // --- Minutes since last HR jump ---
        let epochsSinceJump = Double(index - lastHRJumpEpochIndex)
        let minutesSinceJump = epochsSinceJump * 0.5 // each epoch = 30s = 0.5min

        // --- Build feature dictionary with log1p transforms ---
        return [
            "motion_hist5m_mag_max_log1p":        log1p(motionHist5mMagMax),
            "motion_hist10m_mag_std_log1p":       log1p(motionHist10mMagStd),
            "motion_hist5m_jerk_std_log1p":       log1p(motionHist5mJerkStd),
            "motion_hist5m_mag_std_log1p":        log1p(motionHist5mMagStd),
            "hr_hist10m_cv_raw":                  hrHist10mCV,
            "hr_hist5m_cv_raw":                   hrHist5mCV,
            "hr_hist10m_std_raw":                 hrHist10mStd,
            "hr_hist5m_std_raw":                  hrHist5mStd,
            "minutes_since_last_hr_jump_log1p":   log1p(minutesSinceJump),
            "time_hours_from_start":              timeHoursFromStart,
            "elapsed_minutes_log1p":              log1p(elapsedMinutes),
            "motion_hist10m_mag_mean_log1p":      log1p(motionHist10mMagMean),
            "motion_epoch_jerk_minus_hist5m_mean": motionEpochJerkMinusHist5mMean,
            "motion_hist5m_mag_mean_log1p":       log1p(motionHist5mMagMean),
            "motion_hist5m_mag_sum_log1p":        log1p(motionHist5mMagSum),
            "motion_epoch_mag_minus_hist5m_mean": motionEpochMagMinusHist5mMean,
            "motion_hist2m_mag_std_log1p":        log1p(motionHist2mMagStd),
            "motion_hist2m_mag_mean_log1p":       log1p(motionHist2mMagMean),
            "hr_epoch_range_minus_hist5m_range":  hrEpochRangeMinusHist5mRange,
            "motion_epoch_mag_mean_log1p":        log1p(motionEpochMagMean),
            "hr_epoch_std_minus_hist5m_std":      hrEpochStdMinusHist5mStd,
            "hr_epoch_mean_div_hist10m_mean":     hrEpochMeanDivHist10mMean,
            "motion_epoch_mag_minus_hist2m_mean": motionEpochMagMinusHist2mMean,
            "hr_hist10m_mean_raw":                hrHist10mMean,
            "motion_epoch_mag_max_log1p":         log1p(motionEpochMagMax),
        ]
    }

    // MARK: - Prediction

    func makePrediction(forEpochAt index: Int) -> PredictionSnapshot? {
        guard let stageModel else {
            log("Prediction skipped: model unavailable.")
            return nil
        }

        let features = computeFeatures(forEpochAt: index)
        let epoch = epochHistory[index]

        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: features as [String: NSNumber])
            let prediction = try stageModel.prediction(from: provider)

            guard
                let rawValue = prediction.featureValue(for: "target")?.int64Value,
                let rawStage = SleepStage(rawValue: Int(rawValue))
            else {
                log("Prediction output missing target.")
                return nil
            }

            rawPredictions.append(rawStage)
            if rawPredictions.count > smoothingWindowSize {
                rawPredictions.removeFirst(rawPredictions.count - smoothingWindowSize)
            }

            let smoothedStage = modeStage(from: rawPredictions) ?? rawStage
            rawPredictionHistory.append(rawStage)
            if rawPredictionHistory.count > maxStoredPredictionHistory {
                rawPredictionHistory.removeFirst(rawPredictionHistory.count - maxStoredPredictionHistory)
            }
            smoothedPredictionHistory.append(smoothedStage)
            if smoothedPredictionHistory.count > maxStoredPredictionHistory {
                smoothedPredictionHistory.removeFirst(smoothedPredictionHistory.count - maxStoredPredictionHistory)
            }
            return PredictionSnapshot(rawStage: rawStage, smoothedStage: smoothedStage, epoch: epoch)
        } catch {
            log("Prediction failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - UI Updates

    func updatePredictionState(_ prediction: PredictionSnapshot) {
        let rawStageText = prediction.rawStage.title
        let officialStageText = prediction.smoothedStage.title
        let featureSummary = String(
            format: "HR %.1f bpm | Motion %.1f | Jerk %.2f",
            prediction.epoch.heartRateMean,
            prediction.epoch.motionMagMean,
            prediction.epoch.motionJerk
        )

        DispatchQueue.main.async {
            self.rawStageDisplay = rawStageText
            self.officialStageDisplay = officialStageText
            self.latestFeatureSummary = featureSummary
        }

        log("Epoch classified. Raw: \(rawStageText) | Official: \(officialStageText)")
    }

    func updateEpochSummary(for epoch: EpochAggregate) {
        let summary = String(
            format: "%@ | HR %.1f bpm | Motion %.0f",
            epoch.timestamp.formatted(date: .omitted, time: .standard),
            epoch.heartRateMean,
            epoch.motionMagMean
        )

        DispatchQueue.main.async {
            self.latestEpochSummary = summary
        }
    }

    // MARK: - Smoothing

    func modeStage(from values: [SleepStage]) -> SleepStage? {
        guard !values.isEmpty else { return nil }

        let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        let maxCount = counts.values.max() ?? 0
        let candidates = counts.compactMap { stage, count in
            count == maxCount ? stage : nil
        }

        for stage in values.reversed() {
            if candidates.contains(stage) {
                return stage
            }
        }

        return values.last
    }

    func resetConfirmation() {
        isConfirming = false
        confirmationBuffer.removeAll()
        updateConfirmationProgress("Idle")
    }

    func updateConfirmationProgress(_ status: String) {
        DispatchQueue.main.async {
            self.confirmationProgress = status
        }
        requestPersistedSessionSave()
    }

}

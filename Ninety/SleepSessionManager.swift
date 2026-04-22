import Combine
import CoreML
import Foundation
import UIKit
import WatchConnectivity

final class SleepSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SleepSessionManager()

    // MARK: - Sleep Stage Classification
    // Model output: 0=Wake, 1=N1/N2(light), 2=N3(deep), 3=REM
    enum SleepStage: Int, CaseIterable {
        case wake = 0
        case light = 1   // N1/N2 light sleep — TRIGGERS alarm
        case deep = 2    // N3 deep sleep — do NOT trigger
        case rem = 3     // REM — do NOT trigger

        var title: String {
            let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            switch self {
            case .wake:
                return "Wake".localized(for: preferredLang)
            case .light:
                return "Light".localized(for: preferredLang)
            case .deep:
                return "Deep".localized(for: preferredLang)
            case .rem:
                return "REM".localized(for: preferredLang)
            }
        }
    }

    // MARK: - Per-Epoch Aggregate
    // Stores all raw data needed for feature engineering across rolling windows.
    private struct EpochAggregate {
        let timestamp: Date
        let heartRateMean: Double
        let heartRateStd: Double
        let heartRateRange: Double    // max - min of HR within epoch
        let motionMagMean: Double     // mean of motion counts in epoch
        let motionMagMax: Double      // max of motion counts in epoch
        let motionJerk: Double        // |current_motion - previous_motion|
    }

    private struct PredictionSnapshot {
        let rawStage: SleepStage
        let smoothedStage: SleepStage
        let epoch: EpochAggregate
    }

    // MARK: - Configuration
    private let maxTrackedPayloadIDs = 200
    private let epochDuration: TimeInterval = 30
    /// 10-minute window = 20 epochs of 30s each. We need at least this many for
    /// the widest rolling window (hist10m) in the model's feature set.
    private let minimumEpochsForFeatures = 5
    private let smoothingWindowSize = 5
    private let processingQueue = DispatchQueue(label: "Ninety.SleepSessionManager.processing")

    // MARK: - Published UI State
    @Published var lastPayloadReceived: String = "No data received"
    @Published var watchStatus: String = "No watch session activity"
    @Published var watchConnectionStatus: String = "No connectivity status"
    @Published var engineLog: String = "Idle"
    @Published var logs: [String] = []
    @Published var modelStatus: String = "Loading model"
    @Published var rawStageDisplay: String = "Warming up (5 epochs)"
    @Published var officialStageDisplay: String = "Warming up (5 epochs)"
    @Published var latestEpochSummary: String = "No 30-second epoch yet"
    @Published var latestFeatureSummary: String = "No features computed yet"
    @Published var confirmationProgress: String = "Idle"
    @Published var isTestModeRunning: Bool = false
    @Published var testModeProgress: String = ""

    // MARK: - Confirmation Window Configuration
    /// Number of predictions required in the confirmation window.
    private let confirmationRequired = 3
    /// Minimum number of `.light` predictions within the window to confirm trigger.
    private let confirmationThreshold = 2
    /// Accumulated predictions during the active confirmation window.
    private var confirmationBuffer: [SleepStage] = []
    /// Whether a confirmation window is currently active.
    private var isConfirming = false

    private var preferredLang: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

    // MARK: - Internal State
    private var wcSession: WCSession?
    private var currentBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var recentPayloadIDs: [UUID] = []
    private var currentEpochPayloads: [SensorPayload] = []
    private var epochHistory: [EpochAggregate] = []
    private var rawPredictions: [SleepStage] = []
    private var stageModel: MLModel?
    private var activeWakeTargetDate: Date?
    private var dynamicAlarmTriggered = false
    private var sessionStartDate: Date?
    /// Tracks the last epoch where HR jumped significantly, for the
    /// `minutes_since_last_hr_jump_log1p` feature.
    private var lastHRJumpEpochIndex: Int = 0
    private var testModeTimer: Timer?
    private var testModeRows: [[String: Double]] = []
    private var testModeLabels: [Int] = []
    private var testModeIndex: Int = 0

    override init() {
        super.init()
        setupWatchConnectivity()
        loadModel()
    }

    // MARK: - WatchConnectivity

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    func startWatchSession(targetDate: Date? = nil) {
        resetSession()
        activeWakeTargetDate = targetDate
        dynamicAlarmTriggered = false
        sessionStartDate = Date()

        guard let session = wcSession else { return }

        var command: [String: Any] = ["action": "startSession"]
        if let targetDate {
            command["targetDate"] = targetDate.timeIntervalSince1970
        }

        if session.isReachable {
            session.sendMessage(command, replyHandler: nil) { error in
                self.log("Failed to start via sendMessage: \(error.localizedDescription)")
            }
            log("Direct session request sent to Watch.")
        } else {
            session.transferUserInfo(command)
            log("Watch unreachable. Request queued (Will fire when Watch wakes).".localized(for: preferredLang))
        }
    }

    func stopWatchSession() {
        activeWakeTargetDate = nil
        dynamicAlarmTriggered = false
        guard let session = wcSession else { return }
        let command = ["action": "stopSession"]
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(command)
        }
    }

    func pauseWatchMonitoring() {
        activeWakeTargetDate = nil
        dynamicAlarmTriggered = false
        guard let session = wcSession else { return }
        let command = ["action": "pauseMonitoring"]
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(command)
        }
    }

    func triggerWatchHapticWakeUp() {
        guard let session = wcSession else { return }
        let command = ["action": "hapticWakeUp"]
        // For alarm haptics, we only care about immediate delivery when reachable
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        log("WCSession Activated: \(activationState == .activated)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        wcSession?.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingPayload(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncomingPayload(userInfo)
    }

    // MARK: - Model Loading

    private func loadModel() {
        processingQueue.async {
            guard let modelURL = Bundle.main.url(forResource: "modello25", withExtension: "mlmodelc") else {
                self.updateModelStatus("modello25.mlmodelc missing from bundle".localized(for: self.preferredLang))
                return
            }

            do {
                let configuration = MLModelConfiguration()
                let model = try MLModel(contentsOf: modelURL, configuration: configuration)
                self.stageModel = model
                self.updateModelStatus("Sleep stage model ready".localized(for: self.preferredLang))
            } catch {
                self.updateModelStatus("Model load failed: \(error.localizedDescription)".localized(for: self.preferredLang))
            }
        }
    }

    // MARK: - Payload Handling

    private func handleIncomingPayload(_ payloadDictionary: [String: Any]) {
        // 1. Cross-Device Siri Intent Relay Check
        if let relayIntent = payloadDictionary["relayIntent"] as? String {
            handleRelayIntent(relayIntent, payload: payloadDictionary)
            return
        }

        // 2. Original Watch Status Check
        if handleWatchStatus(payloadDictionary) {
            return
        }

        extendBackgroundTask()

        do {
            let payload: SensorPayload
            if let payloadData = payloadDictionary["payloadData"] as? Data {
                payload = try JSONDecoder().decode(SensorPayload.self, from: payloadData)
            } else {
                let data = try JSONSerialization.data(withJSONObject: payloadDictionary, options: [])
                payload = try JSONDecoder().decode(SensorPayload.self, from: data)
            }

            DispatchQueue.main.async {
                self.lastPayloadReceived = "Received at \(payload.timestamp.formatted(date: .omitted, time: .standard))"
            }

            // Deduplication and consumption must both run on processingQueue
            // to avoid data races on recentPayloadIDs and other shared state.
            processingQueue.async {
                guard self.shouldProcessPayload(withID: payload.id) else {
                    return
                }
                self.consume(payload: payload)
            }
        } catch {
            log("Decode Error: \(error.localizedDescription)")
        }
    }

    private func handleWatchStatus(_ payloadDictionary: [String: Any]) -> Bool {
        guard let status = payloadDictionary["watchStatus"] as? String else {
            return false
        }

        let queuedSchedule = (payloadDictionary["queuedSchedule"] as? TimeInterval).map {
            Date(timeIntervalSince1970: $0).formatted(date: .omitted, time: .shortened)
        }
        let connectionStatus = payloadDictionary["watchConnectionStatus"] as? String

        DispatchQueue.main.async {
            if let queuedSchedule {
                self.watchStatus = "\(status) (\(queuedSchedule))"
            } else {
                self.watchStatus = status
            }

            if let connectionStatus {
                self.watchConnectionStatus = connectionStatus
            }
        }

        log("Watch: \(status)")
        return true
    }

    // MARK: - Cross-Device Intent Handlers
    
    private func handleRelayIntent(_ action: String, payload: [String: Any]) {
        DispatchQueue.main.async {
            switch action {
            case "setAlarm":
                if let timestamp = payload["time"] as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timestamp)
                    _ = SmartAlarmManager.shared.scheduleSleepSession(endingAt: date)
                    self.log("Relayed: Set Ninety Alarm to \(date)")
                }
            case "updateAlarm":
                if let offsetMinutes = payload["offsetMinutes"] as? Int,
                   let scheduleVM = ScheduleViewModel().nextUpcomingSession {
                    let offsetSeconds = Double(offsetMinutes) * 60
                    let newWakeUpDate = scheduleVM.wakeUpDate.addingTimeInterval(offsetSeconds)
                    if newWakeUpDate > Date() {
                        SmartAlarmManager.shared.cancelSession()
                        _ = SmartAlarmManager.shared.scheduleSleepSession(endingAt: newWakeUpDate)
                        self.log("Relayed: Updated Ninety Alarm by \(offsetMinutes)m to \(newWakeUpDate)")
                    }
                }
            case "getAlarm":
                // Get intents usually result in speech responses, which Siri on the Watch natively handles 
                // by delegating to iPhone or speaking a simple default if we return a reply block.
                // For this UI-less app, simply updating the status string is enough.
                self.log("Relayed: Checked Ninety Alarm status.")
            default:
                self.log("Unknown Relay Intent: \(action)")
            }
        }
    }

    // MARK: - Epoch Aggregation

    private func consume(payload: SensorPayload) {
        // 1. Inactivity Timeout: If the gap is > 5 minutes, reset buffers
        if let lastTimestamp = currentEpochPayloads.last?.timestamp ?? epochHistory.last?.timestamp {
            let gap = payload.timestamp.timeIntervalSince(lastTimestamp)
            if gap > 300 {
                log("⚠️ Large data gap (\(Int(gap/60)) min). Resetting model history.")
                epochHistory.removeAll()
                rawPredictions.removeAll()
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
            heartRateMean: hrMean,
            heartRateStd: hrStd,
            heartRateRange: hrRange,
            motionMagMean: motionMagMean,
            motionMagMax: motionMagMax,
            motionJerk: motionJerk
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

    /// Computes the 25 features required by modello25.mlmodel for a given epoch index.
    ///
    /// Rolling windows:
    ///  - hist2m  = 4 epochs  (4 × 30s = 2 min)
    ///  - hist5m  = 10 epochs (10 × 30s = 5 min)
    ///  - hist10m = 20 epochs (20 × 30s = 10 min)
    private func createPaddedWindow(endIndex: Int, requiredCount: Int) -> [EpochAggregate] {
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

    private func computeFeatures(forEpochAt index: Int) -> [String: Double] {
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

    private func makePrediction(forEpochAt index: Int) -> PredictionSnapshot? {
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
            return PredictionSnapshot(rawStage: rawStage, smoothedStage: smoothedStage, epoch: epoch)
        } catch {
            log("Prediction failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - UI Updates

    private func updatePredictionState(_ prediction: PredictionSnapshot) {
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
        evaluateDynamicAlarmTrigger(for: prediction)
    }

    private func updateEpochSummary(for epoch: EpochAggregate) {
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

    private func modeStage(from values: [SleepStage]) -> SleepStage? {
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

    // MARK: - Dynamic Alarm Trigger with Multi-Epoch Confirmation

    private func evaluateDynamicAlarmTrigger(for prediction: PredictionSnapshot) {
        guard activeWakeTargetDate != nil else {
            return
        }

        guard !dynamicAlarmTriggered else {
            return
        }

        let detectedLight = prediction.smoothedStage == .light

        if detectedLight {
            // Start or continue the confirmation window
            if !isConfirming {
                isConfirming = true
                confirmationBuffer.removeAll()
                log("🔍 Light sleep detected. Starting confirmation window.")
            }

            confirmationBuffer.append(prediction.smoothedStage)
            let progress = "\(confirmationBuffer.count)/\(confirmationRequired)"
            updateConfirmationProgress("Verifying... \(progress)")
            log("🔍 Confirmation epoch \(progress): \(prediction.smoothedStage.title)")

            if confirmationBuffer.count >= confirmationRequired {
                let lightCount = confirmationBuffer.filter { $0 == .light }.count

                if lightCount >= confirmationThreshold {
                    // Confirmed: enough light-sleep predictions to trigger safely
                    dynamicAlarmTriggered = true
                    updateConfirmationProgress("✅ Confirmed (\(lightCount)/\(confirmationRequired))")
                    log("✅ Light sleep CONFIRMED (\(lightCount)/\(confirmationRequired)). Triggering alarm.")

                    Task { @MainActor in
                        SmartAlarmManager.shared.triggerDynamicAlarm()
                    }
                } else {
                    // Not enough agreement — false positive, reset and keep monitoring
                    log("❌ Confirmation failed (\(lightCount)/\(confirmationRequired) light). Resetting.")
                    resetConfirmation()
                }
            }
        } else {
            // Non-light prediction during active confirmation window
            if isConfirming {
                confirmationBuffer.append(prediction.smoothedStage)

                if confirmationBuffer.count >= confirmationRequired {
                    let lightCount = confirmationBuffer.filter { $0 == .light }.count
                    if lightCount >= confirmationThreshold {
                        dynamicAlarmTriggered = true
                        updateConfirmationProgress("✅ Confirmed (\(lightCount)/\(confirmationRequired))")
                        log("✅ Light sleep CONFIRMED despite mixed window (\(lightCount)/\(confirmationRequired)). Triggering alarm.")

                        Task { @MainActor in
                            SmartAlarmManager.shared.triggerDynamicAlarm()
                        }
                    } else {
                        log("❌ Confirmation window complete but insufficient light epochs (\(lightCount)/\(confirmationRequired)). Resetting.")
                        resetConfirmation()
                    }
                } else {
                    let progress = "\(confirmationBuffer.count)/\(confirmationRequired)"
                    updateConfirmationProgress("Verifying... \(progress) (mixed)")
                    log("🔍 Confirmation epoch \(progress): \(prediction.smoothedStage.title) (non-light in window)")
                }
            }
            // If not confirming and not light → just keep monitoring
        }
    }

    private func resetConfirmation() {
        isConfirming = false
        confirmationBuffer.removeAll()
        updateConfirmationProgress("Idle")
    }

    private func updateConfirmationProgress(_ status: String) {
        DispatchQueue.main.async {
            self.confirmationProgress = status
        }
    }

    // MARK: - Session Reset

    private func resetSession() {
        processingQueue.async {
            self.currentEpochPayloads.removeAll()
            self.epochHistory.removeAll()
            self.rawPredictions.removeAll()
            self.recentPayloadIDs.removeAll()
            self.dynamicAlarmTriggered = false
            self.isConfirming = false
            self.confirmationBuffer.removeAll()
            self.lastHRJumpEpochIndex = 0
            self.sessionStartDate = nil

            DispatchQueue.main.async {
                self.rawStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                self.officialStageDisplay = "Warming up (5 epochs)".localized(for: self.preferredLang)
                self.latestEpochSummary = "No 30-second epoch yet".localized(for: self.preferredLang)
                self.latestFeatureSummary = "No features computed yet".localized(for: self.preferredLang)
                self.confirmationProgress = "Idle"
            }
        }
    }

    // MARK: - Utilities

    private func shouldProcessPayload(withID id: UUID) -> Bool {
        guard !recentPayloadIDs.contains(id) else {
            return false
        }

        recentPayloadIDs.append(id)
        if recentPayloadIDs.count > maxTrackedPayloadIDs {
            recentPayloadIDs.removeFirst(recentPayloadIDs.count - maxTrackedPayloadIDs)
        }
        return true
    }

    func log(_ message: String) {
        DispatchQueue.main.async {
            self.logs.insert("[\(Date().formatted(date: .omitted, time: .standard))] \(message)", at: 0)
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
            self.engineLog = message
        }
    }

    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.engineLog = "Logs cleared"
        }
    }

    private func extendBackgroundTask() {
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

    private func updateModelStatus(_ status: String) {
        DispatchQueue.main.async {
            self.modelStatus = status
        }
        log(status)
    }

    // MARK: - Math Helpers

    private func mean(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func stdDev(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let avg = mean(of: values)
        let variance = values.reduce(0) { partialResult, value in
            partialResult + pow(value - avg, 2)
        } / Double(values.count)
        return sqrt(variance)
    }

    private func log1p(_ x: Double) -> Double {
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
        let featureNames = header.filter { $0 != "target" }

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

        testModeRows = rows
        testModeLabels = labels
        testModeIndex = 0

        DispatchQueue.main.async {
            self.isTestModeRunning = true
            self.testModeProgress = "0/\(rows.count)"
        }

        log("🧪 TEST MODE started — \(rows.count) epochs from test6.csv")
        log("🧪 Feeding pre-computed features directly to modello25 at 0.5s/epoch")

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

    private func processNextTestRow() {
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

            // Build a fake PredictionSnapshot for the confirmation logic
            let fakeEpoch = EpochAggregate(
                timestamp: Date(),
                heartRateMean: featureRow["hr_hist10m_mean_raw"] ?? 0,
                heartRateStd: featureRow["hr_hist5m_std_raw"] ?? 0,
                heartRateRange: 0,
                motionMagMean: 0,
                motionMagMax: 0,
                motionJerk: 0
            )
            let snap = PredictionSnapshot(rawStage: rawStage, smoothedStage: smoothed, epoch: fakeEpoch)
            evaluateDynamicAlarmTrigger(for: snap)

        } catch {
            log("🧪 [\(testModeIndex)] Prediction error: \(error.localizedDescription)")
        }

        testModeIndex += 1
    }
}

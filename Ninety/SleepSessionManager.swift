import Combine
import CoreML
import Foundation
import UIKit
import WatchConnectivity

final class SleepSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SleepSessionManager()

    enum SleepStage: Int, CaseIterable {
        case wake = 0
        case nrem = 1
        case rem = 2

        var title: String {
            let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            switch self {
            case .wake:
                return "Wake".localized(for: preferredLang)
            case .nrem:
                return "NREM".localized(for: preferredLang)
            case .rem:
                return "REM".localized(for: preferredLang)
            }
        }
    }

    private struct EpochAggregate {
        let timestamp: Date
        let heartRate: Double
        let motionCount: Double
    }

    private struct PredictionSnapshot {
        let rawStage: SleepStage
        let smoothedStage: SleepStage
        let features: FeatureVector
        let epoch: EpochAggregate
    }

    private struct FeatureVector {
        let hrRel: Double
        let motionRel: Double
        let hr5mStd: Double
        let motion5mAvg: Double
        let circadian: Double
        let hrDelta: Double
        let hrRelPrev: Double
        let hrRelNext: Double
    }

    private let maxTrackedPayloadIDs = 200
    private let epochDuration: TimeInterval = 30
    private let minimumEpochsForFeatures = 10
    private let smoothingWindowSize = 5
    private let processingQueue = DispatchQueue(label: "Ninety.SleepSessionManager.processing")

    @Published var lastPayloadReceived: String = "No data received"
    @Published var watchStatus: String = "No watch session activity"
    @Published var watchConnectionStatus: String = "No connectivity status"
    @Published var engineLog: String = "Idle"
    @Published var logs: [String] = []
    @Published var modelStatus: String = "Loading model"
    @Published var rawStageDisplay: String = "Waiting for 10 epochs"
    @Published var officialStageDisplay: String = "Waiting for 10 epochs"
    @Published var latestEpochSummary: String = "No 30-second epoch yet"
    @Published var latestFeatureSummary: String = "No features computed yet"
    
    private var preferredLang: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

    private var wcSession: WCSession?
    private var currentBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var recentPayloadIDs: [UUID] = []
    private var currentEpochPayloads: [SensorPayload] = []
    private var epochHistory: [EpochAggregate] = []
    private var sessionHeartRates: [Double] = []
    private var sessionMotionCounts: [Double] = []
    private var rawPredictions: [SleepStage] = []
    private var stageModel: MLModel?
    private var activeWakeTargetDate: Date?
    private var dynamicAlarmTriggered = false

    override init() {
        super.init()
        setupWatchConnectivity()
        loadModel()
    }

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

    private func loadModel() {
        processingQueue.async {
            guard let modelURL = Bundle.main.url(forResource: "SleepStagesV1", withExtension: "mlmodelc") else {
                self.updateModelStatus("SleepStagesV1.mlmodelc missing from bundle".localized(for: self.preferredLang))
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

    private func handleIncomingPayload(_ payloadDictionary: [String: Any]) {
        if handleWatchStatus(payloadDictionary) {
            return
        }

        extendBackgroundTask()

        do {
            let data = try JSONSerialization.data(withJSONObject: payloadDictionary, options: [])
            let payload = try JSONDecoder().decode(SensorPayload.self, from: data)

            guard shouldProcessPayload(withID: payload.id) else {
                log("Skipped duplicate payload \(payload.id.uuidString.prefix(8))")
                return
            }

            DispatchQueue.main.async {
                self.lastPayloadReceived = "Received at \(payload.timestamp.formatted(date: .omitted, time: .standard))"
            }

            processingQueue.async {
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

    private func consume(payload: SensorPayload) {
        currentEpochPayloads.append(payload)
        let epochStart = currentEpochPayloads.first?.timestamp ?? payload.timestamp
        let epochElapsed = payload.timestamp.timeIntervalSince(epochStart)

        guard epochElapsed >= epochDuration else {
            return
        }

        let hrValues = currentEpochPayloads.flatMap(\.hrSamples)
        let averagedHeartRate = hrValues.isEmpty ? 0 : hrValues.reduce(0, +) / Double(hrValues.count)
        let motionCount = currentEpochPayloads.reduce(0) { partialResult, item in
            partialResult + item.motionCount
        }
        let epoch = EpochAggregate(timestamp: payload.timestamp, heartRate: averagedHeartRate, motionCount: motionCount)

        currentEpochPayloads.removeAll()
        sessionHeartRates.append(epoch.heartRate)
        sessionMotionCounts.append(epoch.motionCount)
        epochHistory.append(epoch)
        if epochHistory.count > minimumEpochsForFeatures {
            epochHistory.removeFirst(epochHistory.count - minimumEpochsForFeatures)
        }

        updateEpochSummary(for: epoch)

        guard epochHistory.count >= minimumEpochsForFeatures else {
            log("Epoch \(epochHistory.count)/\(minimumEpochsForFeatures) captured. Warming feature buffer.")
            return
        }

        guard let prediction = makePrediction(using: epoch) else {
            return
        }

        updatePredictionState(prediction)
    }

    private func makePrediction(using epoch: EpochAggregate) -> PredictionSnapshot? {
        guard let stageModel else {
            log("Prediction skipped: model unavailable.")
            return nil
        }

        let features = engineeredFeatures(for: epoch)

        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "circadian": features.circadian,
                "hr_rel": features.hrRel,
                "motion_rel": features.motionRel,
                "hr_delta": features.hrDelta,
                "hr_5m_std": features.hr5mStd,
                "motion_5m_avg": features.motion5mAvg,
                "hr_rel_prev": features.hrRelPrev,
                "hr_rel_next": features.hrRelNext
            ])
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
            return PredictionSnapshot(rawStage: rawStage, smoothedStage: smoothedStage, features: features, epoch: epoch)
        } catch {
            log("Prediction failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func engineeredFeatures(for epoch: EpochAggregate) -> FeatureVector {
        let heartRateMean = mean(of: sessionHeartRates)
        let heartRateStd = standardDeviation(of: sessionHeartRates)
        let motionMean = mean(of: sessionMotionCounts)
        let motionStd = standardDeviation(of: sessionMotionCounts)
        let recentEpochs = Array(epochHistory.suffix(minimumEpochsForFeatures))
        let recentHeartRates = recentEpochs.map(\.heartRate)
        let recentMotionCounts = recentEpochs.map(\.motionCount)
        let previousEpoch = recentEpochs.dropLast().last
        let previousHeartRate = previousEpoch?.heartRate ?? epoch.heartRate

        let hrRel = zScore(value: epoch.heartRate, mean: heartRateMean, standardDeviation: heartRateStd)
        let motionRel = zScore(value: epoch.motionCount, mean: motionMean, standardDeviation: motionStd)
        let previousHRRel = zScore(value: previousHeartRate, mean: heartRateMean, standardDeviation: heartRateStd)
        let hrDelta = epoch.heartRate - previousHeartRate

        return FeatureVector(
            hrRel: hrRel,
            motionRel: motionRel,
            hr5mStd: standardDeviation(of: recentHeartRates),
            motion5mAvg: mean(of: recentMotionCounts),
            circadian: circadianCosine(at: epoch.timestamp),
            hrDelta: hrDelta,
            hrRelPrev: previousHRRel,
            // The bundled model expects a "next" temporal feature. In real time, use the
            // current normalized HR as a causal fallback rather than waiting another epoch.
            hrRelNext: hrRel
        )
    }

    private func updatePredictionState(_ prediction: PredictionSnapshot) {
        let rawStageText = prediction.rawStage.title
        let officialStageText = prediction.smoothedStage.title
        let featureSummary = String(
            format: "hr_rel %.2f | motion_rel %.2f | hr_5m_std %.2f | motion_5m_avg %.2f | circadian %.2f",
            prediction.features.hrRel,
            prediction.features.motionRel,
            prediction.features.hr5mStd,
            prediction.features.motion5mAvg,
            prediction.features.circadian
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
            epoch.heartRate,
            epoch.motionCount
        )

        DispatchQueue.main.async {
            self.latestEpochSummary = summary
        }
    }

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

    private func evaluateDynamicAlarmTrigger(for prediction: PredictionSnapshot) {
        guard activeWakeTargetDate != nil else {
            return
        }

        guard !dynamicAlarmTriggered else {
            return
        }

        guard prediction.smoothedStage == .wake || prediction.smoothedStage == .rem else {
            return
        }

        dynamicAlarmTriggered = true
        log("Optimal wake stage detected from classifier: \(prediction.smoothedStage.title). Triggering alarm.")

        Task { @MainActor in
            SmartAlarmManager.shared.triggerDynamicAlarm()
        }
    }

    private func resetSession() {
        processingQueue.async {
            self.currentEpochPayloads.removeAll()
            self.epochHistory.removeAll()
            self.sessionHeartRates.removeAll()
            self.sessionMotionCounts.removeAll()
            self.rawPredictions.removeAll()
            self.recentPayloadIDs.removeAll()
            self.dynamicAlarmTriggered = false

            DispatchQueue.main.async {
                self.rawStageDisplay = "Waiting for 10 epochs".localized(for: self.preferredLang)
                self.officialStageDisplay = "Waiting for 10 epochs".localized(for: self.preferredLang)
                self.latestEpochSummary = "No 30-second epoch yet".localized(for: self.preferredLang)
                self.latestFeatureSummary = "No features computed yet".localized(for: self.preferredLang)
            }
        }
    }

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

    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.logs.insert("[\(Date().formatted(date: .omitted, time: .standard))] \(message)", at: 0)
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
            self.engineLog = message
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

    private func mean(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func standardDeviation(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let average = mean(of: values)
        let variance = values.reduce(0) { partialResult, value in
            partialResult + pow(value - average, 2)
        } / Double(values.count)
        return sqrt(variance)
    }

    private func zScore(value: Double, mean: Double, standardDeviation: Double) -> Double {
        let denominator = standardDeviation + 0.001
        return (value - mean) / denominator
    }

    private func circadianCosine(at date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        
        // 1. Risolvi gli opzionali in modo isolato (il tipo inferito sarà Int)
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let s = components.second ?? 0
        
        // 2. Fai la matematica con gli interi in un passaggio separato
        let totalSeconds = (h * 3600) + (m * 60) + s
        
        // 3. Converti in Double solo alla fine
        let seconds = Double(totalSeconds)
        let normalized = seconds / 86_400.0 // Aggiunto .0 per esplicitare il tipo Double
        
        return cos(2 * .pi * normalized)
    }
}

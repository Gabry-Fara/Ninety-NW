import Foundation
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine
import CoreML

enum WatchConnectivityState {
    case synced
    case queued
    case watchOnly
}

enum WatchWeeklyAlarmSyncState: Equatable {
    case synced
    case saving
    case saved
    case pending
    case unreachable
    case failed
}

class WatchSensorManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    private static let pendingScheduleKey = "pendingSmartAlarmSchedule"
    private static let readyScheduleKey = "readySmartAlarmSchedule"
    private static let actualAlarmTimeKey = "actualSmartAlarmTime"
    private static let pendingNextAlarmCommandKey = "pendingNextAlarmCommand"
    private static let lastProcessedPhoneCommandSequenceKey = "lastProcessedPhoneCommandSequence"
    private let payloadInterval: TimeInterval = 5
    private let motionThreshold = 0.08
    private let maxPendingPayloads = 12_000
    private let backlogReplayBatchSize = 24
    private let minimumBacklogFlushInterval: TimeInterval = 8
    private let runtimeExpiryAlarmTolerance: TimeInterval = 10
    private let epochDuration: TimeInterval = 30
    private let minimumEpochsForFeatures = 5
    private let smoothingWindowSize = 5
    private let confirmationRequired = 3
    private let confirmationThreshold = 2
    private let maximumDynamicPredictionAge: TimeInterval = 90
    private let alarmFinalMinuteBuffer: TimeInterval = 60
    #if DEBUG
    private let testLightEpochInjectionEnabled = true
    private let testLightEpochInjectionDelay: TimeInterval = 5 * 60
    private let testLightEpochInjectionCount = 3
    #endif

    private enum WatchPipelineState: String, Codable {
        case idle
        case scheduled
        case recording
        case deliveringBacklog
        case completed
        case failed

        var label: String {
            switch self {
            case .idle:
                return "Idle"
            case .scheduled:
                return "Scheduled"
            case .recording:
                return "Recording"
            case .deliveringBacklog:
                return "Delivering backlog"
            case .completed:
                return "Completed"
            case .failed:
                return "Failed"
            }
        }
    }

    private enum WatchSleepStage: Int, CaseIterable, Codable {
        case wake = 0
        case light = 1
        case deep = 2
        case rem = 3

        var title: String {
            switch self {
            case .wake: return "Wake"
            case .light: return "Light"
            case .deep: return "Deep"
            case .rem: return "REM"
            }
        }
    }

    private struct WatchEpochAggregate {
        let timestamp: Date
        let heartRateMean: Double
        let heartRateStd: Double
        let heartRateRange: Double
        let motionMagMean: Double
        let motionMagMax: Double
        let motionJerk: Double
    }

    private struct WatchPredictionSnapshot {
        let rawStage: WatchSleepStage
        let smoothedStage: WatchSleepStage
        let epoch: WatchEpochAggregate
        let isTestInjected: Bool
    }

    private struct PendingPayloadEnvelope: Codable {
        let payload: SensorPayload
        let enqueuedAt: Date
        var lastAttemptAt: Date?
        var deliveryAttempts: Int
        var deferredDeliveryQueued: Bool
    }

    private struct PendingNextAlarmCommand: Codable, Equatable {
        let hour: Int
        let minute: Int
        let enqueuedAt: Date

        var message: [String: Any] {
            [
                "action": "setNextAlarm",
                "hour": hour,
                "minute": minute,
                "createdAt": enqueuedAt.timeIntervalSince1970
            ]
        }
    }
    
    static let shared = WatchSensorManager()
    
    @Published var sessionState: String = "Inactive"
    @Published var lastPayloadSent: String = "No data sent yet"
    @Published var connectionStatus: String = "Disconnected"
    @Published var isMocking: Bool = false
    @Published var nextAlarmDate: Date? = nil
    @Published var weeklyAlarmSyncState: WatchWeeklyAlarmSyncState = .synced
    @Published var weeklyAlarmSyncDetail: String? = nil
    
    private var runtimeSession: WKExtendedRuntimeSession?
    private var suppressNextRuntimeInvalidation = false
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var wcSession: WCSession?
    private var pendingPayloads: [PendingPayloadEnvelope] = []
    private var lastBacklogFlushDate: Date?
    private var pipelineState: WatchPipelineState = .idle
    private var replayStatusText: String = "No backlog activity"
    private var isSendingNextAlarmCommand = false
    private var alarmDeadlineTimer: Timer?
    private var watchStageModel: MLModel?
    private var currentEpochPayloads: [SensorPayload] = []
    private var epochHistory: [WatchEpochAggregate] = []
    private var rawPredictions: [WatchSleepStage] = []
    private var confirmationBuffer: [WatchSleepStage] = []
    private var isConfirmingSmartWake = false
    private var smartWakeTriggered = false
    private var localAnalysisStartDate: Date?
    private var lastHRJumpEpochIndex = 0
    #if DEBUG
    private var testLightEpochsInjected = 0
    private var didCompleteTestLightEpochInjection = false
    #endif
    
    private var hrQuery: HKAnchoredObjectQuery?
    private var hrSamplesBuffer: [Double] = []
    private var payloadTimer: AnyCancellable?
    private var sensorsRunning = false
    
    // CoreMotion background anchors
    private var motionDeviationSamples: [Double] = []
    private var motionCountBuffer: Double = 0
    private let motionQueue = OperationQueue()
    
    // For Mocking
    private var mockTimer: AnyCancellable?
    
    override init() {
        super.init()
        restorePendingPayloadQueue()
        restorePendingNextAlarmCommand()
        setupWatchConnectivity()
        refreshNextAlarmDate()
        loadWatchModel()
    }

    var hasPendingSchedule: Bool {
        pendingScheduledStartDate != nil
    }

    var pendingScheduleDescription: String? {
        guard let date = pendingScheduledStartDate else { return nil }
        return "Queued for \(date.formatted(date: .omitted, time: .shortened))"
    }

    var hasReadySchedule: Bool {
        readyScheduledStartDate != nil
    }

    var readyScheduleDescription: String? {
        guard let date = readyScheduledStartDate else { return nil }
        return "Ready for \(date.formatted(date: .omitted, time: .shortened))"
    }

    var connectivityState: WatchConnectivityState {
        guard let session = wcSession, WCSession.isSupported() else {
            return .watchOnly
        }

        guard session.activationState == .activated else {
            return .watchOnly
        }

        if session.isReachable {
            return .synced
        }

        return .queued
    }

    private var isActivelyMonitoring: Bool {
        sensorsRunning ||
        runtimeSession?.state == .running ||
        pipelineState == .recording ||
        pipelineState == .deliveringBacklog
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    func refreshConnectionStatus() {
        guard let session = wcSession else {
            connectionStatus = "Disconnected"
            sendWatchStatusUpdate(sessionState)
            return
        }

        guard session.activationState == .activated else {
            connectionStatus = "Session not activated"
            sendWatchStatusUpdate(sessionState)
            return
        }

        if session.isReachable {
            connectionStatus = pendingPayloads.isEmpty ? "Phone reachable" : "Phone reachable, pending \(pendingPayloads.count)"
        } else {
            connectionStatus = pendingPayloads.isEmpty ? "Phone unavailable, queued delivery" : "Phone unavailable, pending \(pendingPayloads.count)"
        }
        sendWatchStatusUpdate(sessionState)
        flushPendingPayloadsIfNeeded(force: session.isReachable)
        flushPendingNextAlarmCommandIfNeeded()
    }

    func retryPendingPayloadDelivery() {
        refreshConnectionStatus()
        flushPendingPayloadsIfNeeded(force: true)
        flushPendingNextAlarmCommandIfNeeded()
    }

    func resumeScheduledSession(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        runtimeSession = extendedRuntimeSession
        runtimeSession?.delegate = self
        clearPendingSchedule()
        clearReadySchedule()
        updatePipelineState(.recording, detail: "Session resumed by system")
        if extendedRuntimeSession.state == .running {
            startSensors()
        }
        sendWatchStatusUpdate(sessionState)
    }

    func refreshStoredAlarmStateIfNeeded() {
        if let interval = UserDefaults.standard.object(forKey: Self.actualAlarmTimeKey) as? TimeInterval {
            let storedDate = Date(timeIntervalSince1970: interval)
            if storedDate <= Date() {
                clearAlarmTracking()
                return
            }
        }

        if let interval = UserDefaults.standard.object(forKey: Self.pendingScheduleKey) as? TimeInterval {
            let pendingDate = Date(timeIntervalSince1970: interval)
            if pendingDate <= Date() {
                clearPendingSchedule()
            }
        }

        refreshNextAlarmDate()
        requestAlarmSync()
    }

    func requestAlarmSync() {
        guard let session = wcSession, session.activationState == .activated else { return }
        let message = ["action": "requestAlarmSync"]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    func requestHealthPermissions(completion: @escaping (Bool) -> Void) {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: nil, read: [hrType]) { success, _ in
            if success {
                self.enableHeartRateBackgroundDelivery()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func scheduleSmartAlarmSession(at date: Date) {
        #if targetEnvironment(simulator)
        self.isMocking = true
        #else
        self.isMocking = false
        #endif

        if let existing = self.runtimeSession {
            if existing.state == .running || existing.state == .scheduled {
                suppressNextRuntimeInvalidation = true
                existing.invalidate()
            }
        }

        resetLocalAnalysis(startDate: date)
        self.runtimeSession = WKExtendedRuntimeSession()
        self.runtimeSession?.delegate = self
        self.runtimeSession?.start(at: date)
        storeReadySchedule(date)
        clearPendingSchedule()
        refreshNextAlarmDate()
        updatePipelineState(.scheduled, detail: "Ready for \(date.formatted(date: .omitted, time: .shortened))")
        sendWatchStatusUpdate(sessionState)
    }

    func setPendingScheduleIfPossible() {
        guard let date = pendingScheduledStartDate else { return }

        guard WKExtension.shared().applicationState == .active else {
            DispatchQueue.main.async {
                self.updatePipelineState(.scheduled, detail: "Open Ninety to set tonight's alarm")
            }
            sendWatchStatusUpdate("Open Ninety on Apple Watch to set Smart Alarm")
            return
        }

        scheduleSmartAlarmSession(at: date)
    }
    
    func stopSession() {
        clearScheduledAlarmAndMonitoring(
            detail: "Manually Stopped",
            state: .completed
        )
    }

    func pauseMonitoring() {
        clearScheduledAlarmAndMonitoring(
            detail: "Monitoring Paused After Alarm",
            state: .completed
        )
    }

    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.runtimeSession = extendedRuntimeSession
            self.clearReadySchedule()
            self.updatePipelineState(.recording, detail: "Session Started")
            self.startSensors()
            self.sendWatchStatusUpdate(self.sessionState)
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.updatePipelineState(.recording, detail: "Session Expiring Soon")
            self.sendWatchStatusUpdate(self.sessionState)

            guard
                let nextAlarmDate = self.nextAlarmDate,
                nextAlarmDate.timeIntervalSinceNow <= self.runtimeExpiryAlarmTolerance
            else {
                return
            }

            self.handleScheduledAlarmReached(reason: "Alarm active (runtime deadline)")
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        DispatchQueue.main.async {
            if self.suppressNextRuntimeInvalidation {
                self.suppressNextRuntimeInvalidation = false
                return
            }

            self.runtimeSession = nil
            self.clearReadySchedule()
            if
                let nsError = error as NSError?,
                nsError.domain == WKExtendedRuntimeSessionErrorDomain,
                let wkErrorCode = WKExtendedRuntimeSessionErrorCode(rawValue: nsError.code)
            {
                switch wkErrorCode {
                case .scheduledTooFarInAdvance:
                    // future day (>36h away). Re-queue it so the Watch sets it automatically
                    // when opened closer to bedtime.
                    if let startDate = self.pendingScheduledStartDate ?? self.readyScheduledStartDate {
                        UserDefaults.standard.set(startDate.timeIntervalSince1970, forKey: Self.pendingScheduleKey)
                        let formatted = startDate.formatted(date: .abbreviated, time: .shortened)
                        self.updatePipelineState(.scheduled, detail: "Next alarm: \(formatted)")
                    } else {
                        self.updatePipelineState(.idle, detail: "Open Ninety to set alarm")
                    }
                case .mustBeActiveToStartOrSchedule:
                    self.updatePipelineState(.failed, detail: "Error: Must be in foreground")
                default:
                    self.updatePipelineState(.failed, detail: "Invalidated: \(wkErrorCode.rawValue)")
                }
            } else {
                self.updatePipelineState(.failed, detail: "Session Invalidated")
            }
            self.sendWatchStatusUpdate(self.sessionState)
            self.stopSensors()
        }
    }
    
    // MARK: - Sensor Acquisition
    
    private func startSensors() {
        guard !sensorsRunning else { return }
        guard !stopMonitoringIfAlarmDeadlineReached() else { return }
        if localAnalysisStartDate == nil {
            localAnalysisStartDate = Date()
        }
        sensorsRunning = true
        #if targetEnvironment(simulator)
        startMockDataStream()
        #else
        startRealSensors()
        #endif
    }
    
    private func stopSensors() {
        sensorsRunning = false
        motionManager.stopAccelerometerUpdates()
        if let query = hrQuery {
            healthStore.stop(query)
            hrQuery = nil
        }
        payloadTimer?.cancel()
        payloadTimer = nil
        motionDeviationSamples.removeAll()
        motionCountBuffer = 0
        hrSamplesBuffer.removeAll()
        mockTimer?.cancel()
        mockTimer = nil
    }
    
    private func startRealSensors() {
        motionDeviationSamples.removeAll()
        motionCountBuffer = 0
        hrSamplesBuffer.removeAll()
        enableHeartRateBackgroundDelivery()
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50 Hz
            motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                
                let magnitude = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))
                let deviation = abs(magnitude - 1.0)

                self.motionDeviationSamples.append(deviation)
                if deviation >= self.motionThreshold {
                    self.motionCountBuffer += 1
                }
            }
        }

        payloadTimer = Timer.publish(every: payloadInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.compileAndTransmitPayload()
            }
        
        // Start HR
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        hrQuery = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        
        hrQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        
        if let query = hrQuery {
            healthStore.execute(query)
        }
    }
    
    private func processHRSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        let newValues = quantitySamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        
        DispatchQueue.main.async {
            self.hrSamplesBuffer.append(contentsOf: newValues)
        }
    }
    
    private func compileAndTransmitPayload() {
        guard !stopMonitoringIfAlarmDeadlineReached() else { return }

        let motionVariance = standardDeviation(for: motionDeviationSamples)
        let payload = SensorPayload(
            id: UUID(),
            timestamp: Date(),
            hrSamples: hrSamplesBuffer,
            motionCount: motionCountBuffer,
            accelerometerVariance: motionVariance,
            isMockData: false
        )
        
        hrSamplesBuffer.removeAll()
        motionDeviationSamples.removeAll()
        motionCountBuffer = 0
        
        transmit(payload: payload)
        processPayloadForLocalSmartWake(payload)
        
        if let alarmDate = nextAlarmDate, Date() >= alarmDate {
            DispatchQueue.main.async {
                print("WATCH: Reached scheduled wake time.")
                self.handleScheduledAlarmReached(reason: "Alarm active (local deadline)")
            }
        }
    }
    
    private func transmit(payload: SensorPayload) {
        if isActivelyMonitoring && pipelineState != .deliveringBacklog {
            updatePipelineState(.recording, detail: "Recording")
        }

        enqueuePendingPayload(payload)
        if let lastIndex = pendingPayloads.indices.last {
            sendPendingPayloads(at: [lastIndex], reason: "Live delivery")
        }

        DispatchQueue.main.async {
            self.lastPayloadSent = "Captured at \(payload.timestamp.formatted(date: .omitted, time: .standard)), HR count: \(payload.hrSamples.count), pending: \(self.pendingPayloads.count)"
        }
    }

    // MARK: - Watch-Local Smart Alarm Model

    private func loadWatchModel() {
        guard let modelURL = Bundle.main.url(forResource: "NeuralWakeUP", withExtension: "mlmodelc") else {
            replayStatusText = "Watch ML missing"
            return
        }

        do {
            let configuration = MLModelConfiguration()
            watchStageModel = try MLModel(contentsOf: modelURL, configuration: configuration)
            replayStatusText = "Watch ML ready"
        } catch {
            replayStatusText = "Watch ML failed: \(error.localizedDescription)"
        }
    }

    private func resetLocalAnalysis(startDate: Date? = nil) {
        currentEpochPayloads.removeAll()
        epochHistory.removeAll()
        rawPredictions.removeAll()
        confirmationBuffer.removeAll()
        isConfirmingSmartWake = false
        smartWakeTriggered = false
        lastHRJumpEpochIndex = 0
        localAnalysisStartDate = startDate
        #if DEBUG
        testLightEpochsInjected = 0
        didCompleteTestLightEpochInjection = false
        #endif
    }

    private func processPayloadForLocalSmartWake(_ payload: SensorPayload) {
        guard !smartWakeTriggered else { return }
        guard let targetDate = currentAlarmTargetDate(), payload.timestamp < targetDate else { return }

        if let lastTimestamp = currentEpochPayloads.last?.timestamp ?? epochHistory.last?.timestamp {
            let gap = payload.timestamp.timeIntervalSince(lastTimestamp)
            if gap > 300 {
                resetLocalAnalysis(startDate: Date())
            }
        }

        currentEpochPayloads.append(payload)
        let epochStart = currentEpochPayloads.first?.timestamp ?? payload.timestamp
        guard payload.timestamp.timeIntervalSince(epochStart) >= epochDuration else {
            return
        }

        let hrValues = currentEpochPayloads.flatMap(\.hrSamples)
        var hrMean = hrValues.isEmpty ? 0 : hrValues.reduce(0, +) / Double(hrValues.count)
        var hrStd = standardDeviation(for: hrValues)
        var hrRange = hrValues.isEmpty ? 0 : (hrValues.max()! - hrValues.min()!)

        if hrMean < 30 {
            if let previousEpoch = epochHistory.last {
                hrMean = previousEpoch.heartRateMean
                hrStd = previousEpoch.heartRateStd
                hrRange = previousEpoch.heartRateRange
            } else {
                hrMean = 60
                hrStd = 0
                hrRange = 0
            }
        }

        let motionValues = currentEpochPayloads.map(\.motionCount)
        let motionMagMean = motionValues.reduce(0, +) / max(Double(motionValues.count), 1)
        let motionMagMax = motionValues.max() ?? 0
        let previousMotion = epochHistory.last?.motionMagMean ?? motionMagMean
        let motionJerk = abs(motionMagMean - previousMotion)

        let epoch = WatchEpochAggregate(
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

        if epochHistory.count >= 2 {
            let previousHR = epochHistory[epochHistory.count - 2].heartRateMean
            if abs(epoch.heartRateMean - previousHR) > 5 {
                lastHRJumpEpochIndex = epochHistory.count - 1
            }
        }

        guard epochHistory.count >= minimumEpochsForFeatures else {
            updatePipelineState(.recording, detail: "Watch ML warming \(epochHistory.count)/\(minimumEpochsForFeatures)")
            sendWatchEpochDiagnostic(
                for: epoch,
                rawStage: nil,
                smoothedStage: nil,
                stageTitle: "Warming \(epochHistory.count)/\(minimumEpochsForFeatures)",
                isTestInjected: false
            )
            return
        }

        guard var prediction = makeWatchPrediction(forEpochAt: epochHistory.count - 1) else {
            sendWatchEpochDiagnostic(
                for: epoch,
                rawStage: nil,
                smoothedStage: nil,
                stageTitle: "Unavailable",
                isTestInjected: false
            )
            return
        }

        prediction = predictionAfterApplyingTestLightInjection(prediction)
        sendWatchEpochDiagnostic(
            for: prediction.epoch,
            rawStage: prediction.rawStage,
            smoothedStage: prediction.smoothedStage,
            stageTitle: prediction.smoothedStage.title,
            isTestInjected: prediction.isTestInjected
        )
        updatePipelineState(.recording, detail: "Watch ML \(prediction.smoothedStage.title)")
        evaluateLocalSmartWake(for: prediction, targetDate: targetDate)
    }

    private func makeWatchPrediction(forEpochAt index: Int) -> WatchPredictionSnapshot? {
        guard let watchStageModel else {
            replayStatusText = "Watch ML unavailable"
            return nil
        }

        let features = computeWatchFeatures(forEpochAt: index)
        let epoch = epochHistory[index]

        do {
            let input = features.mapValues { NSNumber(value: $0) }
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let prediction = try watchStageModel.prediction(from: provider)

            guard
                let rawValue = prediction.featureValue(for: "target")?.int64Value,
                let rawStage = WatchSleepStage(rawValue: Int(rawValue))
            else {
                replayStatusText = "Watch ML output missing"
                return nil
            }

            rawPredictions.append(rawStage)
            if rawPredictions.count > smoothingWindowSize {
                rawPredictions.removeFirst(rawPredictions.count - smoothingWindowSize)
            }

            let smoothedStage = modeStage(from: rawPredictions) ?? rawStage
            replayStatusText = "Watch ML raw \(rawStage.title), smooth \(smoothedStage.title)"
            return WatchPredictionSnapshot(
                rawStage: rawStage,
                smoothedStage: smoothedStage,
                epoch: epoch,
                isTestInjected: false
            )
        } catch {
            replayStatusText = "Watch ML prediction failed: \(error.localizedDescription)"
            return nil
        }
    }

    private func predictionAfterApplyingTestLightInjection(_ prediction: WatchPredictionSnapshot) -> WatchPredictionSnapshot {
        #if DEBUG
        guard testLightEpochInjectionEnabled, !didCompleteTestLightEpochInjection, !smartWakeTriggered else {
            return prediction
        }

        let startDate = localAnalysisStartDate ?? epochHistory.first?.timestamp ?? prediction.epoch.timestamp
        guard prediction.epoch.timestamp.timeIntervalSince(startDate) >= testLightEpochInjectionDelay else {
            return prediction
        }

        if testLightEpochsInjected == 0 {
            confirmationBuffer.removeAll()
            isConfirmingSmartWake = false
        }

        testLightEpochsInjected += 1
        if testLightEpochsInjected >= testLightEpochInjectionCount {
            didCompleteTestLightEpochInjection = true
        }

        replayStatusText = "TEST Light \(testLightEpochsInjected)/\(testLightEpochInjectionCount)"
        return WatchPredictionSnapshot(
            rawStage: .light,
            smoothedStage: .light,
            epoch: prediction.epoch,
            isTestInjected: true
        )
        #else
        return prediction
        #endif
    }

    private func evaluateLocalSmartWake(for prediction: WatchPredictionSnapshot, targetDate: Date) {
        guard !smartWakeTriggered else { return }
        guard localSmartWakeCanTrigger(for: prediction, targetDate: targetDate) else { return }

        if prediction.smoothedStage == .light {
            if !isConfirmingSmartWake {
                isConfirmingSmartWake = true
                confirmationBuffer.removeAll()
            }

            confirmationBuffer.append(prediction.smoothedStage)
        } else if isConfirmingSmartWake {
            confirmationBuffer.append(prediction.smoothedStage)
        } else {
            return
        }

        let progress = "\(confirmationBuffer.count)/\(confirmationRequired)"
        updatePipelineState(.recording, detail: "Watch ML verify \(progress)")

        guard confirmationBuffer.count >= confirmationRequired else { return }

        let lightCount = confirmationBuffer.filter { $0 == .light }.count
        if lightCount >= confirmationThreshold {
            smartWakeTriggered = true
            triggerLocalSmartWake(reason: "Smart Wake (Watch ML \(lightCount)/\(confirmationRequired))")
        } else {
            confirmationBuffer.removeAll()
            isConfirmingSmartWake = false
        }
    }

    private func sendWatchEpochDiagnostic(
        for epoch: WatchEpochAggregate,
        rawStage: WatchSleepStage?,
        smoothedStage: WatchSleepStage?,
        stageTitle: String,
        isTestInjected: Bool
    ) {
        guard let session = wcSession, session.activationState == .activated else { return }

        let diagnostic = WatchEpochDiagnostic(
            id: UUID(),
            timestamp: epoch.timestamp,
            processedAt: Date(),
            heartRateMean: epoch.heartRateMean,
            heartRateStd: epoch.heartRateStd,
            heartRateRange: epoch.heartRateRange,
            motionMagMean: epoch.motionMagMean,
            motionMagMax: epoch.motionMagMax,
            motionJerk: epoch.motionJerk,
            rawStage: rawStage?.rawValue,
            smoothedStage: smoothedStage?.rawValue,
            stageTitle: stageTitle,
            isTestInjected: isTestInjected
        )

        guard let encoded = try? JSONEncoder().encode(diagnostic) else { return }

        let message: [String: Any] = [
            "action": "watchEpochDiagnostic",
            "watchEpochData": encoded
        ]

        session.transferUserInfo(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func localSmartWakeCanTrigger(for prediction: WatchPredictionSnapshot, targetDate: Date) -> Bool {
        let now = Date()
        guard now < targetDate else { return false }
        guard now < targetDate.addingTimeInterval(-alarmFinalMinuteBuffer) else {
            confirmationBuffer.removeAll()
            isConfirmingSmartWake = false
            return false
        }

        let predictionAge = max(0, now.timeIntervalSince(prediction.epoch.timestamp))
        guard predictionAge <= maximumDynamicPredictionAge else {
            confirmationBuffer.removeAll()
            isConfirmingSmartWake = false
            return false
        }

        return true
    }

    private func triggerLocalSmartWake(reason: String) {
        runtimeSession?.notifyUser(hapticType: .notification)
        HapticWakeUpManager.shared.startGradualWakeUp()
        
        // Tell the phone to start the same Ninety alarm.
        sendTriggerAlarmMessage()
        
        clearScheduledAlarmAndMonitoring(
            detail: reason,
            state: .completed,
            keepHapticsRunning: true
        )
    }

    private func currentAlarmTargetDate() -> Date? {
        if let nextAlarmDate {
            return nextAlarmDate
        }

        guard let interval = UserDefaults.standard.object(forKey: Self.actualAlarmTimeKey) as? TimeInterval else {
            return nil
        }

        let storedDate = Date(timeIntervalSince1970: interval)
        return storedDate > Date() ? storedDate : nil
    }

    private func createPaddedWindow(endIndex: Int, requiredCount: Int) -> [WatchEpochAggregate] {
        let availableCount = endIndex + 1
        var window = Array(epochHistory[max(0, endIndex - requiredCount + 1)...endIndex])

        if availableCount < requiredCount, let earliestKnown = window.first {
            let paddingCount = requiredCount - availableCount
            window = Array(repeating: earliestKnown, count: paddingCount) + window
        }

        return window
    }

    private func computeWatchFeatures(forEpochAt index: Int) -> [String: Double] {
        let epoch = epochHistory[index]

        let epochs2m = createPaddedWindow(endIndex: index, requiredCount: 4)
        let epochs5m = createPaddedWindow(endIndex: index, requiredCount: 10)
        let epochs10m = createPaddedWindow(endIndex: index, requiredCount: 20)

        let motionMags2m = epochs2m.map(\.motionMagMean)
        let motionMags5m = epochs5m.map(\.motionMagMean)
        let motionMags10m = epochs10m.map(\.motionMagMean)
        let jerk5m = epochs5m.map(\.motionJerk)

        let hrMeans5m = epochs5m.map(\.heartRateMean)
        let hrMeans10m = epochs10m.map(\.heartRateMean)
        let hrStds5m = epochs5m.map(\.heartRateStd)
        let hrRanges5m = epochs5m.map(\.heartRateRange)

        let motionEpochMagMean = epoch.motionMagMean
        let motionEpochMagMax = epoch.motionMagMax

        let motionHist2mMagMean = mean(of: motionMags2m)
        let motionHist2mMagStd = standardDeviation(for: motionMags2m)
        let motionHist5mMagMean = mean(of: motionMags5m)
        let motionHist5mMagStd = standardDeviation(for: motionMags5m)
        let motionHist5mMagMax = motionMags5m.max() ?? 0
        let motionHist5mMagSum = motionMags5m.reduce(0, +)
        let motionHist10mMagMean = mean(of: motionMags10m)
        let motionHist10mMagStd = standardDeviation(for: motionMags10m)
        let motionHist5mJerkStd = standardDeviation(for: jerk5m)

        let motionEpochJerkMinusHist5mMean = epoch.motionJerk - mean(of: jerk5m)
        let motionEpochMagMinusHist5mMean = motionEpochMagMean - motionHist5mMagMean
        let motionEpochMagMinusHist2mMean = motionEpochMagMean - motionHist2mMagMean

        let hrHist5mMean = mean(of: hrMeans5m)
        let hrHist5mStd = standardDeviation(for: hrMeans5m)
        let hrHist10mMean = mean(of: hrMeans10m)
        let hrHist10mStd = standardDeviation(for: hrMeans10m)
        let hrHist5mCV = hrHist5mMean > 0 ? hrHist5mStd / hrHist5mMean : 0
        let hrHist10mCV = hrHist10mMean > 0 ? hrHist10mStd / hrHist10mMean : 0

        let hrEpochRangeMinusHist5mRange = epoch.heartRateRange - mean(of: hrRanges5m)
        let hrEpochStdMinusHist5mStd = epoch.heartRateStd - mean(of: hrStds5m)
        let hrEpochMeanDivHist10mMean = hrHist10mMean > 0 ? epoch.heartRateMean / hrHist10mMean : 1

        let startDate = localAnalysisStartDate ?? epochHistory.first?.timestamp ?? epoch.timestamp
        let elapsedMinutes = epoch.timestamp.timeIntervalSince(startDate) / 60
        let timeHoursFromStart = elapsedMinutes / 60
        let minutesSinceJump = Double(index - lastHRJumpEpochIndex) * 0.5

        return [
            "motion_hist5m_mag_max_log1p": log1p(motionHist5mMagMax),
            "motion_hist10m_mag_std_log1p": log1p(motionHist10mMagStd),
            "motion_hist5m_jerk_std_log1p": log1p(motionHist5mJerkStd),
            "motion_hist5m_mag_std_log1p": log1p(motionHist5mMagStd),
            "hr_hist10m_cv_raw": hrHist10mCV,
            "hr_hist5m_cv_raw": hrHist5mCV,
            "hr_hist10m_std_raw": hrHist10mStd,
            "hr_hist5m_std_raw": hrHist5mStd,
            "minutes_since_last_hr_jump_log1p": log1p(minutesSinceJump),
            "time_hours_from_start": timeHoursFromStart,
            "elapsed_minutes_log1p": log1p(elapsedMinutes),
            "motion_hist10m_mag_mean_log1p": log1p(motionHist10mMagMean),
            "motion_epoch_jerk_minus_hist5m_mean": motionEpochJerkMinusHist5mMean,
            "motion_hist5m_mag_mean_log1p": log1p(motionHist5mMagMean),
            "motion_hist5m_mag_sum_log1p": log1p(motionHist5mMagSum),
            "motion_epoch_mag_minus_hist5m_mean": motionEpochMagMinusHist5mMean,
            "motion_hist2m_mag_std_log1p": log1p(motionHist2mMagStd),
            "motion_hist2m_mag_mean_log1p": log1p(motionHist2mMagMean),
            "hr_epoch_range_minus_hist5m_range": hrEpochRangeMinusHist5mRange,
            "motion_epoch_mag_mean_log1p": log1p(motionEpochMagMean),
            "hr_epoch_std_minus_hist5m_std": hrEpochStdMinusHist5mStd,
            "hr_epoch_mean_div_hist10m_mean": hrEpochMeanDivHist10mMean,
            "motion_epoch_mag_minus_hist2m_mean": motionEpochMagMinusHist2mMean,
            "hr_hist10m_mean_raw": hrHist10mMean,
            "motion_epoch_mag_max_log1p": log1p(motionEpochMagMax)
        ]
    }

    private func modeStage(from values: [WatchSleepStage]) -> WatchSleepStage? {
        guard !values.isEmpty else { return nil }

        let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        let maxCount = counts.values.max() ?? 0
        let candidates = counts.compactMap { stage, count in
            count == maxCount ? stage : nil
        }

        for stage in values.reversed() where candidates.contains(stage) {
            return stage
        }

        return values.last
    }

    private func mean(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Mocking Data
    
    private func startMockDataStream() {
        mockTimer = Timer.publish(every: payloadInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
            let mockPayload = SensorPayload(
                id: UUID(),
                timestamp: Date(),
                hrSamples: [Double.random(in: 55...65), Double.random(in: 50...60)],
                motionCount: Double.random(in: 0...30),
                accelerometerVariance: Double.random(in: 0.0...0.5),
                isMockData: true
            )
            self?.transmit(payload: mockPayload)
            self?.processPayloadForLocalSmartWake(mockPayload)
        }
    }

    func setNextAlarm(wakeTime: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
        setNextAlarm(
            hour: components.hour ?? 7,
            minute: components.minute ?? 0
        )
    }

    func markNextAlarmDraftChanged() {
        guard weeklyAlarmSyncState == .saved || weeklyAlarmSyncState == .failed else {
            return
        }

        weeklyAlarmSyncState = pendingNextAlarmCommand() == nil ? .synced : .pending
        weeklyAlarmSyncDetail = nil
    }

    private func setNextAlarm(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            weeklyAlarmSyncState = .failed
            weeklyAlarmSyncDetail = "Invalid alarm draft"
            return
        }

        let command = PendingNextAlarmCommand(
            hour: hour,
            minute: minute,
            enqueuedAt: Date()
        )
        sendNextAlarmCommand(command)
    }

    // MARK: - Next Alarm Commands

    private func restorePendingNextAlarmCommand() {
        guard pendingNextAlarmCommand() != nil else { return }
        weeklyAlarmSyncState = .pending
        weeklyAlarmSyncDetail = nil
    }

    private func pendingNextAlarmCommand() -> PendingNextAlarmCommand? {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingNextAlarmCommandKey) else {
            return nil
        }

        guard let command = try? JSONDecoder().decode(PendingNextAlarmCommand.self, from: data) else {
            UserDefaults.standard.removeObject(forKey: Self.pendingNextAlarmCommandKey)
            return nil
        }

        return command
    }

    private func persistPendingNextAlarmCommand(_ command: PendingNextAlarmCommand, state: WatchWeeklyAlarmSyncState) {
        guard let data = try? JSONEncoder().encode(command) else {
            weeklyAlarmSyncState = .failed
            weeklyAlarmSyncDetail = "Unable to store pending alarm"
            return
        }

        UserDefaults.standard.set(data, forKey: Self.pendingNextAlarmCommandKey)
        weeklyAlarmSyncState = state
        weeklyAlarmSyncDetail = nil
    }

    private func clearPendingNextAlarmCommand() {
        UserDefaults.standard.removeObject(forKey: Self.pendingNextAlarmCommandKey)
    }

    private func flushPendingNextAlarmCommandIfNeeded() {
        guard !isSendingNextAlarmCommand, let command = pendingNextAlarmCommand() else {
            return
        }

        sendNextAlarmCommand(command)
    }

    private func sendNextAlarmCommand(_ command: PendingNextAlarmCommand) {
        guard !isSendingNextAlarmCommand else {
            persistPendingNextAlarmCommand(command, state: .pending)
            return
        }

        guard let session = wcSession, session.activationState == .activated else {
            persistPendingNextAlarmCommand(command, state: .pending)
            return
        }

        guard session.isReachable else {
            persistPendingNextAlarmCommand(command, state: .unreachable)
            return
        }

        isSendingNextAlarmCommand = true
        persistPendingNextAlarmCommand(command, state: .saving)
        weeklyAlarmSyncState = .saving
        weeklyAlarmSyncDetail = nil

        session.sendMessage(command.message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleNextAlarmReply(reply, command: command)
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSendingNextAlarmCommand = false
                if let pendingCommand = self.pendingNextAlarmCommand(), pendingCommand != command {
                    self.weeklyAlarmSyncState = .pending
                    self.weeklyAlarmSyncDetail = nil
                    self.flushPendingNextAlarmCommandIfNeeded()
                } else {
                    self.persistPendingNextAlarmCommand(command, state: .pending)
                    self.weeklyAlarmSyncDetail = error.localizedDescription
                }
            }
        })
    }

    private func handleNextAlarmReply(_ reply: [String: Any], command: PendingNextAlarmCommand) {
        isSendingNextAlarmCommand = false

        if let pendingCommand = pendingNextAlarmCommand(), pendingCommand != command {
            weeklyAlarmSyncState = .pending
            weeklyAlarmSyncDetail = nil
            flushPendingNextAlarmCommandIfNeeded()
            return
        }

        if let error = reply["error"] as? String {
            clearPendingNextAlarmCommand()
            weeklyAlarmSyncState = .failed
            weeklyAlarmSyncDetail = error
            return
        }

        clearPendingNextAlarmCommand()
        weeklyAlarmSyncState = (reply["status"] as? String) == "stale" ? .synced : .saved
        weeklyAlarmSyncDetail = reply["dialog"] as? String

        if let targetInterval = reply["targetDate"] as? TimeInterval {
            UserDefaults.standard.set(targetInterval, forKey: Self.actualAlarmTimeKey)
            refreshNextAlarmDate()
        } else {
            requestAlarmSync()
        }
    }

    private func enableHeartRateBackgroundDelivery() {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.enableBackgroundDelivery(for: hrType, frequency: .immediate) { success, error in
            if let error {
                DispatchQueue.main.async {
                    self.connectionStatus = "HK background failed: \(error.localizedDescription)"
                }
                return
            }

            if success {
                DispatchQueue.main.async {
                    if self.connectionStatus == "Disconnected" || self.connectionStatus.hasPrefix("HK background failed") {
                        self.connectionStatus = "HK background enabled"
                    }
                }
            }
        }
    }

    private func standardDeviation(for values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { partialResult, value in
            partialResult + pow(value - mean, 2)
        } / Double(values.count)
        return sqrt(variance)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.refreshConnectionStatus()
            if activationState == .activated {
                self.requestAlarmSync()
            }
            self.flushPendingPayloadsIfNeeded(force: true)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.refreshConnectionStatus()
            if session.isReachable {
                self.requestAlarmSync()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingCommand(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        processIncomingCommand(userInfo)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        processIncomingCommand(applicationContext)
    }
    
    private func processIncomingCommand(_ payload: [String: Any]) {
        if let action = payload["action"] as? String {
            if action == "ackPayloads" {
                let idStrings = payload["ids"] as? [String] ?? []
                DispatchQueue.main.async {
                    self.acknowledgePayloads(withIDs: idStrings.compactMap(UUID.init(uuidString:)))
                }
            } else if action == "startSession" {
                guard shouldProcessPhoneCommand(payload) else { return }
                guard let targetInterval = payload["targetDate"] as? TimeInterval else { return }
                prepareForNewSession()
                UserDefaults.standard.set(targetInterval, forKey: Self.actualAlarmTimeKey)
                refreshNextAlarmDate()
                var wakeWindowStartDate = Date(timeIntervalSince1970: targetInterval).addingTimeInterval(-30 * 60)
                if wakeWindowStartDate <= Date() {
                    wakeWindowStartDate = Date().addingTimeInterval(2)
                }
                DispatchQueue.main.async {
                    self.queueOrScheduleSmartAlarmSession(at: wakeWindowStartDate)
                }
            } else if action == "stopSession" {
                guard shouldProcessPhoneCommand(payload) else { return }
                DispatchQueue.main.async {
                    self.stopSession()
                }
            } else if action == "pauseMonitoring" {
                guard shouldProcessPhoneCommand(payload) else { return }
                DispatchQueue.main.async {
                    self.pauseMonitoring()
                }
            } else if action == "stopAlarm" {
                guard shouldProcessPhoneCommand(payload) else { return }
                DispatchQueue.main.async {
                    self.clearScheduledAlarmAndMonitoring(
                        detail: "Alarm Stopped",
                        state: .idle
                    )
                }
            } else if action == "hapticWakeUp" {
                DispatchQueue.main.async {
                    print("WATCH: Received hapticWakeUp from iPhone.")
                    self.runtimeSession?.notifyUser(hapticType: .notification)
                    HapticWakeUpManager.shared.startGradualWakeUp()
                    self.clearScheduledAlarmAndMonitoring(detail: "Alarm Triggered by Phone", state: .completed, keepHapticsRunning: true)
                }
            } else if action == "syncAlarmState" {
                guard shouldProcessPhoneCommand(payload) else { return }
                if let targetInterval = payload["targetDate"] as? TimeInterval {
                    UserDefaults.standard.set(targetInterval, forKey: Self.actualAlarmTimeKey)
                    print("WATCH: Received syncAlarmState for \(Date(timeIntervalSince1970: targetInterval))")
                    DispatchQueue.main.async {
                        self.refreshNextAlarmDate()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.clearScheduledAlarmAndMonitoring(
                            detail: "Alarm Removed",
                            state: .idle
                        )
                    }
                    print("WATCH: Received syncAlarmState (clear)")
                }
            }
        }
    }

    // MARK: - Reliable Payload Delivery

    private var pendingPayloadsURL: URL? {
        guard let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directory = supportDirectory.appendingPathComponent("Ninety", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("watch_pending_payloads.json")
    }

    private func restorePendingPayloadQueue() {
        guard let url = pendingPayloadsURL else { return }

        guard FileManager.default.fileExists(atPath: url.path) else { return }

        guard
            let data = try? Data(contentsOf: url),
            let restored = try? JSONDecoder().decode([PendingPayloadEnvelope].self, from: data)
        else {
            try? FileManager.default.removeItem(at: url)
            return
        }

        pendingPayloads = Array(restored.suffix(maxPendingPayloads))
        if !pendingPayloads.isEmpty {
            replayStatusText = "Recovered \(pendingPayloads.count) pending payloads"
            updatePipelineState(.deliveringBacklog, detail: "Recovered \(pendingPayloads.count) pending payloads")
        }
    }

    private func prepareForNewSession() {
        clearAlarmTracking()
        resetLocalAnalysis()
        clearPendingPayloadQueue()
        replayStatusText = "No backlog activity"
        updatePipelineState(.idle)
    }

    private func invalidateRuntimeSessionIfNeeded() {
        if runtimeSession?.state == .running || runtimeSession?.state == .scheduled {
            suppressNextRuntimeInvalidation = true
            runtimeSession?.invalidate()
        }
        runtimeSession = nil
    }

    private func clearScheduledAlarmAndMonitoring(
        detail: String,
        state: WatchPipelineState,
        keepHapticsRunning: Bool = false
    ) {
        if !keepHapticsRunning {
            invalidateRuntimeSessionIfNeeded()
            HapticWakeUpManager.shared.stop()
        }
        clearAlarmTracking()
        stopSensors()
        resetLocalAnalysis()
        clearPendingPayloadQueue()
        updatePipelineState(state, detail: detail)
        sendWatchStatusUpdate(sessionState)
    }

    private func handleScheduledAlarmReached(reason: String) {
        let phoneReachable = wcSession?.activationState == .activated && wcSession?.isReachable == true
        
        // Start the silent Watch phase of the same Ninety alarm locally.
        runtimeSession?.notifyUser(hapticType: .notification)
        HapticWakeUpManager.shared.startGradualWakeUp()

        if phoneReachable {
            // Tell the phone to put the same AlarmKit alarm into countdown.
            sendTriggerAlarmMessage()
            
            clearScheduledAlarmAndMonitoring(
                detail: "Alarm active (syncing with iPhone)",
                state: .completed,
                keepHapticsRunning: true
            )
        } else {
            // Watch-only path: haptics are the available alert surface.
            clearScheduledAlarmAndMonitoring(
                detail: reason,
                state: .completed,
                keepHapticsRunning: true
            )
        }
    }

    private func enqueuePendingPayload(_ payload: SensorPayload) {
        guard !pendingPayloads.contains(where: { $0.payload.id == payload.id }) else { return }

        pendingPayloads.append(
            PendingPayloadEnvelope(
                payload: payload,
                enqueuedAt: Date(),
                lastAttemptAt: nil,
                deliveryAttempts: 0,
                deferredDeliveryQueued: false
            )
        )

        if pendingPayloads.count > maxPendingPayloads {
            pendingPayloads.removeFirst(pendingPayloads.count - maxPendingPayloads)
        }

        savePendingPayloadQueue()
        sendWatchStatusUpdate(sessionState)
    }

    private func acknowledgePayloads(withIDs ids: [UUID]) {
        guard !ids.isEmpty else { return }

        let acknowledgedIDs = Set(ids)
        let previousCount = pendingPayloads.count
        pendingPayloads.removeAll { acknowledgedIDs.contains($0.payload.id) }

        guard pendingPayloads.count != previousCount else { return }

        savePendingPayloadQueue()
        let removedCount = previousCount - pendingPayloads.count
        replayStatusText = "Acked \(removedCount), pending \(pendingPayloads.count)"
        connectionStatus = pendingPayloads.isEmpty ? "Phone reachable" : "Phone reachable, pending \(pendingPayloads.count)"

        if pendingPayloads.isEmpty {
            if isActivelyMonitoring {
                updatePipelineState(.recording, detail: "Recording")
            } else if readyScheduledStartDate != nil {
                updatePipelineState(.scheduled, detail: readyScheduleDescription ?? "Scheduled")
            } else if pendingScheduledStartDate != nil {
                updatePipelineState(.scheduled, detail: pendingScheduleDescription ?? "Scheduled")
            } else {
                updatePipelineState(.idle)
            }
        }

        sendWatchStatusUpdate(sessionState)
    }

    private func flushPendingPayloadsIfNeeded(force: Bool = false) {
        guard !pendingPayloads.isEmpty else { return }
        guard let session = wcSession, session.activationState == .activated else { return }

        let now = Date()
        if
            !force,
            let lastBacklogFlushDate,
            now.timeIntervalSince(lastBacklogFlushDate) < minimumBacklogFlushInterval
        {
            return
        }

        let batchCount = min(backlogReplayBatchSize, pendingPayloads.count)
        let indices = Array(pendingPayloads.indices.prefix(batchCount))
        guard !indices.isEmpty else { return }

        lastBacklogFlushDate = now
        updatePipelineState(.deliveringBacklog, detail: "Replaying \(batchCount)/\(pendingPayloads.count) payloads")
        replayStatusText = "Replaying \(batchCount)/\(pendingPayloads.count) payloads"
        sendPendingPayloads(at: indices, reason: "Backlog replay")
    }

    private func sendPendingPayloads(at indices: [Int], reason: String) {
        guard let session = wcSession, session.activationState == .activated else { return }
        guard !indices.isEmpty else { return }

        let reachable = session.isReachable
        let now = Date()
        var queueDidChange = false
        var sentCount = 0

        for index in indices {
            guard pendingPayloads.indices.contains(index) else { continue }
            guard let encoded = try? JSONEncoder().encode(pendingPayloads[index].payload) else { continue }

            pendingPayloads[index].lastAttemptAt = now
            pendingPayloads[index].deliveryAttempts += 1
            queueDidChange = true

            let dict: [String: Any] = ["payloadData": encoded]
            if !pendingPayloads[index].deferredDeliveryQueued {
                session.transferUserInfo(dict)
                pendingPayloads[index].deferredDeliveryQueued = true
            }

            if reachable {
                session.sendMessage(dict, replyHandler: nil) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.connectionStatus = "Live send failed: \(error.localizedDescription)"
                    }
                }
            }

            sentCount += 1
        }

        if queueDidChange {
            savePendingPayloadQueue()
        }

        connectionStatus = reachable ? "Phone reachable, pending \(pendingPayloads.count)" : "Phone unavailable, pending \(pendingPayloads.count)"
        replayStatusText = "\(reason): sent \(sentCount), pending \(pendingPayloads.count)"
        lastPayloadSent = "\(reason): sent \(sentCount), pending \(pendingPayloads.count)"
        sendWatchStatusUpdate(sessionState)
    }

    private func savePendingPayloadQueue() {
        guard let url = pendingPayloadsURL else { return }

        if pendingPayloads.isEmpty {
            try? FileManager.default.removeItem(at: url)
            return
        }

        do {
            let data = try JSONEncoder().encode(pendingPayloads)
            try data.write(to: url, options: [.atomic])
        } catch {
            connectionStatus = "Queue save failed: \(error.localizedDescription)"
        }
    }

    private func clearPendingPayloadQueue() {
        pendingPayloads.removeAll()
        savePendingPayloadQueue()
    }

    private func updatePipelineState(_ newState: WatchPipelineState, detail: String? = nil) {
        pipelineState = newState
        let display = detail ?? newState.label
        if Thread.isMainThread {
            sessionState = display
        } else {
            DispatchQueue.main.async {
                self.sessionState = display
            }
        }
    }

    private var pendingScheduledStartDate: Date? {
        let interval = UserDefaults.standard.object(forKey: Self.pendingScheduleKey) as? TimeInterval
        return interval.map(Date.init(timeIntervalSince1970:))
    }

    private var readyScheduledStartDate: Date? {
        let interval = UserDefaults.standard.object(forKey: Self.readyScheduleKey) as? TimeInterval
        return interval.map(Date.init(timeIntervalSince1970:))
    }

    private func refreshNextAlarmDate() {
        let interval = UserDefaults.standard.double(forKey: Self.actualAlarmTimeKey)
        let refreshedDate: Date?

        if interval > 0 {
            let storedDate = Date(timeIntervalSince1970: interval)
            refreshedDate = storedDate > Date() ? storedDate : nil
        } else {
            refreshedDate = nil
        }

        if Thread.isMainThread {
            nextAlarmDate = refreshedDate
        } else {
            DispatchQueue.main.async {
                self.nextAlarmDate = refreshedDate
            }
        }

        scheduleAlarmDeadlineTimer(for: refreshedDate)
    }

    private func shouldProcessPhoneCommand(_ payload: [String: Any]) -> Bool {
        guard let sequence = intValue(from: payload["commandSequence"]) else {
            return true
        }

        let lastProcessedSequence = UserDefaults.standard.integer(
            forKey: Self.lastProcessedPhoneCommandSequenceKey
        )
        guard sequence > lastProcessedSequence else {
            return false
        }

        UserDefaults.standard.set(sequence, forKey: Self.lastProcessedPhoneCommandSequenceKey)
        return true
    }

    private func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        if let stringValue = value as? String {
            return Int(stringValue)
        }

        return nil
    }

    private func queueOrScheduleSmartAlarmSession(at date: Date) {
        guard WKExtension.shared().applicationState == .active else {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.pendingScheduleKey)
            clearReadySchedule()
            updatePipelineState(.scheduled, detail: "Queued. Open Ninety to set tonight's alarm")
            sendWatchStatusUpdate("Open Ninety on Apple Watch to set Smart Alarm")
            return
        }

        scheduleSmartAlarmSession(at: date)
    }

    private func clearPendingSchedule() {
        UserDefaults.standard.removeObject(forKey: Self.pendingScheduleKey)
    }

    private func storeReadySchedule(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.readyScheduleKey)
    }

    private func clearReadySchedule() {
        UserDefaults.standard.removeObject(forKey: Self.readyScheduleKey)
    }

    private func clearAlarmTracking() {
        alarmDeadlineTimer?.invalidate()
        alarmDeadlineTimer = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingScheduleKey)
        UserDefaults.standard.removeObject(forKey: Self.readyScheduleKey)
        UserDefaults.standard.removeObject(forKey: Self.actualAlarmTimeKey)
        let shouldShowSyncedState = pendingNextAlarmCommand() == nil
        if Thread.isMainThread {
            nextAlarmDate = nil
            if shouldShowSyncedState {
                weeklyAlarmSyncState = .synced
                weeklyAlarmSyncDetail = nil
            }
        } else {
            DispatchQueue.main.async {
                self.nextAlarmDate = nil
                if shouldShowSyncedState {
                    self.weeklyAlarmSyncState = .synced
                    self.weeklyAlarmSyncDetail = nil
                }
            }
        }
    }

    private func scheduleAlarmDeadlineTimer(for alarmDate: Date?) {
        let schedule = {
            self.alarmDeadlineTimer?.invalidate()
            self.alarmDeadlineTimer = nil

            guard let alarmDate else {
                return
            }

            // Fire the haptic deadline 60 seconds BEFORE the actual alarm
            let hapticDeadlineDate = alarmDate.addingTimeInterval(-60)
            let delay = hapticDeadlineDate.timeIntervalSinceNow
            guard delay > 0 else {
                _ = self.stopMonitoringIfAlarmDeadlineReached()
                return
            }

            self.alarmDeadlineTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.stopMonitoringAtAlarmDeadline()
            }
        }

        if Thread.isMainThread {
            schedule()
        } else {
            DispatchQueue.main.async(execute: schedule)
        }
    }

    @discardableResult
    private func stopMonitoringIfAlarmDeadlineReached(now: Date = Date()) -> Bool {
        guard let interval = UserDefaults.standard.object(forKey: Self.actualAlarmTimeKey) as? TimeInterval else {
            return false
        }

        let alarmDate = Date(timeIntervalSince1970: interval)
        // Check against the 60-second advanced deadline
        let hapticDeadlineDate = alarmDate.addingTimeInterval(-60)
        guard now >= hapticDeadlineDate else {
            return false
        }

        stopMonitoringAtAlarmDeadline()
        return true
    }

    private func stopMonitoringAtAlarmDeadline() {
        guard UserDefaults.standard.object(forKey: Self.actualAlarmTimeKey) != nil || isActivelyMonitoring else {
            return
        }

        handleScheduledAlarmReached(reason: "Alarm active (deadline)")
    }

    private func sendWatchStatusUpdate(_ status: String) {
        guard let session = wcSession, session.activationState == .activated else { return }

        var message: [String: Any] = [
            "watchStatus": status,
            "statusTimestamp": Date().timeIntervalSince1970,
            "watchConnectionStatus": connectionStatus,
            "pendingPayloadCount": pendingPayloads.count,
            "replayStatus": replayStatusText,
            "pipelineState": pipelineState.rawValue
        ]
        
        if let queuedSchedule = pendingScheduledStartDate?.timeIntervalSince1970 {
            message["queuedSchedule"] = queuedSchedule
        }

        if let readySchedule = readyScheduledStartDate?.timeIntervalSince1970 {
            message["readySchedule"] = readySchedule
        }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }
    func sendStopAlarmMessage() {
        guard let session = wcSession, session.activationState == .activated else { return }
        let message = ["action": "stopAlarm"]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }
    
    func sendTriggerAlarmMessage() {
        guard let session = wcSession, session.activationState == .activated else { return }
        let message = ["action": "triggerAlarm"]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
}

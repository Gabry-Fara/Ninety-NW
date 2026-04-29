import Foundation
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine

enum WatchConnectivityState {
    case synced
    case queued
    case watchOnly
}

class WatchSensorManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    private static let pendingScheduleKey = "pendingSmartAlarmSchedule"
    private static let readyScheduleKey = "readySmartAlarmSchedule"
    private static let actualAlarmTimeKey = "actualSmartAlarmTime"
    private let payloadInterval: TimeInterval = 5
    private let motionThreshold = 0.08
    private let maxPendingPayloads = 12_000
    private let backlogReplayBatchSize = 24
    private let minimumBacklogFlushInterval: TimeInterval = 8

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

    private struct PendingPayloadEnvelope: Codable {
        let payload: SensorPayload
        let enqueuedAt: Date
        var lastAttemptAt: Date?
        var deliveryAttempts: Int
        var deferredDeliveryQueued: Bool
    }
    
    static let shared = WatchSensorManager()
    
    @Published var sessionState: String = "Inactive"
    @Published var lastPayloadSent: String = "No data sent yet"
    @Published var connectionStatus: String = "Disconnected"
    @Published var isMocking: Bool = false
    @Published var nextAlarmDate: Date? = nil
    
    private var runtimeSession: WKExtendedRuntimeSession?
    private var suppressNextRuntimeInvalidation = false
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var wcSession: WCSession?
    private var pendingPayloads: [PendingPayloadEnvelope] = []
    private var lastBacklogFlushDate: Date?
    private var pipelineState: WatchPipelineState = .idle
    private var replayStatusText: String = "No backlog activity"
    
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
        setupWatchConnectivity()
        refreshNextAlarmDate()
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
    }

    func retryPendingPayloadDelivery() {
        refreshConnectionStatus()
        flushPendingPayloadsIfNeeded(force: true)
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
        if runtimeSession?.state == .running || runtimeSession?.state == .scheduled {
            suppressNextRuntimeInvalidation = true
            runtimeSession?.invalidate()
        }
        runtimeSession = nil
        clearAlarmTracking()
        stopSensors()
        clearPendingPayloadQueue()
        updatePipelineState(.completed, detail: "Manually Stopped")
        sendWatchStatusUpdate(sessionState)
    }

    func pauseMonitoring() {
        clearAlarmTracking()
        stopSensors()
        clearPendingPayloadQueue()
        updatePipelineState(.completed, detail: "Monitoring Paused After Alarm")
        sendWatchStatusUpdate(sessionState)
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
            
            // Fallback: if the session is expiring (30 mins passed), the alarm time has been reached.
            // We must notify the user to wake them up and prevent the system from reporting a failure.
            extendedRuntimeSession.notifyUser(hapticType: .notification)
            HapticWakeUpManager.shared.startGradualWakeUp()
            self.clearAlarmTracking()
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
        
        // Fallback: If iPhone is disconnected, trigger the alarm locally when the time is reached
        if let alarmDate = nextAlarmDate, Date() >= alarmDate {
            DispatchQueue.main.async {
                print("WATCH: Triggering fallback alarm, target date reached.")
                self.runtimeSession?.notifyUser(hapticType: .notification)
                HapticWakeUpManager.shared.startGradualWakeUp()
                self.clearAlarmTracking()
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
                DispatchQueue.main.async {
                    self.stopSession()
                }
            } else if action == "pauseMonitoring" {
                DispatchQueue.main.async {
                    self.pauseMonitoring()
                }
            } else if action == "hapticWakeUp" {
                DispatchQueue.main.async {
                    print("WATCH: Received hapticWakeUp from iPhone.")
                    self.runtimeSession?.notifyUser(hapticType: .notification)
                    HapticWakeUpManager.shared.startGradualWakeUp()
                    self.clearAlarmTracking()
                }
            } else if action == "syncAlarmState" {
                if let targetInterval = payload["targetDate"] as? TimeInterval {
                    UserDefaults.standard.set(targetInterval, forKey: Self.actualAlarmTimeKey)
                    print("WATCH: Received syncAlarmState for \(Date(timeIntervalSince1970: targetInterval))")
                } else {
                    clearAlarmTracking()
                    print("WATCH: Received syncAlarmState (clear)")
                }
                DispatchQueue.main.async {
                    self.refreshNextAlarmDate()
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
        clearPendingPayloadQueue()
        replayStatusText = "No backlog activity"
        updatePipelineState(.idle)
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
        UserDefaults.standard.removeObject(forKey: Self.pendingScheduleKey)
        UserDefaults.standard.removeObject(forKey: Self.readyScheduleKey)
        UserDefaults.standard.removeObject(forKey: Self.actualAlarmTimeKey)
        if Thread.isMainThread {
            nextAlarmDate = nil
        } else {
            DispatchQueue.main.async {
                self.nextAlarmDate = nil
            }
        }
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
}

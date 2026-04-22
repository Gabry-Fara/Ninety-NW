import Foundation
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine

class WatchSensorManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    private static let pendingScheduleKey = "pendingSmartAlarmSchedule"
    private let payloadInterval: TimeInterval = 5
    private let motionThreshold = 0.08
    
    static let shared = WatchSensorManager()
    
    @Published var sessionState: String = "Inactive"
    @Published var lastPayloadSent: String = "No data sent yet"
    @Published var connectionStatus: String = "Disconnected"
    @Published var isMocking: Bool = false
    
    private var runtimeSession: WKExtendedRuntimeSession?
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var wcSession: WCSession?
    
    private var hrQuery: HKAnchoredObjectQuery?
    private var hrSamplesBuffer: [Double] = []
    private var payloadTimer: AnyCancellable?
    
    // CoreMotion background anchors
    private var motionDeviationSamples: [Double] = []
    private var motionCountBuffer: Double = 0
    private let motionQueue = OperationQueue()
    
    // For Mocking
    private var mockTimer: AnyCancellable?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }

    var hasPendingSchedule: Bool {
        pendingScheduledStartDate != nil
    }

    var pendingScheduleDescription: String? {
        guard let date = pendingScheduledStartDate else { return nil }
        return "Queued for \(date.formatted(date: .omitted, time: .shortened))"
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

        connectionStatus = session.isReachable ? "Phone reachable" : "Phone unavailable, queued delivery"
        sendWatchStatusUpdate(sessionState)
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
                existing.invalidate()
            }
        }

        self.runtimeSession = WKExtendedRuntimeSession()
        self.runtimeSession?.delegate = self
        self.runtimeSession?.start(at: date)
        clearPendingSchedule()
        self.sessionState = "Scheduled for \(date.formatted(date: .omitted, time: .shortened))"
        sendWatchStatusUpdate(self.sessionState)
    }

    func armPendingScheduleIfPossible() {
        guard let date = pendingScheduledStartDate else { return }

        guard WKExtension.shared().applicationState == .active else {
            DispatchQueue.main.async {
                self.sessionState = "Open watch app to arm smart alarm"
            }
            sendWatchStatusUpdate("Watch app must be opened to arm Smart Alarm")
            return
        }

        scheduleSmartAlarmSession(at: date)
    }
    
    func stopSession() {
        if runtimeSession?.state == .running || runtimeSession?.state == .scheduled {
            runtimeSession?.invalidate()
        }
        runtimeSession = nil
        clearPendingSchedule()
        stopSensors()
        sessionState = "Manually Stopped"
        sendWatchStatusUpdate(sessionState)
    }

    func pauseMonitoring() {
        clearPendingSchedule()
        stopSensors()
        sessionState = "Monitoring Paused After Alarm"
        sendWatchStatusUpdate(sessionState)
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.sessionState = "Session Started"
            self.startSensors()
            self.sendWatchStatusUpdate(self.sessionState)
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.sessionState = "Session Expiring Soon"
            self.sendWatchStatusUpdate(self.sessionState)
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        DispatchQueue.main.async {
            if
                let nsError = error as NSError?,
                nsError.domain == WKExtendedRuntimeSessionErrorDomain,
                let wkErrorCode = WKExtendedRuntimeSessionErrorCode(rawValue: nsError.code)
            {
                switch wkErrorCode {
                case .scheduledTooFarInAdvance:
                    self.sessionState = "Error: Scheduled >36h ahead"
                case .mustBeActiveToStartOrSchedule:
                    self.sessionState = "Error: Must be in foreground"
                default:
                    self.sessionState = "Invalidated: \(wkErrorCode.rawValue)"
                }
            } else {
                self.sessionState = "Session Invalidated"
            }
            self.sendWatchStatusUpdate(self.sessionState)
            self.stopSensors()
        }
    }
    
    // MARK: - Sensor Acquisition
    
    private func startSensors() {
        #if targetEnvironment(simulator)
        startMockDataStream()
        #else
        startRealSensors()
        #endif
    }
    
    private func stopSensors() {
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
    }
    
    private func transmit(payload: SensorPayload) {
        guard let session = wcSession else { return }

        if let encoded = try? JSONEncoder().encode(payload) {
            let dict: [String: Any] = ["payloadData": encoded]
            session.transferUserInfo(dict)

            if session.isReachable {
                session.sendMessage(dict, replyHandler: nil) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.connectionStatus = "Send failed: \(error.localizedDescription)"
                    }
                }
                DispatchQueue.main.async {
                    self.connectionStatus = "Phone reachable"
                }
            } else {
                DispatchQueue.main.async {
                    self.connectionStatus = "Phone unavailable, queued delivery"
                }
            }

            DispatchQueue.main.async {
                self.lastPayloadSent = "Sent at \(payload.timestamp.formatted(date: .omitted, time: .standard)), HR count: \(payload.hrSamples.count)"
            }
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
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.refreshConnectionStatus()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingCommand(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        processIncomingCommand(userInfo)
    }
    
    private func processIncomingCommand(_ payload: [String: Any]) {
        if let action = payload["action"] as? String {
            if action == "startSession" {
                if let targetInterval = payload["targetDate"] as? TimeInterval {
                    // Start exactly 30 minutes before the target alarm date
                    var wakeWindowStartDate = Date(timeIntervalSince1970: targetInterval).addingTimeInterval(-30 * 60)
                    // Ensure the date is never in the past, which would crash WKExtendedRuntimeSession
                    if wakeWindowStartDate <= Date() {
                        wakeWindowStartDate = Date().addingTimeInterval(2) // start practically immediately
                    }
                    DispatchQueue.main.async {
                        self.queueOrScheduleSmartAlarmSession(at: wakeWindowStartDate)
                    }
                } else {
                    // Fallback to instant mock start
                    DispatchQueue.main.async {
                        self.queueOrScheduleSmartAlarmSession(at: Date().addingTimeInterval(5))
                    }
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
                    HapticWakeUpManager.shared.startGradualWakeUp()
                }
            }
        }
    }

    private var pendingScheduledStartDate: Date? {
        let interval = UserDefaults.standard.object(forKey: Self.pendingScheduleKey) as? TimeInterval
        return interval.map(Date.init(timeIntervalSince1970:))
    }

    private func queueOrScheduleSmartAlarmSession(at date: Date) {
        guard WKExtension.shared().applicationState == .active else {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.pendingScheduleKey)
            sessionState = "Queued. Open watch app to arm session"
            sendWatchStatusUpdate("Queued on watch. Open the watch app to arm Smart Alarm.")
            return
        }

        scheduleSmartAlarmSession(at: date)
    }

    private func clearPendingSchedule() {
        UserDefaults.standard.removeObject(forKey: Self.pendingScheduleKey)
    }

    private func sendWatchStatusUpdate(_ status: String) {
        guard let session = wcSession, session.activationState == .activated else { return }

        var message: [String: Any] = [
            "watchStatus": status,
            "watchConnectionStatus": connectionStatus
        ]
        
        if let queuedSchedule = pendingScheduledStartDate?.timeIntervalSince1970 {
            message["queuedSchedule"] = queuedSchedule
        }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }
}

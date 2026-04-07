import Foundation
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine

class WatchSensorManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    
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
    
    private var dataTimer: Timer?
    
    // For Mocking
    private var mockTimer: Timer?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }
    
    func requestHealthPermissions(completion: @escaping (Bool) -> Void) {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: nil, read: [hrType]) { success, _ in
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
        
        self.runtimeSession = WKExtendedRuntimeSession()
        self.runtimeSession?.delegate = self
        self.runtimeSession?.start(at: date)
        self.sessionState = "Scheduled for \(date.formatted(date: .omitted, time: .shortened))"
    }
    
    func stopSession() {
        runtimeSession?.invalidate()
        runtimeSession = nil
        stopSensors()
        sessionState = "Manually Stopped"
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.sessionState = "Session Started"
            self.startSensors()
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        DispatchQueue.main.async {
            self.sessionState = "Session Expiring Soon"
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        DispatchQueue.main.async {
            self.sessionState = "Session Invalidated"
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
        dataTimer?.invalidate()
        dataTimer = nil
        mockTimer?.invalidate()
        mockTimer = nil
    }
    
    private func startRealSensors() {
        // Start Accelerometer
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50 Hz
            motionManager.startAccelerometerUpdates()
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
        
        // Batch and send every 5 seconds
        dataTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.compileAndTransmitPayload()
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
        // Calculate accelerometer variance
        var variance = 0.0
        if let motionData = motionManager.accelerometerData {
            // Simplified dynamic variance metric based on magnitude
            let magnitude = sqrt(pow(motionData.acceleration.x, 2) + pow(motionData.acceleration.y, 2) + pow(motionData.acceleration.z, 2))
            // Typically you would store the past 5s of data to calculate rolling variance.
            // For architecture implementation proof, we capture current reading deviation from 1G gravity.
            variance = abs(magnitude - 1.0)
        }
        
        let payload = SensorPayload(
            timestamp: Date(),
            hrSamples: hrSamplesBuffer,
            accelerometerVariance: variance,
            isMockData: false
        )
        
        hrSamplesBuffer.removeAll() // Clear buffer after sending
        
        transmit(payload: payload)
    }
    
    private func transmit(payload: SensorPayload) {
        guard let session = wcSession else { return }
        
        if session.activationState != .activated {
            DispatchQueue.main.async {
                self.connectionStatus = "Session not activated"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.connectionStatus = "Reachable"
        }
        
        if let encoded = try? JSONEncoder().encode(payload),
           let dict = try? JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any] {
            
            session.sendMessage(dict, replyHandler: nil) { [weak self] error in
                DispatchQueue.main.async {
                    self?.connectionStatus = "Send failed: \(error.localizedDescription)"
                }
            }
            
            DispatchQueue.main.async {
                self.lastPayloadSent = "Sent at \(payload.timestamp.formatted(date: .omitted, time: .standard)), HR count: \(payload.hrSamples.count)"
            }
        }
    }
    
    // MARK: - Mocking Data
    
    private func startMockDataStream() {
        // Simulating 5 second batches of mock transitions
        mockTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            let mockPayload = SensorPayload(
                timestamp: Date(),
                hrSamples: [Double.random(in: 55...65), Double.random(in: 50...60)],
                accelerometerVariance: Double.random(in: 0.0...0.5),
                isMockData: true
            )
            self?.transmit(payload: mockPayload)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = activationState == .activated ? "Activated" : "Not Activated"
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingCommand(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        processIncomingCommand(userInfo)
    }
    
    private func processIncomingCommand(_ payload: [String: Any]) {
        if let action = payload["action"] as? String, action == "startSession" {
            DispatchQueue.main.async {
                // start in 5 seconds
                self.scheduleSmartAlarmSession(at: Date().addingTimeInterval(5))
            }
        }
    }
}

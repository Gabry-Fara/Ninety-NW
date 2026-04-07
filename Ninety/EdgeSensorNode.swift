import Foundation

#if os(watchOS)
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity

class EdgeSensorNode: NSObject, WCSessionDelegate, WKExtendedRuntimeSessionDelegate {
    
    static let shared = EdgeSensorNode()
    
    private var runtimeSession: WKExtendedRuntimeSession?
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    
    private var hrQuery: HKAnchoredObjectQuery?
    private var currentHR: [Double] = []
    private var hrAnchor: HKQueryAnchor?
    
    private var motionTimer: Timer?
    private var transmissionTimer: Timer?
    private var varianceData: [Double] = []
    
    override private init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    /// Phase 1: Schedule the watch to wake up in background 30 mins before limit
    func scheduleSmartAlarmSession(wakeWindowStartDate: Date) {
        // Avvio esplicito della sessione con tipo .smartAlarm
        self.runtimeSession = WKExtendedRuntimeSession() 
        // Nota: Nel target iOS 26 ipotetico, usare WKExtendedRuntimeSession(sessionType: .smartAlarm) o impostarlo qua
        self.runtimeSession?.delegate = self
        self.runtimeSession?.start(at: wakeWindowStartDate)
        print("Smart Alarm Session scheduled to start at \(wakeWindowStartDate)")
    }
    
    func sessionDidStart(_ session: WKExtendedRuntimeSession) {
        startSensorCollection()
        startTransmissionPipeline()
    }
    
    func sessionWillExpire(_ session: WKExtendedRuntimeSession) {
        stopSensorCollection()
    }
    
    func session(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        stopSensorCollection()
    }
    
    private func startSensorCollection() {
        currentHR = []
        varianceData = []
        
        // 1. Heart Rate
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        hrQuery = HKAnchoredObjectQuery(type: hrType, predicate: nil, anchor: hrAnchor, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deleted, newAnchor, error in
            self?.processHRSamples(samples)
            self?.hrAnchor = newAnchor
        }
        
        hrQuery!.updateHandler = { [weak self] query, samples, deleted, newAnchor, error in
            self?.processHRSamples(samples)
            self?.hrAnchor = newAnchor
        }
        
        healthStore.execute(hrQuery!)
        
        // 2. Accelerometer (Motion)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.5
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                // Calculate simple variance proxy from raw Gs
                let acceleration = data.acceleration
                let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                self?.varianceData.append(magnitude)
            }
        }
    }
    
    private func processHRSamples(_ samples: [HKSample]?) {
        guard let countSamples = samples as? [HKQuantitySample] else { return }
        let hrUnit = HKUnit(from: "count/min")
        let rates = countSamples.map { $0.quantity.doubleValue(for: hrUnit) }
        
        DispatchQueue.main.async {
            self.currentHR.append(contentsOf: rates)
        }
    }
    
    private func stopSensorCollection() {
        if let query = hrQuery {
            healthStore.stop(query)
        }
        motionManager.stopAccelerometerUpdates()
        transmissionTimer?.invalidate()
    }
    
    /// Phase 2: Transmission Pipeline (5-10s interval, direct sendMessage)
    private func startTransmissionPipeline() {
        transmissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.transmitDataPacket()
        }
    }
    
    private func transmitDataPacket() {
        guard WCSession.default.isReachable else { return }
        
        // Calculate accelerometer variance from the collected magnitude array over the last 5s
        let variance: Double
        if varianceData.isEmpty {
            variance = 0.0
        } else {
            let mean = varianceData.reduce(0, +) / Double(varianceData.count)
            variance = varianceData.map { pow($0 - mean, 2) }.reduce(0, +) / Double(varianceData.count)
        }
        
        // Create the packet
        let payload: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "hrSamples": currentHR,
            "accelerometerVariance": variance,
            "isMockData": false
        ]
        
        // Clear buffers for next batch
        currentHR.removeAll()
        varianceData.removeAll()
        
        // Exclusively using sendMessage, no transferUserInfo for crucial latency elimination
        WCSession.default.sendMessage(payload, replyHandler: nil) { error in
            print("Delivery failed: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
#endif

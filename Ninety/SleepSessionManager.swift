import Foundation
import UIKit
import WatchConnectivity
import Combine

class SleepSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SleepSessionManager()
    private let maxTrackedPayloadIDs = 200
    
    @Published var lastPayloadReceived: String = "No data received"
    @Published var watchStatus: String = "No watch session activity"
    @Published var watchConnectionStatus: String = "No connectivity status"
    @Published var engineLog: String = "Idle"
    @Published var logs: [String] = []
    
    private var wcSession: WCSession?
    private var currentBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var recentPayloadIDs: [UUID] = []
    
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
        
        // Before starting a new one, store the old one so we can end it
        let previousTask = currentBackgroundTask
        
        // Request a new task to daisy-chain the background execution limit
        currentBackgroundTask = application.beginBackgroundTask(withName: "SleepProcessing") {
            // Expiration handler called by the OS if time runs out
            application.endBackgroundTask(self.currentBackgroundTask)
            self.currentBackgroundTask = .invalid
            self.log("⚠️ Background Task Expired")
        }
        
        // End the previous task now that we have successfully requested a new one
        if previousTask != .invalid {
            application.endBackgroundTask(previousTask)
        }
        
        log("🔄 Background Task Renewed")
    }
    
    func startWatchSession(targetDate: Date? = nil) {
        guard let session = wcSession else { return }
        
        var command: [String: Any] = ["action": "startSession"]
        if let targetDate = targetDate {
            command["targetDate"] = targetDate.timeIntervalSince1970
        }
        
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil) { error in
                self.log("Failed to start via sendMessage: \(error.localizedDescription)")
            }
            log("Direct session request sent to Watch.")
        } else {
            session.transferUserInfo(command)
            log("Watch unreachable. Request queued (Will fire when Watch wakes).")
        }
    }
    
    func stopWatchSession() {
        guard let session = wcSession else { return }
        let command = ["action": "stopSession"]
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(command)
        }
    }

    func pauseWatchMonitoring() {
        guard let session = wcSession else { return }
        let command = ["action": "pauseMonitoring"]
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(command)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        log("WCSession Activated: \(activationState == .activated)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        wcSession?.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingPayload(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingPayload(userInfo)
    }

    private func handleIncomingPayload(_ payloadDictionary: [String: Any]) {
        if handleWatchStatus(payloadDictionary) {
            return
        }

        // Immediately request extended background time
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
            
            // Pass payload to heuristic engine
            SleepHeuristicEngine.shared.processIncomingPayload(payload)
            
        } catch {
            log("❌ Decode Error: \(error.localizedDescription)")
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

        log("⌚️ \(status)")
        return true
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
}

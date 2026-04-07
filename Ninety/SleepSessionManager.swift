import Foundation
import UIKit
import WatchConnectivity
import Combine

class SleepSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SleepSessionManager()
    
    @Published var lastPayloadReceived: String = "No data received"
    @Published var engineLog: String = "Idle"
    @Published var logs: [String] = []
    
    private var wcSession: WCSession?
    private var currentBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    
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
    
    func startWatchSession() {
        guard let session = wcSession else { return }
        
        let command = ["action": "startSession"]
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
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        log("WCSession Activated: \(activationState == .activated)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        wcSession?.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Immediately request extended background time
        extendBackgroundTask()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            let payload = try JSONDecoder().decode(SensorPayload.self, from: data)
            
            DispatchQueue.main.async {
                self.lastPayloadReceived = "Received at \(payload.timestamp.formatted(date: .omitted, time: .standard))"
            }
            
            // Pass payload to heuristic engine
            SleepHeuristicEngine.shared.processIncomingPayload(payload)
            
        } catch {
            log("❌ Decode Error: \(error.localizedDescription)")
        }
    }
}

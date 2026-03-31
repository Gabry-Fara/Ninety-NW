import Foundation
import MultipeerConnectivity
import Combine
import UIKit

/// Base class that holds common Multipeer connectivity configuration and properties.
public class MultipeerManager: NSObject, ObservableObject {
    public let serviceType = "rps-ninety"
    public let myPeerID: MCPeerID
    public let session: MCSession
    
    // Publishers for Combine
    public let receivedPacketSubject = PassthroughSubject<(GamePacket, MCPeerID), Never>()
    
    public override init() {
        // Retrieve or generate MCPeerID from UserDefaults
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "peerID"),
           let savedPeerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           savedPeerID.displayName.contains("#") {
            self.myPeerID = savedPeerID
        } else {
            let code = String(format: "%04d", Int.random(in: 0...9999))
            let deviceName = "\(UIDevice.current.name) #\(code)"
            
            let newPeerID = MCPeerID(displayName: deviceName)
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newPeerID, requiringSecureCoding: true) {
                defaults.set(data, forKey: "peerID")
            }
            self.myPeerID = newPeerID
        }
        
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        self.session.delegate = self
    }
    
    /// Sends a GamePacket to specified peers connected to the session
    public func send(packet: GamePacket, to peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(packet)
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("[MultipeerManager] Failed to send packet \(packet): \(error.localizedDescription)")
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let stateString: String
        switch state {
        case .connected: stateString = "Connected"
        case .connecting: stateString = "Connecting"
        case .notConnected: stateString = "Not Connected"
        @unknown default: stateString = "Unknown"
        }
        print("[MultipeerManager] Peer \(peerID.displayName) changed state to \(stateString)")
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let packet = try JSONDecoder().decode(GamePacket.self, from: data)
            DispatchQueue.main.async {
                self.receivedPacketSubject.send((packet, peerID))
            }
        } catch {
            print("[MultipeerManager] Failed to decode packet from \(peerID.displayName): \(error.localizedDescription)")
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

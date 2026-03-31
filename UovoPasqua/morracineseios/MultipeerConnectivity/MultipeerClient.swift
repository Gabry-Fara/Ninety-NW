import Foundation
import MultipeerConnectivity
import Combine

public class MultipeerClient: MultipeerManager, MCNearbyServiceBrowserDelegate {
    
    private var browser: MCNearbyServiceBrowser
    
    // Published State for the UI
    @Published public var isConnected = false
    @Published public var lobbyStatusCount: Int = 0
    @Published public var opponentName: String?
    @Published public var lastResult: (RoundResult, Move)?
    @Published public var madeMove: Move?
    
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        self.browser = MCNearbyServiceBrowser(peer: MCPeerID(displayName: "temp"), serviceType: "temp-service")
        super.init()
        
        self.browser = MCNearbyServiceBrowser(peer: self.myPeerID, serviceType: self.serviceType)
        self.browser.delegate = self
        
        setupSubscriptions()
    }
    
    public func startBrowsing() {
        browser.startBrowsingForPeers()
        print("[MultipeerClient] Browsing started as \(myPeerID.displayName)")
    }
    
    public func stopBrowsing() {
        browser.stopBrowsingForPeers()
        print("[MultipeerClient] Browsing stopped")
    }
    
    private func setupSubscriptions() {
        receivedPacketSubject
            .sink { [weak self] (packet, peerID) in
                self?.handlePacket(packet, from: peerID)
            }
            .store(in: &cancellables)
    }
    
    private func handlePacket(_ packet: GamePacket, from peerID: MCPeerID) {
        switch packet {
        case .lobbyStatus(let count):
            self.lobbyStatusCount = count
        case .matchStarted(let opponent):
            self.opponentName = opponent
            self.lastResult = nil
            self.madeMove = nil
        case .gameResult(let result, let opponentMove):
            self.lastResult = (result, opponentMove)
            self.madeMove = nil
        default:
            break
        }
    }
    
    public func sendMove(_ move: Move) {
        self.madeMove = move
        // Send to all connected peers (which should just be the Hub / Apple TV)
        send(packet: .makeMove(choice: move), to: session.connectedPeers)
    }
    
    // MARK: - Overrides
    public override func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        super.session(session, peer: peerID, didChange: state)
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.stopBrowsing() // Standard practice: stop browsing once connected to the host
            case .notConnected:
                self.isConnected = false
                self.opponentName = nil
                self.lobbyStatusCount = 0
                self.startBrowsing() // Resume looking for the host
            default:
                break
            }
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("[MultipeerClient] Found Host: \(peerID.displayName). Sending invite.")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[MultipeerClient] Lost Host: \(peerID.displayName)")
    }
}

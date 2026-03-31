import Foundation
import MultipeerConnectivity
import Combine

public class MultipeerServer: MultipeerManager, MCNearbyServiceAdvertiserDelegate {
    
    private var advertiser: MCNearbyServiceAdvertiser
    
    @Published public private(set) var connectedPeers: [MCPeerID] = []
    
    // Game Management
    private var activePairs: [MCPeerID: MCPeerID] = [:]
    private var pendingMoves: [MCPeerID: Move] = [:] // Store moves waiting for an opponent's move
    @Published public private(set) var pendingPeers: [MCPeerID] = []
    private var invitationHandlers: [MCPeerID: (Bool, MCSession?) -> Void] = [:]
    
    // Match State Tracking
    @Published public private(set) var playerScores: [MCPeerID: Int] = [:]
    @Published public private(set) var matchLogs: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        self.advertiser = MCNearbyServiceAdvertiser(peer: MCPeerID(displayName: "temp"), discoveryInfo: nil, serviceType: "temp-service")
        super.init()
        
        // Re-initialize advertiser with the initialized peerID from the superclass
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.myPeerID, discoveryInfo: nil, serviceType: self.serviceType)
        self.advertiser.delegate = self
        
        self.setupSubscriptions()
    }
    
    public func startAdvertising() {
        advertiser.startAdvertisingPeer()
        print("[MultipeerServer] Advertising started as \(myPeerID.displayName)")
    }
    
    public func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        print("[MultipeerServer] Advertising stopped")
    }
    
    private func setupSubscriptions() {
        receivedPacketSubject
            .sink { [weak self] (packet, peerID) in
                self?.handleReceivedPacket(packet, from: peerID)
            }
            .store(in: &cancellables)
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[MultipeerServer] Received invitation from \(peerID.displayName)")
        DispatchQueue.main.async {
            // Aggressively remove ghost devices with the same name from previous sessions
            self.pendingPeers.removeAll { $0.displayName == peerID.displayName && $0 != peerID }
            self.connectedPeers.removeAll { $0.displayName == peerID.displayName && $0 != peerID }
            // Clean up any paired ghosts
            if let ghost = self.activePairs.keys.first(where: { $0.displayName == peerID.displayName && $0 != peerID }) {
                self.handleDisconnection(of: ghost)
            }
            
            if !self.pendingPeers.contains(peerID) {
                self.pendingPeers.append(peerID)
            }
            self.invitationHandlers[peerID] = invitationHandler
        }
    }
    
    // MARK: - Peer Approval Logic
    public func acceptPeer(_ peerID: MCPeerID) {
        guard let handler = invitationHandlers[peerID] else { return }
        handler(true, session)
        
        DispatchQueue.main.async {
            self.invitationHandlers[peerID] = nil
            self.pendingPeers.removeAll { $0 == peerID }
        }
    }
    
    public func declinePeer(_ peerID: MCPeerID) {
        guard let handler = invitationHandlers[peerID] else { return }
        handler(false, nil)
        
        DispatchQueue.main.async {
            self.invitationHandlers[peerID] = nil
            self.pendingPeers.removeAll { $0 == peerID }
        }
    }
    
    // MARK: - Overrides
    public override func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        super.session(session, peer: peerID, didChange: state)
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.broadcastLobbyStatus()
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.handleDisconnection(of: peerID)
                self.broadcastLobbyStatus()
            default:
                break
            }
        }
    }
    
    // MARK: - Game Logic
    private func handleReceivedPacket(_ packet: GamePacket, from peerID: MCPeerID) {
        switch packet {
        case .makeMove(let choice):
            handleMove(choice, from: peerID)
        default:
            // The server generally receives moves from the client, other packets are ignored
            break
        }
    }
    
    private func handleMove(_ move: Move, from peerID: MCPeerID) {
        guard let opponentID = activePairs[peerID] else {
            print("[MultipeerServer] Received move from unpaired peer: \(peerID.displayName)")
            return
        }
        
        pendingMoves[peerID] = move
        
        if let opponentMove = pendingMoves[opponentID] {
            // Both players made their moves
            resolveRound(playerA: peerID, moveA: move, playerB: opponentID, moveB: opponentMove)
            pendingMoves[peerID] = nil
            pendingMoves[opponentID] = nil
        }
    }
    
    private func resolveRound(playerA: MCPeerID, moveA: Move, playerB: MCPeerID, moveB: Move) {
        let resultA = getResult(for: moveA, against: moveB)
        let resultB = getResult(for: moveB, against: moveA)
        
        let logText: String
        if resultA == .draw {
            logText = "Draw! Both played \(moveA)."
        } else if resultA == .win {
            logText = "\(playerA.displayName) wins round with \(moveA) over \(moveB)!"
        } else {
            logText = "\(playerB.displayName) wins round with \(moveB) over \(moveA)!"
        }
        
        DispatchQueue.main.async {
            if resultA == .win { self.playerScores[playerA, default: 0] += 1 }
            if resultB == .win { self.playerScores[playerB, default: 0] += 1 }
            self.matchLogs.insert(logText, at: 0)
        }
        
        send(packet: .gameResult(result: resultA, opponentMove: moveB), to: [playerA])
        send(packet: .gameResult(result: resultB, opponentMove: moveA), to: [playerB])
    }
    
    private func getResult(for move1: Move, against move2: Move) -> RoundResult {
        if move1 == move2 { return .draw }
        switch (move1, move2) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
            return .win
        default:
            return .lose
        }
    }
    
    private func broadcastLobbyStatus() {
        let packet = GamePacket.lobbyStatus(playerCount: connectedPeers.count)
        send(packet: packet, to: connectedPeers)
    }
    
    /// Starts a specific match explicitly between two peers
    public func startMatch(player1: MCPeerID, player2: MCPeerID) {
        // Register pair in dictionary (bidirectional lookup)
        activePairs[player1] = player2
        activePairs[player2] = player1
        
        DispatchQueue.main.async {
            self.playerScores[player1] = 0
            self.playerScores[player2] = 0
            self.matchLogs = ["Match started between \(player1.displayName) and \(player2.displayName)!"]
        }
        
        // Notify both players
        send(packet: .matchStarted(opponentName: player2.displayName), to: [player1])
        send(packet: .matchStarted(opponentName: player1.displayName), to: [player2])
        
        print("[MultipeerServer] Paired \(player1.displayName) and \(player2.displayName) for a match!")
    }
    
    private func handleDisconnection(of peerID: MCPeerID) {
        if let opponentID = activePairs[peerID] {
            // Unpair
            activePairs[peerID] = nil
            activePairs[opponentID] = nil
            pendingMoves[peerID] = nil
            pendingMoves[opponentID] = nil
            
            print("[MultipeerServer] Player disconnected, match aborted.")
        }
    }
}

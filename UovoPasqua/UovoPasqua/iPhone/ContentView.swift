//
//  ContentView.swift
//  morracineseios
//
//  Created by marco on 31/03/26.
//

import SwiftUI
import Combine
import MultipeerConnectivity


struct ContentView: View {
    @StateObject var mpc = MultipeerManager()
    
    var body: some View {
        VStack {
            #if os(tvOS)
            HostView(mpc: mpc)
            #else
            ClientView(mpc: mpc)
            #endif
        }
    }
}

struct HostView: View {
    @ObservedObject var mpc: MultipeerManager
    @State var selectedPeers = Set<MCPeerID>()
    
    var body: some View {
        VStack {
            Text("Apple TV - Host").font(.largeTitle)
            List(mpc.connectedPeers, id: \.self) { peer in
                HStack {
                    Text(peer.displayName)
                    Spacer()
                    if selectedPeers.contains(peer) {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedPeers.contains(peer) {
                        selectedPeers.remove(peer)
                    } else if selectedPeers.count < 2 {
                        selectedPeers.insert(peer)
                    }
                }
            }
            if selectedPeers.count == 2 {
                Button("Start Turn") {
                    for p in selectedPeers {
                        mpc.requestMove(from: p, duration: 10)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            Text(mpc.lastResultText).font(.headline).padding()
        }
        .onAppear {
            mpc.startHosting()
        }
    }
}

struct ClientView: View {
    @ObservedObject var mpc: MultipeerManager
    
    var body: some View {
        VStack(spacing: 40) {
            Text("iPhone - Player").font(.largeTitle)
            Text(mpc.lastResultText)
            
            if mpc.requestedMove {
                Text("Your Turn! Time: \(mpc.timeRemaining)")
                    .font(.title)
                    .foregroundColor(.red)
                
                HStack(spacing: 20) {
                    MoveButton(title: "Rock", mpc: mpc, move: .rock)
                    MoveButton(title: "Paper", mpc: mpc, move: .paper)
                    MoveButton(title: "Scissors", mpc: mpc, move: .scissors)
                }
            } else {
                Text("Waiting for turn...")
            }
            
            Spacer()
        }
        .onAppear {
            mpc.startClient()
        }
    }
}

struct MoveButton: View {
    let title: String
    let mpc: MultipeerManager
    let move: Move
    
    var body: some View {
        Button(title) {
            mpc.sendMove(move)
        }
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}




enum Move: String, Codable {
    case rock, paper, scissors
}

struct GameMessage: Codable {
    enum MessageType: String, Codable {
        case requestMove
        case submitMove
        case result
    }
    
    let type: MessageType
    var move: Move?
    var duration: Int?
    var winner: Bool?
}

class MultipeerManager: NSObject, ObservableObject {
    private let serviceType = "morra-game"
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isHosting = false
    @Published var requestedMove = false
    @Published var timeRemaining = 0
    @Published var opponentMoveReceived = false
    @Published var lastResultText = ""
    
    // As Host we keep track of moves
    var receivedMoves: [MCPeerID: Move] = [:]
    
    var myPeerID: MCPeerID!
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    
    override init() {
        super.init()
        #if os(tvOS)
        myPeerID = MCPeerID(displayName: "Apple TV (Host)")
        #else
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        #endif
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func startHosting() {
        isHosting = true
        browser.startBrowsingForPeers()
    }
    
    func startClient() {
        isHosting = false
        advertiser.startAdvertisingPeer()
    }
    
    // Host requests a move from specific peers
    func requestMove(from peer: MCPeerID, duration: Int = 10) {
        let msg = GameMessage(type: .requestMove, duration: duration)
        send(msg: msg, to: [peer])
    }
    
    func sendMove(_ move: Move) {
        if let host = connectedPeers.first {
            let msg = GameMessage(type: .submitMove, move: move)
            send(msg: msg, to: [host])
            requestedMove = false
        }
    }
    
    private func send(msg: GameMessage, to peers: [MCPeerID]) {
        guard let data = try? JSONEncoder().encode(msg) else { return }
        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("Error sending: \(error)")
        }
    }
    
    func resolveMatch() {
        // Simple logic for host to resolve game if 2 peers responded
        guard receivedMoves.count == 2 else { return }
        let peers = Array(receivedMoves.keys)
        let p1 = peers[0]
        let p2 = peers[1]
        let m1 = receivedMoves[p1]!
        let m2 = receivedMoves[p2]!
        
        var w1 = false
        var w2 = false
        
        if m1 == m2 {
            // Draw
        } else if (m1 == .rock && m2 == .scissors) || (m1 == .scissors && m2 == .paper) || (m1 == .paper && m2 == .rock) {
            w1 = true
        } else {
            w2 = true
        }
        
        send(msg: GameMessage(type: .result, winner: w1), to: [p1])
        send(msg: GameMessage(type: .result, winner: w2), to: [p2])
        
        DispatchQueue.main.async {
            self.lastResultText = "Match resolved! \(p1.displayName):\(m1.rawValue) vs \(p2.displayName):\(m2.rawValue). Winner: \(w1 ? p1.displayName : (w2 ? p2.displayName : "Draw"))"
            self.receivedMoves.removeAll()
        }
    }
    
    private func startTimer(seconds: Int) {
        timeRemaining = seconds
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                timer.invalidate()
                if self.requestedMove {
                    self.requestedMove = false
                }
            }
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
            default: break
            }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let msg = try? JSONDecoder().decode(GameMessage.self, from: data) {
            DispatchQueue.main.async {
                switch msg.type {
                case .requestMove:
                    self.requestedMove = true
                    self.lastResultText = ""
                    if let d = msg.duration {
                        self.startTimer(seconds: d)
                    }
                case .submitMove:
                    if self.isHosting, let m = msg.move {
                        self.receivedMoves[peerID] = m
                        if self.receivedMoves.count == 2 {
                            self.resolveMatch()
                        }
                    }
                case .result:
                    if let winner = msg.winner {
                        self.lastResultText = winner ? "You won!" : "You lost!"
                    } else {
                        self.lastResultText = "Draw!"
                    }
                }
            }
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

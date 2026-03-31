import SwiftUI
import MultipeerConnectivity

struct OldHomeView: View {
    @EnvironmentObject var server: MultipeerServer
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 40) {
                // Header Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Game Lobby")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Advertising as: **\(server.myPeerID.displayName)**")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
                
                HStack(alignment: .top, spacing: 60) {
                    // Left Column: Pending Approvals
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Pending Approvals (\(server.pendingPeers.count))")
                            .font(.headline)
                        
                        if server.pendingPeers.isEmpty {
                            Text("No pending devices.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(server.pendingPeers, id: \.self) { peer in
                                HStack {
                                    Text(peer.displayName)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Button("Accept") {
                                        server.acceptPeer(peer)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    
                                    Button("Decline") {
                                        server.declinePeer(peer)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right Column: Connected Players
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Connected Players (\(server.connectedPeers.count))")
                            .font(.headline)
                        
                        if server.connectedPeers.isEmpty {
                            Text("Waiting for players to join...")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(server.connectedPeers, id: \.self) { peer in
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text(peer.displayName)
                                        .font(.body)
                                    Spacer()
                                    Text("Connected")
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.1).ignoresSafeArea())
        }
    }
}

#Preview {
    OldHomeView()
        .environmentObject(MultipeerServer())
}

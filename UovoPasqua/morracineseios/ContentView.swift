import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var client = MultipeerClient()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("iPhone Player")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Playing as: **\(client.myPeerID.displayName)**")
                        .foregroundStyle(.secondary)
                }
                
                if !client.isConnected {
                    // Searching / Pending State
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                        
                        Text("Looking for Apple TV or waiting for approval...")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
                    
                } else if let opponent = client.opponentName {
                    // Match State
                    VStack(spacing: 20) {
                        Text("Match against:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(opponent)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        
                        if let lastResult = client.lastResult {
                            VStack(spacing: 8) {
                                Text(resultText(for: lastResult.0))
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundStyle(resultColor(for: lastResult.0))
                                
                                Text("\(opponent) played \(lastResult.1.rawValue.capitalized)")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Text(client.madeMove != nil ? "Waiting for opponent..." : "Choose your move:")
                            .font(.headline)
                            .padding(.top)
                        
                        HStack(spacing: 20) {
                            moveButton(.rock, icon: "circle.fill")
                            moveButton(.paper, icon: "doc.fill")
                            moveButton(.scissors, icon: "scissors")
                        }
                        .disabled(client.madeMove != nil)
                    }
                    .padding()
                    
                } else {
                    // Connected but in Lobby
                    VStack {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                            .padding(.bottom)
                        
                        Text("Connected to Lobby!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(client.lobbyStatusCount) players currently online")
                            .foregroundStyle(.secondary)
                        
                        Text("Waiting to be paired for a match...")
                            .padding(.top, 40)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                client.startBrowsing()
            }
        }
    }
    
    @ViewBuilder
    private func moveButton(_ move: Move, icon: String) -> some View {
        Button {
            client.sendMove(move)
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(move.rawValue.capitalized)
                    .font(.headline)
            }
            .frame(width: 80, height: 80)
            .background(client.madeMove == move ? Color.blue : Color.secondary.opacity(0.2))
            .foregroundColor(client.madeMove == move ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private func resultText(for result: RoundResult) -> String {
        switch result {
        case .win: return "YOU WON!"
        case .lose: return "YOU LOST!"
        case .draw: return "DRAW!"
        }
    }
    
    private func resultColor(for result: RoundResult) -> Color {
        switch result {
        case .win: return .green
        case .lose: return .red
        case .draw: return .orange
        }
    }
}

#Preview {
    ContentView()
}

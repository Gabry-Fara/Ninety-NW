import SwiftUI

@main
struct UovoPasquaApp: App {
    @StateObject private var multipeerServer = MultipeerServer()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(multipeerServer)
                .onAppear {
                    multipeerServer.startAdvertising()
                }
        }
    }
}

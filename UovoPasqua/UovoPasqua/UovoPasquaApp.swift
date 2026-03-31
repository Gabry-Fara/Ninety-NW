import SwiftUI

@main
struct UovoPasquaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
        }
    }
}

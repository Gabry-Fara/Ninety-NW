import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            NewGameView()
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}

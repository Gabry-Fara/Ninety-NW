import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: AppTab.home.symbolName, value: AppTab.home) {
                HomeView()
            }
            Tab("Stile", systemImage: AppTab.style.symbolName, value: AppTab.style) {
                StyleView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}

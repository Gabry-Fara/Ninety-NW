import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: AppTab.home.symbolName, value: AppTab.home) {
                HomeView()
            }
            Tab("Catalog", systemImage: AppTab.catalog.symbolName, value: AppTab.catalog) {
                CatalogView()
            }
            Tab("Search", systemImage: AppTab.search.symbolName, value: AppTab.search) {
                SearchView()
            }
            Tab("Library", systemImage: AppTab.library.symbolName, value: AppTab.library) {
                LibraryView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}

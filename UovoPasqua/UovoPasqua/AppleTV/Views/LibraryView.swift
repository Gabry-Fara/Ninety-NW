import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var appState

    private let continueWatching = SampleDataProvider.continueWatchingShelf
    private let recommended      = SampleDataProvider.recommendedShelf

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXL) {

                    // watchlist — empty state if nothing added
                    watchlistSection

                    // continue watching
                    if !continueWatching.items.isEmpty {
                        ShelfSectionView(
                            section: continueWatching,
                            items: continueWatching.items,
                            card: { LockupCardView(item: $0) },
                            destination: { DetailView(item: $0) }
                        )
                    }

                    // static recommended shelf for library context
                    ShelfSectionView(
                        section: ShelfSection(
                            id: "lib-rec",
                            title: "You Might Also Like",
                            subtitle: nil,
                            items: recommended.items
                        ),
                        items: recommended.items,
                        card: { LockupCardView(item: $0) },
                        destination: { DetailView(item: $0) }
                    )

                    Spacer(minLength: AppTheme.spacingXXL)
                }
                .padding(.top, AppTheme.spacingLG)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("My List")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacingXL)

            if appState.watchlistItems.isEmpty {
                // placeholder when empty
                HStack(spacing: AppTheme.spacingMD) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your list is empty")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Add films and series using the + button on any detail page.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.vertical, AppTheme.spacingMD)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppTheme.spacingMD) {
                        ForEach(appState.watchlistItems) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                LockupCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingXL)
                    .padding(.trailing, AppTheme.spacingXL)
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .environment(AppState())
}

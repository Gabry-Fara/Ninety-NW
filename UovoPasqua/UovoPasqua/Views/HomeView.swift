import SwiftUI

// scroll offset preference key for hero parallax / fade
private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var heroNavigateToDetail = false
    @State private var scrollOffset: CGFloat = 0

    private let hero      = SampleDataProvider.heroItem
    private let trending  = SampleDataProvider.trendingShelf
    private let continuing = SampleDataProvider.continueWatchingShelf
    private let recommended = SampleDataProvider.recommendedShelf
    private let categories = SampleDataProvider.categories

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                    // scroll offset tracker using geometry reader + preference
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                    .frame(height: 0)

                    // hero — above the fold
                    NavigationLink(destination: DetailView(item: hero)) {
                        HeroHeaderView(
                            item: hero,
                            onPlay: {},
                            onDetails: {},
                            onAddToList: { appState.toggleWatchlist($0) }
                        )
                    }
                    .buttonStyle(.plain)

                    // trending shelf
                    ShelfSectionView(
                        section: trending,
                        items: trending.items,
                        card: { LockupCardView(item: $0) },
                        destination: { DetailView(item: $0) }
                    )

                    // continue watching — only if items exist
                    if !continuing.items.isEmpty {
                        ShelfSectionView(
                            section: continuing,
                            items: continuing.items,
                            card: { LockupCardView(item: $0) },
                            destination: { DetailView(item: $0) }
                        )
                    }

                    // categories row
                    categoriesRow

                    // recommended
                    ShelfSectionView(
                        section: recommended,
                        items: recommended.items,
                        card: { LockupCardView(item: $0) },
                        destination: { DetailView(item: $0) }
                    )

                    Spacer(minLength: AppTheme.spacingXXL)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .background(Color.black.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
        }
    }

    // categories as a horizontal row of category cards
    private var categoriesRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Browse Categories")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacingXL)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppTheme.spacingMD) {
                    ForEach(categories) { cat in
                        NavigationLink(destination: CatalogView(initialCategory: cat)) {
                            LockupCardView(category: cat)
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

#Preview {
    HomeView()
        .environment(AppState())
}

import SwiftUI

struct DetailView: View {
    let item: MediaItem
    @Environment(AppState.self) private var appState
    @FocusState private var focusedAction: DetailAction?

    enum DetailAction: Hashable { case play, addToList }

    private var related: [MediaItem] { SampleDataProvider.relatedItems(for: item) }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // hero header area
                detailHero

                // metadata + actions
                VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                    metadataBlock
                    actionsRow
                    descriptionBlock

                    // more like this shelf
                    if !related.isEmpty {
                        moreLikeThis
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.vertical, AppTheme.spacingLG)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { focusedAction = .play }
    }

    // MARK: subviews

    private var detailHero: some View {
        ZStack(alignment: .bottomLeading) {
            // artwork gradient full width
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor(item.artworkColorTop),
                    AppTheme.placeholderColor(item.artworkColorBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 460)

            Image(systemName: item.artworkSymbol)
                .font(.system(size: 140))
                .foregroundStyle(.white.opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: 460)

            // bottom gradient fade to black
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 460)

            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(item.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, AppTheme.spacingXL)
            .padding(.bottom, AppTheme.spacingMD)
        }
    }

    private var metadataBlock: some View {
        HStack(spacing: AppTheme.spacingMD) {
            if let cat = SampleDataProvider.categories.first(where: { $0.id == item.categoryID }) {
                Label(cat.name, systemImage: cat.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            if item.isInProgress {
                Label("\(Int(item.progressFraction * 100))% watched", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.orange.opacity(0.9))
            }
        }
    }

    private var actionsRow: some View {
        HStack(spacing: AppTheme.spacingSM) {
            QuickActionButtonView(label: item.isInProgress ? "Resume" : "Play",
                                  symbolName: "play.fill", style: .primary) {}
                .focused($focusedAction, equals: .play)

            QuickActionButtonView(
                label: appState.isInWatchlist(item) ? "In List" : "Add to List",
                symbolName: appState.isInWatchlist(item) ? "checkmark" : "plus",
                style: .secondary
            ) {
                appState.toggleWatchlist(item)
            }
            .focused($focusedAction, equals: .addToList)
        }
    }

    private var descriptionBlock: some View {
        Text(item.description)
            .font(.body)
            .foregroundStyle(.white.opacity(0.85))
            .lineSpacing(4)
            .frame(maxWidth: 700, alignment: .leading)
    }

    private var moreLikeThis: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("More Like This")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppTheme.spacingMD) {
                    ForEach(related) { rel in
                        NavigationLink(destination: DetailView(item: rel)) {
                            LockupCardView(item: rel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, AppTheme.spacingXL)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(item: SampleDataProvider.films[0])
            .environment(AppState())
    }
}

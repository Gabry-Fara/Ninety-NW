import SwiftUI

// full-bleed hero at top of home view
struct HeroHeaderView: View {
    let item: MediaItem
    let onPlay: () -> Void
    let onDetails: () -> Void
    let onAddToList: (MediaItem) -> Void

    @Environment(AppState.self) private var appState
    @FocusState private var focusedAction: HeroAction?

    enum HeroAction: Hashable { case play, details, addToList }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // artwork area — right side placeholder
            HStack(spacing: 0) {
                Color.clear
                    .frame(maxWidth: AppTheme.heroHeight * 0.55)

                // artwork placeholder gradient
                ZStack {
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(item.artworkColorTop),
                            AppTheme.placeholderColor(item.artworkColorBottom)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: item.artworkSymbol)
                        .font(.system(size: 120))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }

            // full overlay gradient: left-to-right for text, top-to-bottom for readability
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black.opacity(0.8), location: 0.45),
                    .init(color: .black.opacity(0.0), location: 0.75),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            AppTheme.heroOverlayGradient

            // content column
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Spacer()

                Text(item.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Text(item.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .frame(maxWidth: 540, alignment: .leading)

                HStack(spacing: AppTheme.spacingSM) {
                    QuickActionButtonView(label: "Play", symbolName: "play.fill", style: .primary) {
                        onPlay()
                    }
                    .focused($focusedAction, equals: .play)

                    QuickActionButtonView(label: "Details", symbolName: "info.circle", style: .secondary) {
                        onDetails()
                    }
                    .focused($focusedAction, equals: .details)

                    QuickActionButtonView(
                        label: appState.isInWatchlist(item) ? "In List" : "Add to List",
                        symbolName: appState.isInWatchlist(item) ? "checkmark" : "plus",
                        style: .secondary
                    ) {
                        onAddToList(item)
                    }
                    .focused($focusedAction, equals: .addToList)
                }
                .padding(.top, AppTheme.spacingXS)
            }
            .padding(.horizontal, AppTheme.spacingXL)
            .padding(.bottom, AppTheme.spacingLG)
        }
        .frame(height: AppTheme.heroHeight)
        .onAppear {
            // give initial focus to play button
            focusedAction = .play
        }
    }
}

#Preview {
    NavigationStack {
        HeroHeaderView(
            item: SampleDataProvider.heroItem,
            onPlay: {},
            onDetails: {},
            onAddToList: { _ in }
        )
        .environment(AppState())
        .background(Color.black)
    }
}

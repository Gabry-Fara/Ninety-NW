import SwiftUI

// reusable card for both MediaItem and Category content
struct LockupCardView: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let colorTop: String
    let colorBottom: String
    var progressFraction: Double = 0       // 0 hides the bar
    var isCategory: Bool = false

    @Environment(\.isFocused) private var isFocused

    private var width: CGFloat  { isCategory ? AppTheme.categoryCardWidth  : AppTheme.cardWidth }
    private var height: CGFloat { isCategory ? AppTheme.categoryCardHeight : AppTheme.cardHeight }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // placeholder artwork gradient
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(colorTop),
                            AppTheme.placeholderColor(colorBottom)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // large symbol watermark
            Image(systemName: symbolName)
                .font(.system(size: isCategory ? 36 : 44))
                .foregroundStyle(.white.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: 12, y: -8)

            // bottom overlay gradient
            AppTheme.cardOverlayGradient

            // text stack
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(isCategory ? .callout : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                // progress bar
                if progressFraction > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .frame(height: 3)
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width * progressFraction, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 4)
                }
            }
            .padding(AppTheme.spacingSM)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .scaleEffect(isFocused ? AppTheme.focusScaleCard : 1)
        .shadow(color: isFocused ? .white.opacity(0.15) : .black.opacity(0.4),
                radius: isFocused ? 20 : 8, y: isFocused ? 8 : 4)
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: isFocused)
    }
}

// convenience init from MediaItem
extension LockupCardView {
    init(item: MediaItem) {
        self.title            = item.title
        self.subtitle         = item.subtitle
        self.symbolName       = item.artworkSymbol
        self.colorTop         = item.artworkColorTop
        self.colorBottom      = item.artworkColorBottom
        self.progressFraction = item.progressFraction
        self.isCategory       = false
    }

    init(category: Category) {
        self.title       = category.name
        self.subtitle    = category.tagline
        self.symbolName  = category.symbolName
        self.colorTop    = category.gradientStart
        self.colorBottom = category.gradientEnd
        self.isCategory  = true
    }
}

#Preview {
    HStack(spacing: 24) {
        LockupCardView(item: SampleDataProvider.films[0])
        LockupCardView(item: SampleDataProvider.films[1])
        LockupCardView(category: SampleDataProvider.categories[0])
    }
    .padding()
    .background(Color.black)
}

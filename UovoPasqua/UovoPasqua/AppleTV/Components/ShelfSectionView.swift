import SwiftUI

// generic horizontal shelf — works for any Identifiable item with a card and destination view
struct ShelfSectionView<Item: Identifiable & Hashable, Card: View, Destination: View>: View {
    let section: ShelfSection
    let items: [Item]
    let card: (Item) -> Card
    let destination: (Item) -> Destination

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            // section header
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if let sub = section.subtitle {
                    Text(sub)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, AppTheme.spacingXL)

            // horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppTheme.spacingMD) {
                    ForEach(items) { item in
                        NavigationLink(destination: destination(item)) {
                            card(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                // leading + trailing padding so partially visible cards hint at more
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.trailing, AppTheme.spacingXL)
            }
        }
    }
}

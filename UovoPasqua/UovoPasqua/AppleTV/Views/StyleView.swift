import SwiftUI

// stile grafico — selezione fake, nessuno stile viene applicato per ora
private struct GraphicStyle: Identifiable {
    let id: String
    let name: String
    let description: String
    let accentColor: String
    let backgroundToken: String
    let symbol: String
}

private let availableStyles: [GraphicStyle] = [
    GraphicStyle(id: "minimal",   name: "Minimal",    description: "Sfondo scuro, testo pulito, nessun colore in eccesso.",         accentColor: "slate",   backgroundToken: "midnight", symbol: "circle.fill"),
    GraphicStyle(id: "neon",      name: "Neon",       description: "Bagliori al neon su sfondo nero profondo.",                     accentColor: "violet",  backgroundToken: "midnight", symbol: "sparkles"),
    GraphicStyle(id: "retro",     name: "Retro",      description: "Palette anni '80, pixel e nostalgia.",                         accentColor: "amber",   backgroundToken: "crimson",  symbol: "gamecontroller.fill"),
    GraphicStyle(id: "nature",    name: "Nature",     description: "Verde bosco, terra e toni naturali.",                          accentColor: "forest",  backgroundToken: "teal",     symbol: "leaf.fill"),
    GraphicStyle(id: "ocean",     name: "Ocean",      description: "Profondità marine, blu e azzurri freddi.",                     accentColor: "ocean",   backgroundToken: "indigo",   symbol: "water.waves"),
    GraphicStyle(id: "fire",      name: "Fire",       description: "Rosso e arancio, energia e calore.",                           accentColor: "crimson", backgroundToken: "amber",    symbol: "flame.fill"),
    GraphicStyle(id: "space",     name: "Space",      description: "Viola cosmico, stelle e polvere di nebula.",                   accentColor: "indigo",  backgroundToken: "violet",   symbol: "star.fill"),
    GraphicStyle(id: "gold",      name: "Gold",       description: "Lusso dorato su nero, per i vincitori.",                       accentColor: "gold",    backgroundToken: "slate",    symbol: "crown.fill"),
]

struct StyleView: View {
    // nessuna selezione reale — solo UI
    @State private var hoveredID: String? = nil

    private let columns = [
        GridItem(.fixed(380), spacing: 32),
        GridItem(.fixed(380), spacing: 32),
        GridItem(.fixed(380), spacing: 32),
        GridItem(.fixed(380), spacing: 32),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            // header
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Scegli uno stile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Personalizza l'aspetto dell'app. Nessuno stile è ancora attivo.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, AppTheme.spacingXL)

            // griglia stili
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 32) {
                    ForEach(availableStyles) { style in
                        StyleCardView(style: style)
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.bottom, AppTheme.spacingXXL)
            }
        }
        .padding(.top, AppTheme.spacingLG)
        .background(Color(white: 0.06).ignoresSafeArea())
    }
}

// card per un singolo stile grafico
private struct StyleCardView: View {
    let style: GraphicStyle
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button {} label: {
            ZStack(alignment: .bottomLeading) {
                // sfondo gradiente dello stile
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.placeholderColor(style.backgroundToken),
                                AppTheme.placeholderColor(style.accentColor),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isFocused ? 1 : 0.6)

                // simbolo decorativo
                Image(systemName: style.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.15))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: 20, y: -10)

                // overlay scuro basso
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.3),
                        .init(color: .black.opacity(0.7), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG))

                // testo
                VStack(alignment: .leading, spacing: 6) {
                    Text(style.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(style.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
                .padding(AppTheme.spacingSM)

                // badge "presto disponibile"
                Text("Presto")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .foregroundStyle(.white.opacity(0.8))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(AppTheme.spacingSM)
            }
            .frame(width: 380, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .strokeBorder(Color.white.opacity(isFocused ? 0.5 : 0.0), lineWidth: 2)
            )
            .scaleEffect(isFocused ? AppTheme.focusScaleCard : 1)
            .shadow(color: isFocused ? AppTheme.placeholderColor(style.accentColor).opacity(0.5) : .clear, radius: 24)
            .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StyleView()
        .environment(AppState())
}

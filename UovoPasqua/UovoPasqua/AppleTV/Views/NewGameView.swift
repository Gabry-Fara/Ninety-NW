import SwiftUI

// modalità di gioco selezionabile
enum GameMode: Hashable {
    case duello   // 2 giocatori, meglio di 3
    case torneo   // 4–8 giocatori, eliminazione diretta
}

// stile grafico della partita — fake per ora
struct GameStyle: Identifiable, Hashable {
    let id: String
    let name: String
    let colorToken: String
    let symbol: String
}

private let availableStyles: [GameStyle] = [
    GameStyle(id: "minimal",  name: "Minimal",  colorToken: "slate",   symbol: "circle.fill"),
    GameStyle(id: "neon",     name: "Neon",     colorToken: "violet",  symbol: "sparkles"),
    GameStyle(id: "retro",    name: "Retro",    colorToken: "amber",   symbol: "gamecontroller.fill"),
    GameStyle(id: "nature",   name: "Nature",   colorToken: "forest",  symbol: "leaf.fill"),
    GameStyle(id: "ocean",    name: "Ocean",    colorToken: "ocean",   symbol: "water.waves"),
    GameStyle(id: "fire",     name: "Fire",     colorToken: "crimson", symbol: "flame.fill"),
    GameStyle(id: "space",    name: "Space",    colorToken: "indigo",  symbol: "star.fill"),
    GameStyle(id: "gold",     name: "Gold",     colorToken: "gold",    symbol: "crown.fill"),
]

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMode: GameMode?    = nil
    @State private var selectedStyle: GameStyle?  = nil
    @State private var tournamentPlayers: Int      = 4

    @FocusState private var focusedMode: GameMode?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {

                // header
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text("Nuova Partita")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Scegli il formato e lo stile della partita.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, AppTheme.spacingXL)

                // selezione modalità
                HStack(spacing: AppTheme.spacingLG) {
                    modeCard(
                        mode: .duello,
                        title: "Duello",
                        subtitle: "2 giocatori",
                        detail: "Meglio di 3 manche",
                        symbol: "person.2.fill",
                        colorToken: "indigo"
                    )
                    modeCard(
                        mode: .torneo,
                        title: "Torneo",
                        subtitle: "\(tournamentPlayers) giocatori",
                        detail: "Eliminazione diretta",
                        symbol: "trophy.fill",
                        colorToken: "amber"
                    )
                }
                .padding(.horizontal, AppTheme.spacingXL)

                // selettore numero giocatori — solo per torneo
                if selectedMode == .torneo {
                    playerPicker
                        .padding(.horizontal, AppTheme.spacingXL)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // sezione stile
                styleSection

                // bottoni azione
                HStack(spacing: AppTheme.spacingSM) {
                    QuickActionButtonView(
                        label: "Crea Partita",
                        symbolName: "play.fill",
                        style: selectedMode != nil ? .primary : .secondary
                    ) {
                        // avvio partita da implementare
                    }
                    .disabled(selectedMode == nil)

                    QuickActionButtonView(
                        label: "Annulla",
                        symbolName: "xmark",
                        style: .secondary
                    ) {
                        dismiss()
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.bottom, AppTheme.spacingXL)
            }
            .padding(.top, AppTheme.spacingLG)
        }
        .background(Color(white: 0.06).ignoresSafeArea())
        .animation(.easeOut(duration: 0.22), value: selectedMode)
        .onAppear { focusedMode = .duello }
    }

    // MARK: mode card

    private func modeCard(
        mode: GameMode,
        title: String,
        subtitle: String,
        detail: String,
        symbol: String,
        colorToken: String
    ) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            selectedMode = mode
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(
                        isSelected
                        ? AppTheme.placeholderColor(colorToken).opacity(0.55)
                        : Color.white.opacity(0.07)
                    )

                Image(systemName: symbol)
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(AppTheme.spacingMD)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(AppTheme.spacingMD)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .strokeBorder(
                        isSelected ? AppTheme.placeholderColor(colorToken) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .focused($focusedMode, equals: mode)
        .scaleEffect(focusedMode == mode ? AppTheme.focusScaleCard : 1)
        .shadow(
            color: focusedMode == mode ? AppTheme.placeholderColor(colorToken).opacity(0.4) : .clear,
            radius: 24
        )
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: focusedMode == mode)
    }

    // MARK: player picker

    private var playerPicker: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Text("Giocatori:")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: AppTheme.spacingSM) {
                Button {
                    if tournamentPlayers > 4 { tournamentPlayers -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(tournamentPlayers > 4 ? .white : .white.opacity(0.25))
                }
                .buttonStyle(.plain)
                .disabled(tournamentPlayers <= 4)

                Text("\(tournamentPlayers)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(minWidth: 48)
                    .monospacedDigit()

                Button {
                    if tournamentPlayers < 8 { tournamentPlayers += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(tournamentPlayers < 8 ? .white : .white.opacity(0.25))
                }
                .buttonStyle(.plain)
                .disabled(tournamentPlayers >= 8)
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingXS)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))

            Text("min 4 · max 8")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: style section

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text("Stile")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if selectedStyle == nil {
                    Text("· opzionale")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, AppTheme.spacingXL)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingMD) {
                    ForEach(availableStyles) { style in
                        styleChip(style)
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.trailing, AppTheme.spacingXL)
                .padding(.vertical, AppTheme.spacingXS)
            }
        }
    }

    private func styleChip(_ style: GameStyle) -> some View {
        let isSelected = selectedStyle?.id == style.id

        return Button {
            selectedStyle = isSelected ? nil : style
        } label: {
            StyleChipView(style: style, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// chip compatto per la selezione stile
private struct StyleChipView: View {
    let style: GameStyle
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // sfondo gradiente
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(style.colorToken),
                            AppTheme.placeholderColor(style.colorToken).opacity(0.5),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isSelected || isFocused ? 1 : 0.45)

            // simbolo
            Image(systemName: style.symbol)
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.2))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8)

            // nome
            VStack(alignment: .leading, spacing: 2) {
                Text(style.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("Presto")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(AppTheme.spacingSM)
        }
        .frame(width: 160, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .strokeBorder(
                    isSelected ? .white : Color.white.opacity(isFocused ? 0.4 : 0.0),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .overlay(alignment: .topLeading) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(6)
            }
        }
        .scaleEffect(isFocused ? AppTheme.focusScaleCard : 1)
        .shadow(color: isFocused ? AppTheme.placeholderColor(style.colorToken).opacity(0.5) : .clear, radius: 16)
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: isFocused)
    }
}

#Preview {
    NewGameView()
        .environment(AppState())
}

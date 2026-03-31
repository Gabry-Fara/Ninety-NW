import SwiftUI

// modalità di gioco selezionabile
enum GameMode: Hashable {
    case duello   // 2 giocatori, meglio di 3
    case torneo   // 4–8 giocatori, eliminazione diretta
}

struct NewGameView: View {
    @State private var selectedMode: GameMode?    = nil
    @State private var selectedStyle: GameStyle    = SampleDataProvider.gameStyles[0]
    @State private var tournamentPlayers: Int      = 4
    @State private var showConnectedIPhones = false

    @FocusState private var focusedMode: GameMode?
    @FocusState private var focusedAction: ActionButton?

    private enum ActionButton: Hashable {
        case create
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {

                // header
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text("Nuova Partita")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Scegli il formato e poi uno dei tre stili visivi.")
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
                        guard selectedMode != nil else { return }
                        showConnectedIPhones = true
                    }
                    .disabled(selectedMode == nil)
                    .focused($focusedAction, equals: .create)
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.bottom, AppTheme.spacingXL)
            }
            .padding(.top, AppTheme.spacingLG)
        }
        .background(backgroundLayer.ignoresSafeArea())
        .animation(.easeOut(duration: 0.22), value: selectedMode)
        .animation(.easeOut(duration: 0.22), value: selectedStyle.id)
        .onAppear {
            focusedMode = .duello
            focusedAction = nil
        }
        .onChange(of: selectedMode) { _, newValue in
            if newValue != nil {
                focusedMode = nil
                focusedAction = .create
            } else {
                focusedAction = nil
            }
        }
        .onChange(of: selectedStyle) { _, _ in
            guard selectedMode != nil else { return }
            focusedAction = .create
        }
        .onChange(of: tournamentPlayers) { _, _ in
            guard selectedMode == .torneo else { return }
            focusedAction = .create
        }
        .navigationDestination(isPresented: $showConnectedIPhones) {
            if let mode = selectedMode {
                ConnectedIPhonesView(
                    selectedMode: mode,
                    selectedStyle: selectedStyle,
                    playerCount: mode == .duello ? 2 : tournamentPlayers
                )
            }
        }
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
        let styles = SampleDataProvider.gameStyles
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingMD), count: 3)

        return VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            HStack {
                Text("Stile")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("· cyber, oceano, vulcano")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, AppTheme.spacingXL)

            LazyVGrid(columns: columns, spacing: AppTheme.spacingMD) {
                ForEach(styles) { style in
                    styleOption(style)
                }
            }
            .padding(.horizontal, AppTheme.spacingXL)
        }
    }

    private func styleOption(_ style: GameStyle) -> some View {
        let isSelected = selectedStyle.id == style.id

        return Button {
            selectedStyle = style
        } label: {
            StyleOptionCardView(style: style, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct StyleOptionCardView: View {
    let style: GameStyle
    let isSelected: Bool

    @Environment(\.isFocused) private var isFocused

    private var emphasis: Bool { isFocused || isSelected }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(style.backgroundToken),
                            AppTheme.placeholderColor(style.accentToken)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(style.previewAssetName)
                .resizable()
                .scaledToFill()
                .opacity(0.75)
                .blur(radius: 0.2)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.2),
                    .init(color: .black.opacity(0.78), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))

            VStack(alignment: .leading, spacing: 4) {
                Label(style.name, systemImage: style.symbolName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(style.tagline)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            }
            .padding(AppTheme.spacingSM)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(AppTheme.spacingSM)
            }
        }
        .frame(height: 150)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .strokeBorder(
                    isSelected ? .white : Color.white.opacity(isFocused ? 0.45 : 0.1),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(emphasis ? AppTheme.focusScaleCard : 1)
        .shadow(color: emphasis ? AppTheme.placeholderColor(style.accentToken).opacity(0.38) : .clear, radius: 18, y: 8)
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: emphasis)
    }
}

private extension NewGameView {
    @ViewBuilder
    var backgroundLayer: some View {
        ZStack {
            GameStyleArtworkView(style: selectedStyle, mode: .backdrop, blurRadius: 0.5)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.20),
                    .black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NewGameView()
        .environment(AppState())
}

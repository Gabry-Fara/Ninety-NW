import SwiftUI

// modalità di gioco selezionabile
enum GameMode: Hashable {
    case duello        // 2 giocatori, meglio di 3
    case torneo        // 4–8 giocatori, eliminazione diretta
}

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMode: GameMode? = nil
    @State private var tournamentPlayers: Int = 4
    @FocusState private var focusedMode: GameMode?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXL) {

            // header
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Nuova Partita")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Scegli il formato di gioco.")
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

            // selettore numero giocatori torneo
            if selectedMode == .torneo {
                playerPicker
                    .padding(.horizontal, AppTheme.spacingXL)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // bottone crea partita
            HStack {
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
                // sfondo
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(
                        isSelected
                        ? AppTheme.placeholderColor(colorToken).opacity(0.55)
                        : Color.white.opacity(0.07)
                    )

                // simbolo decorativo
                Image(systemName: symbol)
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: 20)

                // testo
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

                // spunta selezione
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(AppTheme.spacingMD)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .strokeBorder(
                        isSelected
                        ? AppTheme.placeholderColor(colorToken)
                        : Color.white.opacity(0.1),
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

    // MARK: selettore giocatori torneo

    private var playerPicker: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Text("Giocatori:")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: AppTheme.spacingSM) {
                // decrementa
                Button {
                    if tournamentPlayers > 4 { tournamentPlayers -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(tournamentPlayers > 4 ? .white : .white.opacity(0.25))
                }
                .buttonStyle(.plain)
                .disabled(tournamentPlayers <= 4)

                // valore
                Text("\(tournamentPlayers)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(minWidth: 48)
                    .monospacedDigit()

                // incrementa
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
}

#Preview {
    NewGameView()
        .environment(AppState())
}

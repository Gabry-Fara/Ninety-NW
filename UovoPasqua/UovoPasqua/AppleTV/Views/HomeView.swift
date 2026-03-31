import SwiftUI

// mock game session — verrà sostituito con dati reali
private struct GameSession: Identifiable {
    let id: String
    let name: String
    let playerCount: Int
    let round: Int
    let colorToken: String
}

private let mockGames: [GameSession] = [
    GameSession(id: "g1", name: "Partita di Marco", playerCount: 3, round: 2, colorToken: "indigo"),
    GameSession(id: "g2", name: "Sfida veloce",     playerCount: 2, round: 1, colorToken: "forest"),
    GameSession(id: "g3", name: "Torneo sera",      playerCount: 4, round: 5, colorToken: "ocean"),
    GameSession(id: "g4", name: "Classica",         playerCount: 2, round: 3, colorToken: "violet"),
    GameSession(id: "g5", name: "Rivincita",        playerCount: 2, round: 1, colorToken: "crimson"),
]

struct HomeView: View {
    @FocusState private var createFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // hero: crea nuova partita
            createPanel
                .padding(.top, AppTheme.spacingXL)

            Spacer()

            // partite in corso
            partiteInCorso
                .padding(.bottom, AppTheme.spacingXL)
        }
        .background(Color(white: 0.06).ignoresSafeArea())
    }

    // MARK: create panel

    private var createPanel: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingXXL) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                Text("Sasso Carta Forbice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Crea una partita e condividila con i giocatori nella stessa rete.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: 480, alignment: .leading)

                HStack(spacing: AppTheme.spacingSM) {
                    QuickActionButtonView(
                        label: "Nuova Partita",
                        symbolName: "plus",
                        style: .primary
                    ) {
                        // navigazione da implementare
                    }
                    .focused($createFocused)

                    QuickActionButtonView(
                        label: "Unisciti",
                        symbolName: "person.badge.plus",
                        style: .secondary
                    ) {
                        // navigazione da implementare
                    }
                }
            }

            Spacer()

            // icona decorativa destra
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 220, height: 220)

                Text("✊ ✋ ✌️")
                    .font(.system(size: 52))
            }
        }
        .padding(.horizontal, AppTheme.spacingXL)
        .onAppear { createFocused = true }
    }

    // MARK: partite in corso

    private var partiteInCorso: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Partite in corso")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacingXL)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppTheme.spacingMD) {
                    ForEach(mockGames) { game in
                        // placeholder — nessuna destinazione per ora
                        Button {} label: {
                            gameCard(game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.trailing, AppTheme.spacingXL)
            }
        }
    }

    @ViewBuilder
    private func gameCard(_ game: GameSession) -> some View {
        GameCardView(game: game)
    }
}

// card per una partita in corso
private struct GameCardView: View {
    let game: GameSession
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.placeholderColor(game.colorToken).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(Color.white.opacity(isFocused ? 0.5 : 0.1), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                HStack(spacing: AppTheme.spacingXS) {
                    Label("\(game.playerCount) giocatori", systemImage: "person.2.fill")
                    Spacer()
                    Text("Round \(game.round)")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(AppTheme.spacingSM)
        }
        .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight * 0.65)
        .scaleEffect(isFocused ? AppTheme.focusScaleCard : 1)
        .shadow(color: isFocused ? .white.opacity(0.12) : .clear, radius: 16)
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: isFocused)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}

import SwiftUI

enum RPSMove: String, CaseIterable, Hashable {
    case rock
    case paper
    case scissors

    var title: String {
        switch self {
        case .rock: return "Sasso"
        case .paper: return "Carta"
        case .scissors: return "Forbici"
        }
    }

    var symbol: String {
        switch self {
        case .rock: return "circle.dotted.circle"
        case .paper: return "doc.fill"
        case .scissors: return "scissors"
        }
    }

    func beats(_ other: RPSMove) -> Bool {
        switch self {
        case .rock: return other == .scissors
        case .paper: return other == .rock
        case .scissors: return other == .paper
        }
    }
}

struct GamePlayView: View {
    let selectedMode: GameMode
    let selectedStyle: GameStyle?
    let players: [ConnectedPhone]

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedMove: RPSMove?
    @State private var roundNumber = 1
    @State private var leftScore = 0
    @State private var rightScore = 0
    @State private var playerMove: RPSMove?
    @State private var opponentMove: RPSMove?
    @State private var matchMessage = "scegli una mossa per iniziare."
    @State private var matchFinished = false

    private var leftPlayer: ConnectedPhone { players.first ?? SampleDataProvider.mockConnectedPhones[0] }
    private var rightPlayer: ConnectedPhone { players.dropFirst().first ?? SampleDataProvider.mockConnectedPhones[1] }

    private var accentToken: String {
        selectedStyle?.colorToken ?? leftPlayer.accentTop
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLG) {
            topBar
            scoreboard
            arena
            moveBar
        }
        .padding(.horizontal, AppTheme.spacingXL)
        .padding(.top, AppTheme.spacingLG)
        .padding(.bottom, AppTheme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundLayer.ignoresSafeArea())
        .onAppear {
            focusedMove = .rock
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingLG) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Partita in corso")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(selectedMode == .duello ? "duello mock 1 contro 1" : "torneo mock con due partecipanti selezionati")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer(minLength: 0)

            HStack(spacing: AppTheme.spacingSM) {
                if let selectedStyle {
                    Label(selectedStyle.name, systemImage: selectedStyle.symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }

                QuickActionButtonView(
                    label: "Indietro",
                    symbolName: "chevron.left",
                    style: .secondary
                ) {
                    dismiss()
                }
            }
        }
    }

    private var scoreboard: some View {
        HStack(spacing: AppTheme.spacingLG) {
            scoreCard(title: leftPlayer.deviceName, score: leftScore, token: leftPlayer.accentTop, isLeader: leftScore > rightScore)
            centerStatus
            scoreCard(title: rightPlayer.deviceName, score: rightScore, token: rightPlayer.accentTop, isLeader: rightScore > leftScore)
        }
    }

    private var centerStatus: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Text("Round \(roundNumber)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

            Text(matchMessage)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreCard(title: String, score: Int, token: String, isLeader: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)

            Text("\(score)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(isLeader ? "in vantaggio" : "pronto a ribaltare")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(token).opacity(0.72),
                            AppTheme.placeholderColor(token).opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                        .strokeBorder(Color.white.opacity(isLeader ? 0.42 : 0.12), lineWidth: 1)
                )
        )
    }

    private var arena: some View {
        HStack(spacing: AppTheme.spacingLG) {
            playerPanel(phone: leftPlayer, move: playerMove)
            vsOrb
            playerPanel(phone: rightPlayer, move: opponentMove)
        }
        .frame(maxWidth: .infinity)
    }

    private func playerPanel(phone: ConnectedPhone, move: RPSMove?) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.placeholderColor(phone.accentTop),
                            AppTheme.placeholderColor(phone.accentBottom)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            LinearGradient(
                colors: [
                    .black.opacity(0.10),
                    .black.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG))

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phone.deviceName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(phone.modelName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "iphone.gen2")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(move?.title ?? "in attesa")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(move == nil ? "la mossa apparirà qui" : "mossa registrata")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(AppTheme.spacingLG)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var vsOrb: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Text("vs")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(matchFinished ? "match chiuso" : "round live")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingLG)
        .background(
            Circle()
                .fill(AppTheme.placeholderColor(accentToken).opacity(0.55))
                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        )
    }

    private var moveBar: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("scegli la mossa")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Text(matchFinished ? "ricomincia o esci" : "best of 5")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }

            HStack(spacing: AppTheme.spacingMD) {
                ForEach(RPSMove.allCases, id: \.self) { move in
                    QuickActionButtonView(
                        label: move.title,
                        symbolName: move.symbol,
                        style: .secondary
                    ) {
                        guard !matchFinished else { return }
                        playRound(playerMove: move)
                    }
                    .focused($focusedMove, equals: move)
                }

                Spacer(minLength: 0)

                QuickActionButtonView(
                    label: "Ricomincia",
                    symbolName: "arrow.counterclockwise",
                    style: .secondary
                ) {
                    resetMatch()
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func playRound(playerMove: RPSMove) {
        let opponent = RPSMove.allCases.randomElement() ?? .rock
        self.playerMove = playerMove
        self.opponentMove = opponent

        if playerMove == opponent {
            matchMessage = "pareggio."
        } else if playerMove.beats(opponent) {
            leftScore += 1
            matchMessage = "\(leftPlayer.deviceName) vince il round."
        } else {
            rightScore += 1
            matchMessage = "\(rightPlayer.deviceName) vince il round."
        }

        if leftScore == 3 || rightScore == 3 {
            matchFinished = true
            matchMessage = leftScore > rightScore ? "\(leftPlayer.deviceName) conquista la partita." : "\(rightPlayer.deviceName) conquista la partita."
        } else {
            roundNumber += 1
        }
    }

    private func resetMatch() {
        roundNumber = 1
        leftScore = 0
        rightScore = 0
        playerMove = nil
        opponentMove = nil
        matchMessage = "scegli una mossa per iniziare."
        matchFinished = false
        focusedMove = .rock
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor(accentToken).opacity(0.62),
                    AppTheme.placeholderColor("midnight"),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 700
            )
        }
    }
}

#Preview {
    NavigationStack {
        GamePlayView(
            selectedMode: .duello,
            selectedStyle: nil,
            players: Array(SampleDataProvider.mockConnectedPhones.prefix(2))
        )
    }
}

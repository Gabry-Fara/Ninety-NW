import SwiftUI

struct GamePlayView: View {
    let selectedMode: GameMode
    let selectedStyle: GameStyle?
    let players: [ConnectedPhone]

    @Environment(\.dismiss) private var dismiss

    private var gameStyle: GameStyle {
        selectedStyle ?? SampleDataProvider.gameStyles[0]
    }

    @State private var leftScore = 0
    @State private var rightScore = 0

    var body: some View {
        VStack(spacing: AppTheme.spacingLG) {
            topBar
            scoreHeader
            HStack(spacing: AppTheme.spacingLG) {
                playerHand(isLeading: true)

                playerHand(isLeading: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.spacingXL)
        .padding(.top, AppTheme.spacingLG)
        .padding(.bottom, AppTheme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundLayer.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack {
            QuickActionButtonView(
                label: "Indietro",
                symbolName: "chevron.left",
                style: .secondary
            ) {
                dismiss()
            }

            Spacer(minLength: 0)
        }
    }

    private var scoreHeader: some View {
        HStack {
            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Text("\(leftScore) - \(rightScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(selectedMode == .duello ? "duello" : "torneo")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 14)
            .tvGlassPanel()

            Spacer(minLength: 0)
        }
    }

    private func playerHand(isLeading: Bool) -> some View {
        let artworkName = gameStyle.gameplayAssetName

        return ZStack(alignment: isLeading ? .leading : .trailing) {
            Image(artworkName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 330)
                .scaleEffect(x: isLeading ? 1 : -1, y: 1)
                .shadow(color: .black.opacity(0.32), radius: 18, y: 10)
        }
        .frame(maxWidth: .infinity, minHeight: 360, alignment: isLeading ? .leading : .trailing)
        .padding(.top, isLeading ? 28 : 0)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            GameStyleArtworkView(style: gameStyle, mode: .backdrop)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.15),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.white.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 700
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        GamePlayView(
            selectedMode: .duello,
            selectedStyle: SampleDataProvider.gameStyles[0],
            players: Array(SampleDataProvider.sampleConnectedPhones.prefix(2))
        )
    }
}

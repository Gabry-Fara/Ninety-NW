import SwiftUI

struct GamePlayView: View {
    let selectedMode: GameMode
    let selectedStyle: GameStyle?
    let players: [ConnectedPhone]

    @Environment(\.dismiss) private var dismiss

    private var leftPlayer: ConnectedPhone { players.first ?? SampleDataProvider.mockConnectedPhones[0] }
    private var rightPlayer: ConnectedPhone { players.dropFirst().first ?? SampleDataProvider.mockConnectedPhones[1] }

    @State private var leftScore = 0
    @State private var rightScore = 0

    private var accentToken: String {
        selectedStyle?.colorToken ?? leftPlayer.accentTop
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLG) {
            topBar
            scoreHeader
            HStack(spacing: AppTheme.spacingLG) {
                playerStation(
                    phone: leftPlayer,
                    score: leftScore,
                    isLeading: true
                )

                centerBadge

                playerStation(
                    phone: rightPlayer,
                    score: rightScore,
                    isLeading: false
                )
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
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(.ultraThinMaterial)
                    .opacity(0.92)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            Spacer(minLength: 0)
        }
    }

    private func playerStation(phone: ConnectedPhone, score: Int, isLeading: Bool) -> some View {
        let contentAlignment: Alignment = isLeading ? .leading : .trailing

        return VStack(alignment: isLeading ? .leading : .trailing, spacing: AppTheme.spacingMD) {
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
                .overlay(
                    VStack(alignment: isLeading ? .leading : .trailing, spacing: 8) {
                        Image(systemName: "iphone.gen2")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(phone.ownerName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("punteggio \(score)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(AppTheme.spacingLG)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: contentAlignment)
                )
                .frame(maxWidth: .infinity, minHeight: 320)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var centerBadge: some View {
        VStack(spacing: 6) {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(.white)

            Text("play")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            Circle()
                .fill(AppTheme.placeholderColor(accentToken).opacity(0.55))
                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        )
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor(accentToken).opacity(0.45),
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

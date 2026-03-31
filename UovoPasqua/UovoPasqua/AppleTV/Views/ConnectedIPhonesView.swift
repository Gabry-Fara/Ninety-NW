import SwiftUI

struct ConnectedIPhonesView: View {
    let selectedMode: GameMode
    let selectedStyle: GameStyle?
    let playerCount: Int

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedPhoneID: String?
    @State private var selectedPhoneIDs: [String] = []
    @State private var showGameScreen = false

    private let columns = [
        GridItem(.fixed(290), spacing: AppTheme.spacingLG),
        GridItem(.fixed(290), spacing: AppTheme.spacingLG),
        GridItem(.fixed(290), spacing: AppTheme.spacingLG)
    ]

    private var selectedPhones: [ConnectedPhone] {
        selectedPhoneIDs.compactMap { id in
            SampleDataProvider.mockConnectedPhones.first(where: { $0.id == id })
        }
    }

    private var canStartMatch: Bool {
        selectedPhones.count == 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            topBar
            summaryCard
            deviceGrid
            footerBar
        }
        .padding(.horizontal, AppTheme.spacingXL)
        .padding(.top, AppTheme.spacingLG)
        .padding(.bottom, AppTheme.spacingLG)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundLayer.ignoresSafeArea())
        .onAppear {
            focusedPhoneID = SampleDataProvider.mockConnectedPhones.first?.id
        }
        .navigationDestination(isPresented: $showGameScreen) {
            if selectedPhones.count == 2 {
                GamePlayView(
                    selectedMode: selectedMode,
                    selectedStyle: selectedStyle,
                    players: selectedPhones
                )
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingLG) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("iPhone collegati")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("seleziona due dispositivi per avviare la partita.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: 760, alignment: .leading)
            }

            Spacer(minLength: 0)

            QuickActionButtonView(
                label: "Indietro",
                symbolName: "chevron.left",
                style: .secondary
            ) {
                dismiss()
            }
        }
    }

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingLG) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Modalità")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                Text(selectedMode == .duello ? "Duello" : "Torneo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(selectedMode == .duello ? "match veloce 1 contro 1." : "setup torneo con due partecipanti selezionati.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Stato selezione")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: canStartMatch ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(canStartMatch ? .green : .white.opacity(0.7))
                    Text("\(selectedPhones.count)/2 giocatori")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Text(canStartMatch ? "pronto per iniziare la partita." : "seleziona esattamente due iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Stile")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                if let selectedStyle {
                    Label(selectedStyle.name, systemImage: selectedStyle.symbol)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else {
                    Label("Predefinito", systemImage: "circle.dashed")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Text("dispositivi disponibili: \(playerCount).")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(AppTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .fill(.ultraThinMaterial)
                .opacity(0.92)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var deviceGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("Dispositivi trovati")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(selectedPhones.count) selezionati")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: columns, spacing: AppTheme.spacingLG) {
                ForEach(SampleDataProvider.mockConnectedPhones) { phone in
                    Button {
                        toggleSelection(for: phone)
                    } label: {
                        ConnectedPhoneCardView(
                            phone: phone,
                            isSelected: selectedPhones.contains(phone)
                        )
                    }
                    .buttonStyle(.plain)
                    .focused($focusedPhoneID, equals: phone.id)
                }
            }
        }
    }

    private var footerBar: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Label("seleziona due card per continuare", systemImage: "hand.point.right.fill")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            QuickActionButtonView(
                label: "Crea partita",
                symbolName: "play.fill",
                style: canStartMatch ? .primary : .secondary
            ) {
                guard canStartMatch else { return }
                showGameScreen = true
            }
            .disabled(!canStartMatch)
        }
    }

    private func toggleSelection(for phone: ConnectedPhone) {
        if let index = selectedPhoneIDs.firstIndex(of: phone.id) {
            selectedPhoneIDs.remove(at: index)
            return
        }

        if selectedPhoneIDs.count < 2 {
            selectedPhoneIDs.append(phone.id)
            return
        }

        selectedPhoneIDs.removeLast()
        selectedPhoneIDs.append(phone.id)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor("midnight"),
                    AppTheme.placeholderColor("slate"),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.10),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 600
            )
        }
    }
}

private struct ConnectedPhoneCardView: View {
    let phone: ConnectedPhone
    let isSelected: Bool

    @Environment(\.isFocused) private var isFocused

    private var emphasis: Bool { isFocused || isSelected }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
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
                    .black.opacity(0.02),
                    .black.opacity(0.74)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))

            VStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "iphone.gen2")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(phone.ownerName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 128)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .strokeBorder(
                    Color.white.opacity(emphasis ? 0.55 : 0.14),
                    lineWidth: emphasis ? 2 : 1
                )
        )
        .scaleEffect(emphasis ? 1.03 : 1)
        .shadow(
            color: emphasis ? AppTheme.placeholderColor(phone.accentTop).opacity(0.32) : .clear,
            radius: emphasis ? 16 : 0,
            y: emphasis ? 8 : 0
        )
        .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: emphasis)
    }
}

#Preview {
    NavigationStack {
        ConnectedIPhonesView(
            selectedMode: .duello,
            selectedStyle: nil,
            playerCount: 6
        )
    }
}

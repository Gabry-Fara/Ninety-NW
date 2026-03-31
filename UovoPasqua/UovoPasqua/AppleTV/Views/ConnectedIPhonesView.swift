import SwiftUI
import MultipeerConnectivity

struct ConnectedIPhonesView: View {
    let selectedMode: GameMode
    let selectedStyle: GameStyle?
    let availableDeviceCount: Int

    @EnvironmentObject var server: MultipeerServer
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedPhoneID: String?
    @FocusState private var focusedAction: ActionButton?
    @State private var selectedPhoneIDs: [String] = []
    @State private var showGameScreen = false

    private enum ActionButton: Hashable {
        case create
        case back
    }

    private let columns = [
        GridItem(.fixed(290), spacing: AppTheme.spacingLG),
        GridItem(.fixed(290), spacing: AppTheme.spacingLG),
        GridItem(.fixed(290), spacing: AppTheme.spacingLG)
    ]

    private var availablePhones: [ConnectedPhone] {
        server.connectedPeers.enumerated().map { index, peer in
            let colors = [("indigo", "blue"), ("amber", "orange"), ("rose", "pink"), ("emerald", "teal"), ("purple", "indigo")]
            let color = colors[index % colors.count]
            return ConnectedPhone(
                id: "\(peer.displayName)-\(peer.hashValue)",
                ownerName: peer.displayName,
                accentTop: color.0,
                accentBottom: color.1
            )
        }
    }

    private var selectedPhones: [ConnectedPhone] {
        selectedPhoneIDs.compactMap { id in
            availablePhones.first(where: { $0.id == id })
        }
    }

    private var maximumTournamentPlayers: Int {
        let maxAllowed = min(availableDeviceCount, 8)
        return maxAllowed - (maxAllowed % 2)
    }

    private var isTournamentMode: Bool {
        selectedMode == .torneo
    }

    private var minimumRequiredPlayers: Int {
        isTournamentMode ? 4 : 2
    }

    private var canStartMatch: Bool {
        if isTournamentMode {
            return selectedPhones.count >= minimumRequiredPlayers
                && selectedPhones.count.isMultiple(of: 2)
                && selectedPhones.count <= maximumTournamentPlayers
        }
        return selectedPhones.count == 2
    }

    private var selectionHint: String {
        if isTournamentMode {
            return "seleziona almeno 4 iPhone, in numero pari."
        }
        return "seleziona due iPhone per il duello."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            topBar
            if isTournamentMode {
                tournamentRuleBanner
            }
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
            focusedPhoneID = availablePhones.first?.id
            focusedAction = nil
        }
        .onChange(of: selectedPhoneIDs.count) { _, newValue in
            if isTournamentMode {
                if newValue >= minimumRequiredPlayers && newValue.isMultiple(of: 2) {
                    focusedPhoneID = nil
                    focusedAction = .create
                } else {
                    focusedAction = nil
                }
            } else if newValue == 2 {
                focusedPhoneID = nil
                focusedAction = .create
            } else {
                focusedAction = nil
            }
        }
        .navigationDestination(isPresented: $showGameScreen) {
            if canStartMatch {
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

                Text(selectionHint)
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
            .focused($focusedAction, equals: .back)
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

                Text(selectedMode == .duello ? "match veloce 1 contro 1." : "scelta libera dei device, ma sempre con numero pari.")
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
                    Text(isTournamentMode ? "\(selectedPhones.count) selezionati" : "\(selectedPhones.count)/2 giocatori")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Text(
                    canStartMatch
                    ? "pronto per iniziare la partita."
                    : (isTournamentMode ? "servono almeno 4 iPhone, in numero pari." : "seleziona esattamente due iPhone.")
                )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Stile")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                if let selectedStyle {
                    Label(selectedStyle.name, systemImage: selectedStyle.symbolName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else {
                    Label("Predefinito", systemImage: "circle.dashed")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Text("dispositivi disponibili: \(availableDeviceCount).")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

        }
        .padding(AppTheme.spacingMD)
        .tvGlassPanel()
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
                ForEach(availablePhones) { phone in
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
            Label(isTournamentMode ? "tappa i device: minimo 4, numero pari" : "seleziona due card per continuare", systemImage: "hand.point.right.fill")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            QuickActionButtonView(
                label: "Crea partita",
                symbolName: "play.fill",
                style: canStartMatch ? .primary : .secondary
            ) {
                guard canStartMatch else { return }
                
                // Fire off network notification to the two chosen devices!
                if selectedPhones.count == 2,
                   let p1 = getMCPeerID(for: selectedPhones[0]),
                   let p2 = getMCPeerID(for: selectedPhones[1]) {
                    server.startMatch(player1: p1, player2: p2)
                }
                
                showGameScreen = true
            }
            .disabled(!canStartMatch)
            .focused($focusedAction, equals: .create)
        }
    }

    private var tournamentRuleBanner: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMD) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.85))

            VStack(alignment: .leading, spacing: 4) {
                Text("setup torneo")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("tocca i device direttamente. puoi creare solo con almeno 4 selezionati e un numero pari.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: 0)

            Text("\(selectedPhones.count) selezionati")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(AppTheme.spacingMD)
        .tvGlassPanel()
    }

    private func toggleSelection(for phone: ConnectedPhone) {
        if let index = selectedPhoneIDs.firstIndex(of: phone.id) {
            selectedPhoneIDs.remove(at: index)
            return
        }

        if isTournamentMode {
            if selectedPhoneIDs.count < maximumTournamentPlayers {
                selectedPhoneIDs.append(phone.id)
            }
        } else if selectedPhoneIDs.count < 2 {
            selectedPhoneIDs.append(phone.id)
        }

        if canStartMatch {
            focusedPhoneID = nil
            focusedAction = .create
        }
    }
    
    // Reverse lookup from the wrapper struct back to the network device object
    private func getMCPeerID(for phone: ConnectedPhone) -> MCPeerID? {
        return server.connectedPeers.first { "\($0.displayName)-\($0.hashValue)" == phone.id }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        let style = selectedStyle ?? SampleDataProvider.gameStyles[0]

        ZStack {
            GameStyleArtworkView(style: style, mode: .backdrop, blurRadius: 10)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.30),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.white.opacity(0.08),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 600
            )
            .ignoresSafeArea()
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

            VStack(spacing: 0) {
                Text(phone.ownerName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
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
        .tvFocusEffect(
            isFocused: emphasis,
            scale: 1.03,
            shadowColor: AppTheme.placeholderColor(phone.accentTop).opacity(0.32),
            shadowRadius: 16,
            shadowYOffset: 8
        )
    }
}

#Preview {
    NavigationStack {
        ConnectedIPhonesView(
            selectedMode: .duello,
            selectedStyle: nil,
            availableDeviceCount: 6
        )
        .environmentObject(MultipeerServer())
    }
}

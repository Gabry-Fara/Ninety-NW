import SwiftUI

struct TestModeView: View {
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color { .themeAccent(for: colorScheme) }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 24) {

                    // — Header info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MODEL TEST MODE")
                            .font(.caption.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        VStack(spacing: 12) {
                            infoRow("Model:", "modello25 (4 classi)")
                            infoRow("Dataset:", "test6.csv · 8830 epoche")
                            infoRow("Speed:", "0.5s/epoch · ~60× real-time")
                            infoRow("Trigger:", "Light sleep (N1/N2) confermato 2/3")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                    }

                    // — Live status (only when running)
                    if sleepManager.isTestModeRunning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RUNNING")
                                .font(.caption.bold())
                                .tracking(1)
                                .foregroundStyle(accent)
                                .padding(.leading, 4)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Progress")
                                        .bold()
                                    Spacer()
                                    Text(sleepManager.testModeProgress)
                                        .foregroundStyle(.secondary)
                                    ProgressView(value: progressFraction)
                                        .tint(accent)
                                        .frame(width: 60)
                                }
                                .font(.caption)

                                infoRow("Predicted (raw):", sleepManager.rawStageDisplay)
                                infoRow("Predicted (smoothed):", sleepManager.officialStageDisplay)
                                infoRow("Confirmation:", sleepManager.confirmationProgress)
                                infoRow("Last epoch:", sleepManager.latestFeatureSummary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                        }
                    }

                    // — Control buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTROLS")
                            .font(.caption.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        VStack(spacing: 10) {
                            if sleepManager.isTestModeRunning {
                                Button {
                                    sleepManager.stopTestMode()
                                } label: {
                                    Label("Stop Test", systemImage: "stop.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(.red)
                            } else {
                                Button {
                                    sleepManager.startTestMode()
                                } label: {
                                    Label("Start Test", systemImage: "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(accent)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                    }

                    // — Log stream
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LOG STREAM")
                                .font(.caption.bold())
                                .tracking(1)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !sleepManager.logs.isEmpty {
                                Text("\(sleepManager.logs.count) entries")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.leading, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            if sleepManager.logs.isEmpty {
                                Text("No logs yet. Press Start Test to begin.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                            } else {
                                // Show only test-mode logs (🧪 prefix) + last 5 lines for context
                                let testLogs = sleepManager.logs.filter {
                                    $0.contains("🧪") || $0.contains("✅") || $0.contains("❌")
                                }
                                ForEach(Array(testLogs.prefix(60).enumerated()), id: \.offset) { _, logMsg in
                                    logRow(logMsg)
                                }
                                if testLogs.count > 60 {
                                    Text("… \(testLogs.count - 60) older entries")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .background {
            HorizonBackground(isActive: sleepManager.isTestModeRunning)
                .ignoresSafeArea()
        }
        .navigationTitle("Test Mode")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
    }

    // MARK: - Helpers

    private var progressFraction: Double {
        guard let parts = parseProgress() else { return 0 }
        return Double(parts.current) / Double(parts.total)
    }

    private func parseProgress() -> (current: Int, total: Int)? {
        let components = sleepManager.testModeProgress.split(separator: "/")
        guard components.count == 2,
              let current = Int(components[0]),
              let total = Int(components[1]) else { return nil }
        return (current, total)
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).bold()
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    @ViewBuilder
    private func logRow(_ message: String) -> some View {
        let isCorrect = message.contains("✅")
        let isWrong   = message.contains("❌") && !message.contains("Confirmation failed") && !message.contains("csv")
        let isConfirmed = message.contains("CONFIRMED") || message.contains("ALARM")

        Text(message)
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundStyle(
                isConfirmed ? Color.green :
                isCorrect   ? Color.primary :
                isWrong     ? Color.orange  : Color.secondary
            )
            .padding(.bottom, 1)
        Divider()
    }
}

#Preview {
    NavigationStack {
        TestModeView()
    }
    .environmentObject(ScheduleViewModel())
}

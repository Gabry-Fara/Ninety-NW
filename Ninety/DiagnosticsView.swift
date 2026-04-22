import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @Environment(\.colorScheme) private var colorScheme
    
    private var accent: Color { .themeAccent(for: colorScheme) }
    
    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 24) {
                    diagnosticSection("Your Session".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Starts Tracking:".localized(for: appLanguage), viewModel.projectedSession.monitoringStartDate.formatted(date: .omitted, time: .shortened))
                            diagnosticRow("Wake-Up Alarm:".localized(for: appLanguage), viewModel.projectedSession.wakeUpDate.formatted(date: .omitted, time: .shortened))
                            diagnosticRow("Sleep Stage:".localized(for: appLanguage), sleepManager.officialStageDisplay)
                            diagnosticRow("Watch:".localized(for: appLanguage), viewModel.userFriendlyWatchStatus(from: sleepManager.watchStatus))
                        }
                    }

                    diagnosticSection("Status".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Alarm:".localized(for: appLanguage), viewModel.userFriendlyAlarmStatus(from: smartAlarm.alarmStatus))

                            if !smartAlarm.monitoringCountdown.isEmpty {
                                HStack {
                                    Text("Next tracking:")
                                        .bold()
                                    Spacer()
                                    Text(smartAlarm.monitoringCountdown)
                                        .foregroundStyle(accent)
                                        .monospacedDigit()
                                }
                                .font(.caption)
                            }
                            
                            if let scheduledSession = viewModel.lastScheduledSession {
                                diagnosticRow("Wake-up:".localized(for: appLanguage), scheduledSession.wakeUpDate.formatted(date: .abbreviated, time: .shortened))
                                diagnosticRow("Monitoring from:".localized(for: appLanguage), scheduledSession.monitoringStartDate.formatted(date: .omitted, time: .shortened))
                            }
                            
                            if let schedulingError = viewModel.schedulingError {
                                Text(schedulingError)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    diagnosticSection("Watch — Live Sensor Data".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Connection:".localized(for: appLanguage), sleepManager.watchConnectionStatus)
                            diagnosticRow("Watch status:".localized(for: appLanguage), sleepManager.watchStatus)
                            diagnosticRow("Last payload:".localized(for: appLanguage), sleepManager.lastPayloadReceived)
                            diagnosticRow("Current epoch:".localized(for: appLanguage), sleepManager.latestEpochSummary)

                            Divider()

                            diagnosticRow("ML Stage (raw):".localized(for: appLanguage), sleepManager.rawStageDisplay)
                            diagnosticRow("ML Stage (smoothed):".localized(for: appLanguage), sleepManager.officialStageDisplay)
                            diagnosticRow("Confirmation:".localized(for: appLanguage), sleepManager.confirmationProgress)
                            diagnosticRow("Model:".localized(for: appLanguage), sleepManager.modelStatus)

                            Text("Model requires 5 epochs (~2.5 min) to warm up before first prediction.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)

                            Button("Start Watch Session".localized(for: appLanguage)) {
                                sleepManager.startWatchSession()
                            }
                            .buttonStyle(GlassButtonStyle.glassProminent)
                            .tint(accent)
                            .padding(.top, 5)
                        }
                    }

                    diagnosticSection("🧪 Test Mode") {
                        VStack(spacing: 12) {
                            Text("Feeds pre-computed test data (test6.csv) directly to the ML model, bypassing Apple Watch. Each row = 1 epoch (30s).")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            if sleepManager.isTestModeRunning {
                                diagnosticRow("Progress:", sleepManager.testModeProgress)
                                diagnosticRow("Predicted:", sleepManager.officialStageDisplay)
                                diagnosticRow("Confirmation:", sleepManager.confirmationProgress)

                                Button("⏹ Stop Test Mode") {
                                    sleepManager.stopTestMode()
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(.red)
                            } else {
                                Button("▶️ Start Test Mode") {
                                    sleepManager.startTestMode()
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(.green)
                            }
                        }
                    }
                    
                    diagnosticSection("AlarmKit Constraints".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Status:".localized(for: appLanguage), smartAlarm.alarmStatus)
                            
                            VStack(spacing: 8) {
                                Button("Request System Permissions".localized(for: appLanguage)) {
                                    smartAlarm.requestPermissions { _ in }
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                
                                Button("Schedule Failsafe (In +30 min)".localized(for: appLanguage)) {
                                    let endOfWindow = Date().addingTimeInterval(30 * 60)
                                    smartAlarm.scheduleSystemAlarm(for: endOfWindow)
                                }
                                .buttonStyle(GlassButtonStyle.glass)
                                
                                Button("Test Dynamic Sub-Routine".localized(for: appLanguage)) {
                                    smartAlarm.triggerDynamicAlarm()
                                }
                                .buttonStyle(GlassButtonStyle.glass)
                                
                                Button("Alarm Trigger".localized(for: appLanguage)) {
                                    smartAlarm.triggerDynamicAlarm()
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(.red)
                            }
                            .padding(.top, 5)
                        }
                    }
                    
                    diagnosticSection("Log Stream".localized(for: appLanguage)) {
                        VStack(alignment: .leading, spacing: 8) {
                            if sleepManager.logs.isEmpty {
                                Text("No logs yet. Start session on Watch.".localized(for: appLanguage))
                                    .foregroundColor(.secondary)
                            } else {
                                let displayLogs = Array(sleepManager.logs.reversed().prefix(100))
                                ForEach(displayLogs, id: \.self) { logMsg in
                                    coloredLogRow(logMsg)
                                }
                                if sleepManager.logs.count > 100 {
                                    Text("… \(sleepManager.logs.count - 100) older entries")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    diagnosticSection("Clock Debug Logs".localized(for: appLanguage)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Copy Clock Logs to Clipboard".localized(for: appLanguage)) {
                                let logString = viewModel.clockLogs.joined(separator: "\n")
                                UIPasteboard.general.string = logString
                            }
                            .buttonStyle(GlassButtonStyle.glassProminent)
                            .padding(.bottom, 8)
                            
                            if viewModel.clockLogs.isEmpty {
                                Text("No clock logs yet.".localized(for: appLanguage))
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.clockLogs, id: \.self) { logMsg in
                                    Text(logMsg)
                                        .font(.system(size: 10, design: .monospaced))
                                        .padding(.bottom, 2)
                                    Divider()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .background {
            HorizonBackground(isActive: false)
                .ignoresSafeArea()
        }
        .navigationTitle("Diagnostics".localized(for: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
    }
    
    @ViewBuilder
    private func diagnosticSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        }
    }
    
    @ViewBuilder
    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .bold()
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }

    @ViewBuilder
    private func coloredLogRow(_ message: String) -> some View {
        let isWarning = message.contains("⚠️")
        let isError = message.contains("❌") || message.lowercased().contains("error") || message.lowercased().contains("failed")
        let isSuccess = message.contains("✅")
        let isConfirmed = message.contains("CONFIRMED") || message.contains("Triggering alarm")
        let isTracking = message.contains("🔍") || message.contains("Tracking")

        let textColor: Color = if isConfirmed {
            .green
        } else if isSuccess {
            .primary
        } else if isError {
            .red
        } else if isWarning {
            .orange
        } else if isTracking {
            .cyan
        } else {
            .secondary
        }

        Text(message)
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundStyle(textColor)
            .padding(.bottom, 1)
        Divider()
    }
}

#Preview {
    DiagnosticsView()
        .environmentObject(ScheduleViewModel())
}

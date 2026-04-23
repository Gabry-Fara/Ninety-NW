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
                            diagnosticRow("Session recovery:".localized(for: appLanguage), sleepManager.sessionRecoveryStatus)
                            diagnosticRow("Pipeline:".localized(for: appLanguage), sleepManager.sessionStateDisplay)
                            
                            if let scheduledSession = viewModel.lastScheduledSession {
                                diagnosticRow("Scheduled For:".localized(for: appLanguage), scheduledSession.wakeUpDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            
                            if let schedulingError = viewModel.schedulingError {
                                Text(schedulingError)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    diagnosticSection("Watch Connectivity".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Last Payload:".localized(for: appLanguage), sleepManager.lastPayloadReceived)
                            diagnosticRow("Watch Session:".localized(for: appLanguage), sleepManager.watchStatus)
                            diagnosticRow("Delivery:".localized(for: appLanguage), sleepManager.watchConnectionStatus)
                            if let queuedStart = sleepManager.watchQueuedStartDate {
                                diagnosticRow("Watch queued for:".localized(for: appLanguage), queuedStart.formatted(date: .abbreviated, time: .shortened))
                            }
                            if let armedStart = sleepManager.watchArmedStartDate {
                                diagnosticRow("Watch armed for:".localized(for: appLanguage), armedStart.formatted(date: .abbreviated, time: .shortened))
                            }
                            diagnosticRow("Pending on Watch:".localized(for: appLanguage), "\(sleepManager.watchPendingPayloadCount)")
                            diagnosticRow("Replay:".localized(for: appLanguage), sleepManager.replayStatus)
                            diagnosticRow("Ack:".localized(for: appLanguage), sleepManager.ackStatus)
                            
                            Text("Open Ninety on Apple Watch once before sleep to arm Smart Alarm. After that it starts automatically.".localized(for: appLanguage))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            Button("Start Session on Watch".localized(for: appLanguage)) {
                                sleepManager.log("UI Interaction: Button tapped -> Start Session on Watch")
                                sleepManager.startWatchSession()
                            }
                            .buttonStyle(GlassButtonStyle.glassProminent)
                            .tint(accent)
                            .padding(.top, 5)
                        }
                    }

                    diagnosticSection("Sleep Classifier".localized(for: appLanguage)) {
                        VStack(spacing: 10) {
                            diagnosticRow("Model:".localized(for: appLanguage), sleepManager.modelStatus)
                            diagnosticRow("Raw Stage:".localized(for: appLanguage), sleepManager.rawStageDisplay)
                            diagnosticRow("Official Stage:".localized(for: appLanguage), sleepManager.officialStageDisplay)
                            diagnosticRow("Epoch:".localized(for: appLanguage), sleepManager.latestEpochSummary)
                            diagnosticRow("Features:".localized(for: appLanguage), sleepManager.latestFeatureSummary)
                        }
                    }
                    
                    diagnosticSection("AlarmKit Constraints".localized(for: appLanguage)) {
                        VStack(spacing: 12) {
                            diagnosticRow("Status:".localized(for: appLanguage), smartAlarm.alarmStatus)
                            
                            VStack(spacing: 8) {
                                Button("Request System Permissions".localized(for: appLanguage)) {
                                    sleepManager.log("UI Interaction: Button tapped -> Request System Permissions")
                                    smartAlarm.requestPermissions { _ in }
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                
                                Button("Schedule Failsafe (In +30 min)".localized(for: appLanguage)) {
                                    sleepManager.log("UI Interaction: Button tapped -> Schedule Failsafe (+30 min)")
                                    let endOfWindow = Date().addingTimeInterval(30 * 60)
                                    smartAlarm.scheduleSystemAlarm(for: endOfWindow)
                                }
                                .buttonStyle(GlassButtonStyle.glass)
                                
                                Button("Test Dynamic Sub-Routine".localized(for: appLanguage)) {
                                    sleepManager.log("UI Interaction: Button tapped -> Test Dynamic Sub-Routine")
                                    smartAlarm.triggerDynamicAlarm()
                                }
                                .buttonStyle(GlassButtonStyle.glass)
                                
                                Button("Alarm Trigger".localized(for: appLanguage)) {
                                    sleepManager.log("UI Interaction: Button tapped -> Manual Alarm Trigger")
                                    smartAlarm.triggerDynamicAlarm()
                                }
                                .buttonStyle(GlassButtonStyle.glassProminent)
                                .tint(.red)
                            }
                            .padding(.top, 5)
                        }
                    }
                    
                    diagnosticSection("Log Stream".localized(for: appLanguage)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Clear Logs".localized(for: appLanguage)) {
                                sleepManager.clearLogs()
                            }
                            .buttonStyle(GlassButtonStyle.glass)
                            .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                if sleepManager.logs.isEmpty {
                                    Text("No logs yet. Start session on Watch.".localized(for: appLanguage))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(sleepManager.logs, id: \.self) { logMsg in
                                        Text(logMsg)
                                            .font(.system(size: 10, design: .monospaced))
                                            .padding(.bottom, 2)
                                        Divider()
                                    }
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
}

#Preview {
    DiagnosticsView()
        .environmentObject(ScheduleViewModel())
}

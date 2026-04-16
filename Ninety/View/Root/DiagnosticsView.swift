import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    
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
                            
                            Text("If the watch app is not foregrounded, the start request is queued and the user must open the watch app to arm Smart Alarm.".localized(for: appLanguage))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            Button("Start Session on Watch".localized(for: appLanguage)) {
                                sleepManager.startWatchSession()
                            }
                            .buttonStyle(GlassButtonStyle.glassProminent)
                            .tint(.blue)
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
                                ForEach(sleepManager.logs, id: \.self) { logMsg in
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

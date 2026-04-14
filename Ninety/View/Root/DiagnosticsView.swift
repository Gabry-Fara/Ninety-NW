import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Navigation Layer (Subtle for diagnostics)
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    GlassEffectContainer(spacing: 20) {
                        VStack(spacing: 24) {
                            diagnosticSection("Your Session") {
                                VStack(spacing: 12) {
                                    diagnosticRow("Starts Tracking:", viewModel.projectedSession.monitoringStartDate.formatted(date: .omitted, time: .shortened))
                                    diagnosticRow("Wake-Up Alarm:", viewModel.projectedSession.wakeUpDate.formatted(date: .omitted, time: .shortened))
                                    diagnosticRow("Sleep Stage:", sleepManager.officialStageDisplay)
                                    diagnosticRow("Watch:", viewModel.userFriendlyWatchStatus(from: sleepManager.watchStatus))
                                }
                            }

                            diagnosticSection("Status") {
                                VStack(spacing: 12) {
                                    diagnosticRow("Alarm:", viewModel.userFriendlyAlarmStatus(from: smartAlarm.alarmStatus))
                                    
                                    if let scheduledSession = viewModel.lastScheduledSession {
                                        diagnosticRow("Scheduled For:", scheduledSession.wakeUpDate.formatted(date: .abbreviated, time: .shortened))
                                    }
                                    
                                    if let schedulingError = viewModel.schedulingError {
                                        Text(schedulingError)
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                            
                            diagnosticSection("Watch Connectivity") {
                                VStack(spacing: 12) {
                                    diagnosticRow("Last Payload:", sleepManager.lastPayloadReceived)
                                    diagnosticRow("Watch Session:", sleepManager.watchStatus)
                                    diagnosticRow("Delivery:", sleepManager.watchConnectionStatus)
                                    
                                    Text("If the watch app is not foregrounded, the start request is queued and the user must open the watch app to arm Smart Alarm.")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                    
                                    Button("Start Session on Watch") {
                                        sleepManager.startWatchSession()
                                    }
                                    .buttonStyle(GlassButtonStyle.glassProminent)
                                    .tint(.blue)
                                    .padding(.top, 5)
                                }
                            }

                            diagnosticSection("Sleep Classifier") {
                                VStack(spacing: 10) {
                                    diagnosticRow("Model:", sleepManager.modelStatus)
                                    diagnosticRow("Raw Stage:", sleepManager.rawStageDisplay)
                                    diagnosticRow("Official Stage:", sleepManager.officialStageDisplay)
                                    diagnosticRow("Epoch:", sleepManager.latestEpochSummary)
                                    diagnosticRow("Features:", sleepManager.latestFeatureSummary)
                                }
                            }
                            
                            diagnosticSection("AlarmKit Constraints") {
                                VStack(spacing: 12) {
                                    diagnosticRow("Status:", smartAlarm.alarmStatus)
                                    
                                    VStack(spacing: 8) {
                                        Button("Request System Permissions") {
                                            smartAlarm.requestPermissions { _ in }
                                        }
                                        .buttonStyle(GlassButtonStyle.glassProminent)
                                        
                                        Button("Schedule Failsafe (In +30 min)") {
                                            let endOfWindow = Date().addingTimeInterval(30 * 60)
                                            smartAlarm.scheduleSystemAlarm(for: endOfWindow)
                                        }
                                        .buttonStyle(GlassButtonStyle.glass)
                                        
                                        Button("Test Dynamic Sub-Routine") {
                                            smartAlarm.triggerDynamicAlarm()
                                        }
                                        .buttonStyle(GlassButtonStyle.glass)
                                        
                                        Button("Alarm Trigger") {
                                            smartAlarm.triggerDynamicAlarm()
                                        }
                                        .buttonStyle(GlassButtonStyle.glassProminent)
                                        .tint(.red)
                                    }
                                    .padding(.top, 5)
                                }
                            }
                            
                            diagnosticSection("Log Stream") {
                                VStack(alignment: .leading, spacing: 8) {
                                    if sleepManager.logs.isEmpty {
                                        Text("No logs yet. Start session on Watch.")
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
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .containerBackground(.clear, for: .navigation)
        }
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

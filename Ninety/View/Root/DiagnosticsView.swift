import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox("Your Session") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Starts Tracking:")
                                    .bold()
                                Spacer()
                                Text(viewModel.projectedSession.monitoringStartDate.formatted(date: .omitted, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Wake-Up Alarm:")
                                    .bold()
                                Spacer()
                                Text(viewModel.projectedSession.wakeUpDate.formatted(date: .omitted, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Sleep Stage:")
                                    .bold()
                                Spacer()
                                Text(sleepManager.officialStageDisplay)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Watch:")
                                    .bold()
                                Spacer()
                                Text(viewModel.userFriendlyWatchStatus(from: sleepManager.watchStatus))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .font(.caption)
                    }

                    GroupBox("Status") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Alarm:")
                                    .bold()
                                Spacer()
                                Text(viewModel.userFriendlyAlarmStatus(from: smartAlarm.alarmStatus))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            if let scheduledSession = viewModel.lastScheduledSession {
                                HStack {
                                    Text("Scheduled For:")
                                        .bold()
                                    Spacer()
                                    Text(scheduledSession.wakeUpDate.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let schedulingError = viewModel.schedulingError {
                                Text(schedulingError)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        .font(.caption)
                    }
                    
                    GroupBox("Watch Connectivity") {
                        HStack {
                            Text("Last Payload:")
                                .bold()
                            Spacer()
                            Text(sleepManager.lastPayloadReceived)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)

                        HStack(alignment: .top) {
                            Text("Watch Session:")
                                .bold()
                            Spacer()
                            Text(sleepManager.watchStatus)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)

                        HStack(alignment: .top) {
                            Text("Delivery:")
                                .bold()
                            Spacer()
                            Text(sleepManager.watchConnectionStatus)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)

                        Text("If the watch app is not foregrounded, the start request is queued and the user must open the watch app to arm Smart Alarm.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        Button("Start Session on Watch") {
                            sleepManager.startWatchSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 5)
                    }

                    GroupBox("Sleep Stage Classifier") {
                        HStack(alignment: .top) {
                            Text("Model:")
                                .bold()
                            Spacer()
                            Text(sleepManager.modelStatus)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)

                        HStack {
                            Text("Raw Stage:")
                                .bold()
                            Spacer()
                            Text(sleepManager.rawStageDisplay)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)

                        HStack {
                            Text("Official Stage:")
                                .bold()
                            Spacer()
                            Text(sleepManager.officialStageDisplay)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)

                        HStack(alignment: .top) {
                            Text("Epoch:")
                                .bold()
                            Spacer()
                            Text(sleepManager.latestEpochSummary)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)

                        HStack(alignment: .top) {
                            Text("Features:")
                                .bold()
                            Spacer()
                            Text(sleepManager.latestFeatureSummary)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)
                    }
                    
                    GroupBox("AlarmKit Constraints") {
                        HStack {
                            Text("Status:")
                                .bold()
                            Spacer()
                            Text(smartAlarm.alarmStatus)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)
                        
                        Button("Request System Permissions") {
                            smartAlarm.requestPermissions { _ in }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 5)
                        
                        Button("Schedule Failsafe (In +30 min)") {
                            let endOfWindow = Date().addingTimeInterval(30 * 60)
                            smartAlarm.scheduleSystemAlarm(for: endOfWindow)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Test Dynamic Sub-Routine") {
                            smartAlarm.triggerDynamicAlarm()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Alarm Trigger") {
                            smartAlarm.triggerDynamicAlarm()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    
                    GroupBox("Classifier Log Stream") {
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
            .navigationTitle("Diagnostics")
        }
    }
}

#Preview {
    DiagnosticsView()
        .environmentObject(ScheduleViewModel())
}

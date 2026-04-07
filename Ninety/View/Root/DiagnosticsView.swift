import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    GroupBox("Watch Connectivity") {
                        HStack {
                            Text("Last Payload:")
                                .bold()
                            Spacer()
                            Text(sleepManager.lastPayloadReceived)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        
                        Button("Start Session on Watch") {
                            sleepManager.startWatchSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 5)
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
                        .tint(.red)
                    }
                    
                    GroupBox("Heuristic Log Stream") {
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

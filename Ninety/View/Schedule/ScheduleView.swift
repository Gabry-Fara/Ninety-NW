//
//  ScheduleView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
    @State private var showingWakeTimePicker = false
   
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Wake Up")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Button {
                            showingWakeTimePicker = true
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(viewModel.wakeTimeLabel)
                                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .minimumScaleFactor(0.8)

                                Text(viewModel.scheduledDayLabel)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Double tap to choose a wake-up time")

                        Text("Tap the time to change it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Ninety starts preparing 30 minutes before wake-up so your watch can look for the best moment to wake you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }

                Section("Your Session") {
                    LabeledContent("Starts Tracking") {
                        Text(viewModel.projectedSession.monitoringStartDate.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Wake-Up Alarm") {
                        Text(viewModel.projectedSession.wakeUpDate.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Sleep Stage") {
                        Text(sleepManager.officialStageDisplay)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Watch") {
                        Text(viewModel.userFriendlyWatchStatus(from: sleepManager.watchStatus))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Status") {
                    LabeledContent("Alarm") {
                        Text(viewModel.userFriendlyAlarmStatus(from: smartAlarm.alarmStatus))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    if let scheduledSession = viewModel.lastScheduledSession {
                        LabeledContent("Scheduled For") {
                            Text(scheduledSession.wakeUpDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let schedulingError = viewModel.schedulingError {
                        Text(schedulingError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    NavigationLink(destination: SleepChartView()) {
                        Label("Sleep Trends", systemImage: "chart.bar.xaxis")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Wake Up")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        
                        Divider()
                        
                        Button {
                            showingDiagnostics = true
                        } label: {
                            Label("Diagnostics", systemImage: "ladybug")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.body.weight(.medium))
                    }
                    .accessibilityLabel("More Options")
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDiagnostics) {
                NavigationStack {
                    DiagnosticsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingDiagnostics = false
                                }
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingWakeTimePicker) {
                NavigationStack {
                    Form {
                        Section {
                            DatePicker(
                                "Wake Up",
                                selection: $viewModel.wakeUpTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                        } footer: {
                            Text("Choose the time you want to wake up. Ninety will handle the rest.")
                        }
                    }
                    .navigationTitle("Wake Up")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingWakeTimePicker = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingWakeTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.scheduleSession()
                        }
                    } label: {
                        Group {
                            if viewModel.isScheduling {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Schedule Smart Alarm")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .font(.headline)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("You’ll be woken around \(viewModel.projectedSession.wakeUpDate.formatted(date: .omitted, time: .shortened)).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
            }
        }
    }
}

#Preview {
    ScheduleView()
}

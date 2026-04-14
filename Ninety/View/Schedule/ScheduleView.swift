//
//  ScheduleView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
    @State private var showingWakeTimePicker = false
   
    @Namespace private var glassNamespace
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Navigation Layer
                HorizonBackground(isActive: viewModel.isAlarmEnabled)
                    .ignoresSafeArea()
                
                GlassEffectContainer(spacing: 30) {
                    VStack {
                        // Keeps the pill optically centered 
                        Spacer()
                        
                        // Primary Wake Up Control (Minimalist Pill)
                        Button {
                            showingWakeTimePicker = true
                        } label: {
                            Text(viewModel.wakeTimeLabel)
                                .font(.system(size: 84, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .opacity(viewModel.isAlarmEnabled ? 1.0 : 0.4)
                                .contentTransition(.numericText())
                                .padding(.horizontal, 48)
                                .padding(.vertical, 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 64, style: .continuous))
                        
                        Spacer()
                    }
                    .padding(.bottom, 120) // Offsets the top toolbar to visually center on the physical screen
                }
                
                // Floating Bottom Action Pill
                VStack {
                    Spacer()
                    
                    Button {
                        viewModel.isAlarmEnabled.toggle()
                        if viewModel.isAlarmEnabled {
                            Task { await viewModel.scheduleSession() }
                        } else {
                            viewModel.cancelSession()
                        }
                    } label: {
                        Text(viewModel.isAlarmEnabled ? "Alarm On" : "Alarm Off")
                            .font(.headline)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isAlarmEnabled)
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: viewModel.isAlarmEnabled, tint: .blue))
                    .padding(.bottom, 24)
                }
            }
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
                            .foregroundStyle(.primary)
                            .font(.title2.weight(.medium))
                    }
                    .glassEffect(.regular.interactive(), in: Circle())
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
                    .scrollContentBackground(.hidden)
                    .containerBackground(.clear, for: .navigation)
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
        }
    }
}

#Preview {
    ScheduleView()
        .environmentObject(ScheduleViewModel())
}

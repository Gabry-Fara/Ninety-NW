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
    
    @State private var internalHour: Int = 0
    @State private var internalMinute: Int = 0
    
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
                        
                        if showingWakeTimePicker {
                            // Immersive Custom Picker
                            ZStack {
                                // Central Glass Pill Highlight
                                RoundedRectangle(cornerRadius: 48, style: .continuous)
                                    .fill(Color(white: 0.5).opacity(0.001)) // Transparent base to trigger glass hit-testing correctly
                                    .glassEffect(.regular)
                                    .frame(height: 96)
                                    .padding(.horizontal, 48)
                                
                                HStack(spacing: 12) {
                                    CustomWheelPicker(selectedValue: $internalHour, range: 0...23, isMinutes: false, isActive: viewModel.isAlarmEnabled)
                                        .frame(width: 100)
                                    
                                    Text(":")
                                        .font(.system(size: 64, weight: .light, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .opacity(viewModel.isAlarmEnabled ? 0.8 : 0.3)
                                        .offset(y: -4) // Optically align colon
                                    
                                    CustomWheelPicker(selectedValue: $internalMinute, range: 0...59, isMinutes: true, isActive: viewModel.isAlarmEnabled)
                                        .frame(width: 100)
                                }
                                .frame(height: 280)
                                .mask(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.25),
                                            .init(color: .black, location: 0.75),
                                            .init(color: .clear, location: 1)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .padding(.bottom, 120) // Offsets the top toolbar to visually center on the physical screen
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                        } else {
                            // Primary Wake Up Control (Minimalist Pill)
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    let calendar = Calendar.current
                                    internalHour = calendar.component(.hour, from: viewModel.wakeUpTime)
                                    internalMinute = calendar.component(.minute, from: viewModel.wakeUpTime)
                                    showingWakeTimePicker = true
                                }
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
                            .padding(.bottom, 120) // Offsets the top toolbar to visually center on the physical screen
                            .transition(.scale(scale: 1.1).combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
                
                // Floating Bottom Action Pill
                VStack {
                    Spacer()
                    
                    if showingWakeTimePicker {
                        Button {
                            var components = DateComponents()
                            components.hour = internalHour
                            components.minute = internalMinute
                            if let newDate = Calendar.current.date(from: components) {
                                viewModel.wakeUpTime = newDate
                            }
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showingWakeTimePicker = false
                            }
                        } label: {
                            Text("Select")
                                .font(.headline)
                                .padding(.horizontal, 48)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true, tint: .blue))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .toolbar {
                if showingWakeTimePicker {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showingWakeTimePicker = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .transition(.opacity)
                    }
                } else {
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
                        .transition(.opacity)
                    }
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
        }
    }
}

// MARK: - Custom Liquid Picker

struct CustomWheelPicker: View {
    @Binding var selectedValue: Int
    let range: ClosedRange<Int>
    let isMinutes: Bool
    let isActive: Bool
    
    @State private var viewPosition: Int?
    
    private var baseOpacity: Double { isActive ? 1.0 : 0.4 }
    private var blurOpacity: Double { isActive ? 0.3 : 0.1 }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(range, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 80, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .frame(height: 80)
                        .foregroundStyle(.primary)
                        .opacity(viewPosition == value ? baseOpacity : blurOpacity)
                        .scaleEffect(viewPosition == value ? 1.0 : 0.6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewPosition)
                        .id(value)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.vertical, 100)
        .scrollPosition(id: $viewPosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .onChange(of: viewPosition) { _, newValue in
            if let newValue = newValue {
                selectedValue = newValue
            }
        }
        .onAppear {
            viewPosition = selectedValue
        }
    }
}



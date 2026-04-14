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
                
                // Tap-to-dismiss: tapping empty space cancels picker without saving
                if showingWakeTimePicker {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Reset the picker back to the saved time to discard unsaved user interaction
                            let calendar = Calendar.current
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                internalHour = calendar.component(.hour, from: viewModel.wakeUpTime)
                                internalMinute = calendar.component(.minute, from: viewModel.wakeUpTime)
                                showingWakeTimePicker = false
                            }
                        }
                        .ignoresSafeArea()
                }
                
                // The pill is anchored by a fixed top spacer so it never shifts
                VStack(spacing: 0) {
                    Spacer().frame(height: 160)
                    
                    ZStack {
                        // Glass pill background — always fixed shape and size
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .fill(Color(white: 0.5).opacity(0.001))
                            .glassEffect(.regular.interactive().tint(viewModel.isAlarmEnabled ? .blue : .clear), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                            .glassEffectID("timePill", in: glassNamespace)
                            .frame(width: 286, height: 96)
                        
                        // Unified Content Layer — Always uses the Wheel Picker!
                        // It never switches views, so it logically CANNOT jump or shift.
                        // We simply fade out adjacent inactive numbers when not in picker mode.
                        HStack(spacing: 12) {
                            CustomWheelPicker(
                                selectedValue: $internalHour,
                                range: 0...23,
                                isMinutes: false,
                                isActive: viewModel.isAlarmEnabled,
                                isPickerMode: showingWakeTimePicker
                            )
                            .frame(width: 100)
                            
                            Text(":")
                                .font(.system(size: 64, weight: .light, design: .rounded))
                                .foregroundStyle(.primary)
                                .opacity(viewModel.isAlarmEnabled ? 0.8 : 0.3)
                                .offset(y: -4) // Match picker colon
                            
                            CustomWheelPicker(
                                selectedValue: $internalMinute,
                                range: 0...59,
                                isMinutes: true,
                                isActive: viewModel.isAlarmEnabled,
                                isPickerMode: showingWakeTimePicker
                            )
                            .frame(width: 100)
                        }
                        .frame(width: 286, height: 280)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.28),
                                    .init(color: .black, location: 0.72),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .disabled(!showingWakeTimePicker) // Lock scrolling when static
                    }
                    // IMPORTANT: always the same fixed height so Spacer below never shifts
                    .frame(width: 286, height: 280)
                    .contentShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .onTapGesture {
                        if !showingWakeTimePicker {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingWakeTimePicker = true
                            }
                        }
                    }
                    .onAppear {
                        let calendar = Calendar.current
                        internalHour = calendar.component(.hour, from: viewModel.wakeUpTime)
                        internalMinute = calendar.component(.minute, from: viewModel.wakeUpTime)
                    }
                    .onChange(of: viewModel.wakeUpTime) { _, newTime in
                        if !showingWakeTimePicker {
                            let calendar = Calendar.current
                            internalHour = calendar.component(.hour, from: newTime)
                            internalMinute = calendar.component(.minute, from: newTime)
                        }
                    }
                    
                    Spacer()
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
                if !showingWakeTimePicker {
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
                            Image(systemName: "slider.horizontal.3")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                                .font(.title2.weight(.medium))
                        }
                        .glassEffect(.regular.interactive(), in: Circle())
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
    let isPickerMode: Bool // True when active interacting, false just shows center
    
    @State private var viewPosition: Int?
    
    private var baseOpacity: Double { isActive ? 1.0 : 0.4 }
    private var blurOpacity: Double { isActive ? 0.3 : 0.1 }
    
    private var count: Int { range.upperBound - range.lowerBound + 1 }
    // A smaller multiplier keeps memory footprint lean while feeling functionally infinite
    private let multiplier: Int = 100
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Generate items
                ForEach(0..<(count * multiplier), id: \.self) { index in
                    // Calculate real time value (e.g., 0-23 or 0-59)
                    let value = range.lowerBound + (index % count)
                    
                    Text(String(format: "%02d", value))
                        .font(.system(size: 76, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .frame(height: 96)
                        .foregroundStyle(.primary)
                        // iOS 17 hardware-accelerated scroll transition: zero lag, bound directly to scroll physics!
                        .scrollTransition(axis: .vertical) { content, phase in
                            content
                                // Fade adjacent numbers completely transparent if we aren't in interacting mode
                                .opacity(phase.isIdentity ? baseOpacity : (isPickerMode ? blurOpacity : 0.0))
                                .scaleEffect(phase.isIdentity ? 1.0 : (isPickerMode ? 0.65 : 1.0))
                        }
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.vertical, 92) // Centers selected row within the 280pt parent height
        .scrollPosition(id: $viewPosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .onChange(of: viewPosition) { _, newValue in
            if let newValue = newValue {
                // Convert index back to actual time value
                selectedValue = range.lowerBound + (newValue % count)
            }
        }
        .onChange(of: selectedValue) { _, newSelected in
            // Allows external bindings (like tapping 'Alarm Off/On') to snap the wheel instantly
            if let currentPos = viewPosition {
                let currentShownValue = range.lowerBound + (currentPos % count)
                if currentShownValue != newSelected {
                    let midIndexOrigin = (multiplier / 2) * count
                    let offset = newSelected - range.lowerBound
                    viewPosition = midIndexOrigin + offset
                }
            }
        }
        .onAppear {
            // Start perfectly in the middle of our list to allow scrolling in both directions
            let midIndexOrigin = (multiplier / 2) * count
            let offset = selectedValue - range.lowerBound
            viewPosition = midIndexOrigin + offset
        }
    }
}



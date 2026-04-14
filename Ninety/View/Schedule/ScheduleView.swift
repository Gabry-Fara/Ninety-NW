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
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                        
                        // Content — crossfades, never moves
                        if showingWakeTimePicker {
                            HStack(spacing: 12) {
                                CustomWheelPicker(selectedValue: $internalHour, range: 0...23, isMinutes: false, isActive: viewModel.isAlarmEnabled)
                                    .frame(width: 100)
                                
                                Text(":")
                                    .font(.system(size: 64, weight: .light, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .opacity(viewModel.isAlarmEnabled ? 0.8 : 0.3)
                                    .offset(y: -4)
                                
                                CustomWheelPicker(selectedValue: $internalMinute, range: 0...59, isMinutes: true, isActive: viewModel.isAlarmEnabled)
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
                            .transition(.opacity)
                        } else {
                            Text(String(format: "%02d:%02d", Calendar.current.component(.hour, from: viewModel.wakeUpTime), Calendar.current.component(.minute, from: viewModel.wakeUpTime)))
                                .font(.system(size: 76, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(.primary)
                                .opacity(viewModel.isAlarmEnabled ? 1.0 : 0.4)
                                .contentTransition(.numericText())
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 286, height: 280)
                    .contentShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .onTapGesture {
                        if !showingWakeTimePicker {
                            let calendar = Calendar.current
                            internalHour = calendar.component(.hour, from: viewModel.wakeUpTime)
                            internalMinute = calendar.component(.minute, from: viewModel.wakeUpTime)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingWakeTimePicker = true
                            }
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
                            Image(systemName: "ellipsis.circle")
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
    
    @State private var viewPosition: Int?
    
    private var baseOpacity: Double { isActive ? 1.0 : 0.4 }
    private var blurOpacity: Double { isActive ? 0.3 : 0.1 }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(range, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 76, weight: .light, design: .rounded)) // Matches static label exactly
                        .monospacedDigit()
                        .frame(height: 96) // Match pill height so selected item sits on pill
                        .foregroundStyle(.primary)
                        .opacity(viewPosition == value ? baseOpacity : blurOpacity)
                        .scaleEffect(viewPosition == value ? 1.0 : 0.65)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewPosition)
                        .id(value)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.vertical, 92) // (280 - 96) / 2 = 92, centers selected row in pill
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



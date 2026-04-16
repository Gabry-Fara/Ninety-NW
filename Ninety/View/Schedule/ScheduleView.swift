//
//  ScheduleView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//
import SwiftUI
struct ScheduleView: View {
    private let timeBlockOffset: CGFloat = -130
    private let daySelectorOffset: CGFloat = 18

    @EnvironmentObject private var viewModel: ScheduleViewModel
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
    @State private var showingWakeTimePicker = false
    @Namespace private var glassNamespace
    @State private var internalHour: Int = 0
    @State private var internalMinute: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    private let impactHaptic = UIImpactFeedbackGenerator(style: .medium)
    private var accent: Color { .themeAccent(for: colorScheme) }
    var body: some View {
        NavigationStack {
            ZStack {
                HorizonBackground(isActive: viewModel.isAlarmEnabled)
                    .ignoresSafeArea()
                if showingWakeTimePicker {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            syncInternalTime()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingWakeTimePicker = false
                            }
                        }
                        .ignoresSafeArea()
                }
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    ZStack {
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .fill(Color(white: 0.5).opacity(0.001))
                            .glassEffect(.regular.interactive().tint(viewModel.isAlarmEnabled ? accent : .clear), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                            .glassEffectID("timePill", in: glassNamespace)
                            .frame(width: 286, height: 96)
                        HStack(spacing: 12) {
                            CustomWheelPicker(selectedValue: $internalHour, range: 0...23, isMinutes: false, isActive: true, isPickerMode: showingWakeTimePicker)
                                .frame(width: 100)
                            Text(":")
                                .font(.system(size: 64, weight: .light, design: .rounded))
                                .foregroundStyle(.primary)
                                .opacity(viewModel.isAlarmEnabled ? 0.8 : 0.3)
                                .offset(y: -4)
                            CustomWheelPicker(selectedValue: $internalMinute, range: 0...59, isMinutes: true, isActive: true, isPickerMode: showingWakeTimePicker)
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
                        .disabled(!showingWakeTimePicker)
                    }
                    .frame(width: 286, height: 280)
                    .offset(y: timeBlockOffset)
                    .overlay {
                        if !showingWakeTimePicker {
                            Color.clear
                                .contentShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showingWakeTimePicker = true
                                    }
                                }
                        }
                    }
                    .onAppear(perform: syncInternalTime)
                    .onChange(of: viewModel.selectedDayHour) { _, _ in
                        if !showingWakeTimePicker { syncInternalTime() }
                    }
                    .onChange(of: viewModel.selectedDayMinute) { _, _ in
                        if !showingWakeTimePicker { syncInternalTime() }
                    }
                    Spacer().frame(height: 40)
                    if viewModel.isAlarmEnabled && !showingWakeTimePicker {
                        Text("\("Next Up".localized(for: appLanguage)) · \(viewModel.nextUpcomingLabel)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                            .offset(y: daySelectorOffset)
                            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                    }
                    if !showingWakeTimePicker {
                        DayOfWeekSelector(scheduledWeekdays: viewModel.scheduledWeekdays, selectedWeekday: viewModel.selectedWeekday) { weekday in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedWeekday = weekday
                            }
                        }
                        .padding(.top, viewModel.isAlarmEnabled ? 12 : 28)
                        .offset(y: daySelectorOffset)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                    Spacer().frame(height: 60)
                }
                VStack {
                    Spacer()
                    if showingWakeTimePicker {
                        Button {
                            if hapticFeedbackEnabled { impactHaptic.impactOccurred() }
                            viewModel.updateWakeTime(hour: internalHour, minute: internalMinute)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showingWakeTimePicker = false
                            }
                        } label: {
                            Text("Select".localized(for: appLanguage))
                                .font(.headline)
                                .padding(.horizontal, 48)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: true, tint: accent))
                        .padding(.bottom, 24)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    } else {
                        Button {
                            if hapticFeedbackEnabled { impactHaptic.impactOccurred() }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.toggleSelectedDay()
                            }
                        } label: {
                            Text((viewModel.isAlarmEnabledForSelectedDay ? "Alarm On" : "Alarm Off").localized(for: appLanguage))
                                .font(.headline)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isAlarmEnabledForSelectedDay)
                        }
                        .buttonStyle(GlassButtonStyle(isProminent: viewModel.isAlarmEnabledForSelectedDay, tint: accent))
                        .disabled(viewModel.isScheduling)
                        .padding(.bottom, 24)
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
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
                                Label("Settings".localized(for: appLanguage), systemImage: "gearshape")
                            }
                            Divider()
                            Button {
                                showingDiagnostics = true
                            } label: {
                                Label("Diagnostics".localized(for: appLanguage), systemImage: "ladybug")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                                .font(.title2.weight(.medium))
                        }
                        .glassEffect(.regular.interactive(), in: Circle())
                    }
                }
            }
            .navigationTitle(showingWakeTimePicker ? "Set Wake Time".localized(for: appLanguage) : "Ninety".localized(for: appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDiagnostics) {
                NavigationStack {
                    DiagnosticsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done".localized(for: appLanguage)) {
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

    private func syncInternalTime() {
        internalHour = viewModel.selectedDayHour
        internalMinute = viewModel.selectedDayMinute
    }
}

private struct DayOfWeekSelector: View {
    let scheduledWeekdays: Set<Int>
    let selectedWeekday: Int
    let onSelect: (Int) -> Void
    
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selectionNamespace
    
    private var accent: Color { .themeAccent(for: colorScheme) }

    private struct WeekdayInfo: Identifiable {
        let id: Int // 1-indexed weekday (1=Sun, 2=Mon...)
        let symbol: String
    }

    private var orderedWeekdays: [WeekdayInfo] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: appLanguage)
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday // Usually 1 (Sun) or 2 (Mon)
        
        return (0..<7).map { i in
            let index = (firstWeekday - 1 + i) % 7
            return WeekdayInfo(id: index + 1, symbol: symbols[index])
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(orderedWeekdays) { day in
                let isScheduled = scheduledWeekdays.contains(day.id)
                let isSelected = selectedWeekday == day.id

                Button {
                    onSelect(day.id)
                } label: {
                    Text(day.symbol)
                        .font(.footnote.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(isScheduled ? Color.white : Color.primary.opacity(0.9))
                        .background {
                            ZStack {
                                // Base scheduled state (static)
                                Circle()
                                    .fill(isScheduled ? accent.opacity(0.25) : Color.white.opacity(0.08))
                                    .glassEffect(.regular.tint(isScheduled ? accent : .clear), in: Circle())
                                
                                // Liquid Glass Selector (slides between days)
                                if isSelected {
                                    Circle()
                                        .fill(Color.white.opacity(0.01)) // Invisible base for effect
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.primary.opacity(0.4), lineWidth: 1.5)
                                        )
                                        .glassEffect(.regular.interactive().tint(isScheduled ? accent : .clear), in: Circle())
                                        .matchedGeometryEffect(id: "daySelection", in: selectionNamespace)
                                }
                            }
                        }
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
    }
}

struct CustomWheelPicker: View {
    @Binding var selectedValue: Int
    let range: ClosedRange<Int>
    let isMinutes: Bool
    let isActive: Bool
    let isPickerMode: Bool
    
    @State private var viewPosition: Int?
    @State private var userDidScroll = false
    @State private var lastTickedPosition: Int?
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    private let selectionHaptic = UISelectionFeedbackGenerator()
    
    // Lower multiplier because we drop LazyVStack; 10 provides enough loops to feel infinite while maintaining perfect layout bounds
    private let multiplier = 10
    private var count: Int { range.upperBound - range.lowerBound + 1 }

    var body: some View {
        let baseOpacity = isActive ? 1.0 : 0.4
        let blurOpacity = isActive ? 0.3 : 0.1

        ScrollView(.vertical, showsIndicators: false) {
            // Using VStack instead of LazyVStack is the crucial fix! 
            // It pre-computes all boundaries instantaneously, meaning .scrollPosition programmatic jumps are flawlessly mathematically exact.
            VStack(spacing: 0) {
                ForEach(0..<(count * multiplier), id: \.self) { index in
                    let value = range.lowerBound + (index % count)

                    Text(String(format: "%02d", value))
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(height: 96)
                        .foregroundStyle(.primary)
                        .scrollTransition(axis: .vertical) { content, phase in
                            content
                                .opacity(phase.isIdentity ? baseOpacity : (isPickerMode ? blurOpacity : 0.0))
                                .scaleEffect(phase.isIdentity ? 1.0 : (isPickerMode ? 0.65 : 1.0))
                        }
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.vertical, 92)
        .scrollPosition(id: $viewPosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting {
                userDidScroll = true
                if hapticFeedbackEnabled { selectionHaptic.prepare() }
            } else if newPhase == .idle {
                if userDidScroll, let pos = viewPosition {
                    let newValue = range.lowerBound + (pos % count)
                    selectedValue = newValue
                    userDidScroll = false
                } else if let pos = viewPosition {
                    let currentShownValue = range.lowerBound + (pos % count)
                    if currentShownValue != selectedValue {
                        var diff = selectedValue - currentShownValue
                        let half = count / 2
                        if diff > half { diff -= count }
                        else if diff < -half { diff += count }
                        
                        DispatchQueue.main.async { viewPosition = pos + diff }
                    }
                }
            }
        }
        .onChange(of: selectedValue) { _, newSelected in
            if let currentPos = viewPosition {
                let currentShownValue = range.lowerBound + (currentPos % count)
                if currentShownValue != newSelected {
                    var diff = newSelected - currentShownValue
                    let half = count / 2
                    if diff > half { diff -= count }
                    else if diff < -half { diff += count }
                    
                    viewPosition = currentPos + diff
                }
            }
        }
        .onAppear {
            let midIndexOrigin = (multiplier / 2) * count
            let offset = selectedValue - range.lowerBound
            viewPosition = midIndexOrigin + offset
            lastTickedPosition = viewPosition
        }
        .onChange(of: viewPosition) { oldPos, newPos in
            guard userDidScroll, hapticFeedbackEnabled else { return }
            guard let old = oldPos, let new = newPos, old != new else { return }
            let oldValue = range.lowerBound + (old % count)
            let newValue = range.lowerBound + (new % count)
            if oldValue != newValue {
                selectionHaptic.selectionChanged()
                selectionHaptic.prepare()
            }
        }
    }
}

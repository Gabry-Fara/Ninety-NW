//
//  ScheduleView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//
import SwiftUI

struct ScheduleView: View {
    private enum WatchSetupState: Int {
        case needsAction = 1
        case ready = 2
        case active = 3
    }

    private struct WatchSetupSummary {
        let state: WatchSetupState
        let title: String
        let message: String
        let badge: String
        let symbol: String
        let tint: Color
    }

    private let timeBlockOffset: CGFloat = -60
    private let daySelectorOffset: CGFloat = 70
    private let alarmButtonBottomPadding: CGFloat = 64
    private let watchBannerSlotHeight: CGFloat = 190

    @EnvironmentObject private var viewModel: ScheduleViewModel
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var smartAlarm = SmartAlarmManager.shared
    @ObservedObject private var sleepManager = SleepSessionManager.shared
    @State private var showingSettings = false
    @State private var isSettingsNavigationPending = false
    @State private var showingDiagnostics = false
    @State private var showingWakeTimePicker = false
    @Namespace private var glassNamespace
    @State private var internalHour: Int = 0
    @State private var internalMinute: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showGuidedTour") private var showGuidedTour: Bool = false
    @State private var showingWatchDetails = false
    private let impactHaptic = UIImpactFeedbackGenerator(style: .medium)
    private var accent: Color { .scheduleAccent(for: colorScheme) }
    private var isSelectedDayActive: Bool { viewModel.isAlarmEnabledForSelectedDay }
    private var effectiveScheduledSession: SmartAlarmManager.ScheduledSleepSession? {
        viewModel.lastScheduledSession ?? viewModel.nextUpcomingSession
    }
    private var timePillTint: Color {
        guard isSelectedDayActive else { return .clear }
        return accent.opacity(colorScheme == .light ? 0.30 : 0.34)
    }
    private var watchSetupSummary: WatchSetupSummary? {
        guard viewModel.isAlarmEnabled, let scheduledSession = effectiveScheduledSession else {
            return nil
        }

        if sleepManager.isTrackingLive {
            return WatchSetupSummary(
                state: .active,
                title: "Tracking active on Apple Watch".localized(for: appLanguage),
                message: "The sleep window is running on Apple Watch now.".localized(for: appLanguage),
                badge: "Tracking in progress".localized(for: appLanguage),
                symbol: "waveform.path.ecg",
                tint: Color(red: 0.22, green: 0.72, blue: 0.55)
            )
        }

        if let readyStartDate = sleepManager.watchReadyStartDate {
            let formatted = readyStartDate.formatted(date: .omitted, time: .shortened)
            return WatchSetupSummary(
                state: .ready,
                title: "Smart Alarm ready".localized(for: appLanguage),
                message: String(
                    format: "Apple Watch will start sleep tracking at %@.".localized(for: appLanguage),
                    formatted
                ),
                badge: "Ready".localized(for: appLanguage),
                symbol: "checkmark.circle.fill",
                tint: Color(red: 0.18, green: 0.70, blue: 0.48)
            )
        }

        let pendingStartDate = sleepManager.watchQueuedStartDate ?? scheduledSession.monitoringStartDate
        let formatted = pendingStartDate.formatted(date: .omitted, time: .shortened)
        return WatchSetupSummary(
            state: .needsAction,
            title: "Open the Watch app to finish setting up".localized(for: appLanguage),
            message: String(
                format: "Open Ninety once on your Apple Watch before sleep. No extra tap is needed after that. Tracking starts at %@.".localized(for: appLanguage),
                formatted
            ),
            badge: "Open Watch".localized(for: appLanguage),
            symbol: "applewatch",
            tint: accent
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HorizonBackground(isActive: viewModel.isAlarmEnabled, accentOverride: accent)
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
                    Spacer().frame(height: 60)
                    ZStack {
                        if !showingWakeTimePicker {
                            Text("Wake up by".localized(for: appLanguage))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .opacity(0.8)
                                .offset(y: -70)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .fill(Color(white: 0.5).opacity(0.001))
                            .glassEffect(
                                .regular.interactive().tint(timePillTint),
                                in: RoundedRectangle(cornerRadius: 38, style: .continuous)
                            )
                            .glassEffectID("timePill", in: glassNamespace)
                            .frame(width: 286, height: 96)
                            .tourTarget(.clockPill)
                        if showingWakeTimePicker {
                            HStack(spacing: 12) {
                                CustomWheelPicker(
                                    selectedValue: $internalHour,
                                    range: 0...23,
                                    isMinutes: false,
                                    isActive: true,
                                    isPickerMode: true
                                )
                                    .frame(width: 100)
                                Text(":")
                                    .font(.system(size: 64, weight: .light, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .opacity(0.8)
                                    .offset(y: -4)
                                CustomWheelPicker(
                                    selectedValue: $internalMinute,
                                    range: 0...59,
                                    isMinutes: true,
                                    isActive: true,
                                    isPickerMode: true
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
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                        } else {
                            VStack(spacing: 0) {
                                IdleTimeDisplay(
                                    hour: internalHour,
                                    minute: internalMinute,
                                    isActive: isSelectedDayActive
                                )
                                
                                if let summary = watchSetupSummary, isSelectedDayActive {
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            showingWatchDetails.toggle()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(summary.tint)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(summary.badge)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.medium)
                                            
                                            Image(systemName: "chevron.up.circle.fill")
                                                .font(.caption2)
                                                .opacity(0.3)
                                                .rotationEffect(.degrees(showingWatchDetails ? 180 : 0))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background {
                                            Capsule()
                                                .fill(.ultraThinMaterial)
                                                .overlay {
                                                    Capsule()
                                                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                                }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, -80) // Pull it closer to the clock
                                }
                            }
                        }
                    }
                    .frame(width: 286, height: 280)
                    .disabled(showGuidedTour)
                    .offset(y: timeBlockOffset)
                    .overlay(alignment: .top) {
                        if !showingWakeTimePicker && !showGuidedTour {
                            Color.clear
                                .frame(width: 270, height: 130)
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
                        .allowsHitTesting(!showGuidedTour)
                        .tourTarget(.daySelector)
                        .padding(.top, viewModel.isAlarmEnabled ? 12 : 28)
                        .offset(y: daySelectorOffset)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                    Spacer().frame(height: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                // Watch status panel — floats in the empty space above the alarm button
                if viewModel.isAlarmEnabled && !showingWakeTimePicker && showingWatchDetails {
                    VStack(spacing: 0) {
                        Spacer()
                        if let summary = watchSetupSummary {
                            watchSetupBanner(summary)
                                .padding(.horizontal, 24)
                        }
                        Spacer().frame(height: alarmButtonBottomPadding + 230)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(true)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
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
                        .padding(.bottom, alarmButtonBottomPadding)
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
                        .disabled(viewModel.isScheduling || showGuidedTour)
                        .tourTarget(.alarmButton)
                        .padding(.bottom, alarmButtonBottomPadding)
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .allowsHitTesting(!showGuidedTour)
            .toolbar {
                if !showingWakeTimePicker && !showGuidedTour && !isSettingsNavigationPending {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                isSettingsNavigationPending = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isSettingsNavigationPending = false
                                    showingSettings = true
                                }
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
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
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
            .overlay {
                if showGuidedTour {
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.001))
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .onTapGesture {}

                        GuidedTourView(isPresented: $showGuidedTour)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private var watchSetupBannerSlot: some View {
        ZStack(alignment: .top) {
            Color.clear

            if let summary = watchSetupSummary {
                watchSetupBanner(summary)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: watchBannerSlotHeight, alignment: .top)
    }

    private func watchSetupBanner(_ summary: WatchSetupSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(summary.tint.opacity(colorScheme == .light ? 0.16 : 0.24))
                        .frame(width: 32, height: 32)

                    Image(systemName: summary.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(summary.tint)
                }

                Text(summary.title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .layoutPriority(1)

                Spacer(minLength: 0)
            }

            Text(summary.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            watchSetupProgressRow(for: summary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: 340, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(summary.tint.opacity(colorScheme == .light ? 0.14 : 0.18))
                        .frame(width: 120, height: 120)
                        .blur(radius: 28)
                        .offset(x: -20, y: -50)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(summary.tint.opacity(colorScheme == .light ? 0.22 : 0.30), lineWidth: 1)
        }
        .shadow(color: summary.tint.opacity(colorScheme == .light ? 0.10 : 0.15), radius: 20, y: 10)
    }

    private func watchSetupStatusPill(_ label: String, tint: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(colorScheme == .light ? 0.12 : 0.18))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(colorScheme == .light ? 0.18 : 0.26), lineWidth: 1)
            }
    }

    private func watchSetupProgressRow(for summary: WatchSetupSummary) -> some View {
        HStack(alignment: .top, spacing: 0) {
            watchSetupProgressNode(
                label: "Alarm saved".localized(for: appLanguage),
                symbol: "checkmark",
                style: .complete,
                tint: accent
            )
            watchSetupConnector(isActive: summary.state.rawValue >= WatchSetupState.ready.rawValue, tint: summary.tint)
            watchSetupProgressNode(
                label: "Open Watch".localized(for: appLanguage),
                symbol: summary.state == .needsAction ? "applewatch" : "checkmark",
                style: summary.state == .needsAction ? .current : .complete,
                tint: summary.state == .needsAction ? summary.tint : Color(red: 0.18, green: 0.70, blue: 0.48)
            )
            watchSetupConnector(isActive: summary.state == .active, tint: summary.tint)
            watchSetupProgressNode(
                label: "Tracking".localized(for: appLanguage),
                symbol: summary.state == .active ? "waveform.path.ecg" : "moon.zzz",
                style: summary.state == .active ? .complete : .upcoming,
                tint: summary.tint
            )
        }
    }

    private enum WatchProgressStyle {
        case complete
        case current
        case upcoming
    }

    private func watchSetupProgressNode(label: String, symbol: String, style: WatchProgressStyle, tint: Color) -> some View {
        let circleFill: Color
        let circleStroke: Color
        let iconColor: Color

        switch style {
        case .complete:
            circleFill = tint
            circleStroke = tint.opacity(0.0)
            iconColor = .white
        case .current:
            circleFill = tint.opacity(colorScheme == .light ? 0.14 : 0.20)
            circleStroke = tint.opacity(colorScheme == .light ? 0.30 : 0.36)
            iconColor = tint
        case .upcoming:
            circleFill = Color.white.opacity(colorScheme == .light ? 0.42 : 0.08)
            circleStroke = Color.primary.opacity(colorScheme == .light ? 0.08 : 0.16)
            iconColor = .secondary
        }

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 24, height: 24)
                Circle()
                    .strokeBorder(circleStroke, lineWidth: 1)
                    .frame(width: 24, height: 24)
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    private func watchSetupConnector(isActive: Bool, tint: Color) -> some View {
        Capsule(style: .continuous)
            .fill(isActive ? tint.opacity(0.55) : Color.primary.opacity(0.10))
            .frame(width: 18, height: 2)
            .padding(.top, 11)
    }

    private func syncInternalTime() {
        internalHour = viewModel.selectedDayHour
        internalMinute = viewModel.selectedDayMinute
    }
}

private struct IdleTimeDisplay: View {
    let hour: Int
    let minute: Int
    let isActive: Bool

    private var hourText: String { String(format: "%02d", hour) }
    private var minuteText: String { String(format: "%02d", minute) }

    var body: some View {
        HStack(spacing: 12) {
            Text(hourText)
                .font(.system(size: 72, weight: .light, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 100, height: 96)
                .foregroundStyle(.primary)
                .opacity(isActive ? 1.0 : 0.4)

            Text(":")
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundStyle(.primary)
                .opacity(isActive ? 0.8 : 0.3)
                .offset(y: -4)

            Text(minuteText)
                .font(.system(size: 72, weight: .light, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 100, height: 96)
                .foregroundStyle(.primary)
                .opacity(isActive ? 1.0 : 0.4)
        }
        .frame(width: 286, height: 280)
    }
}

private struct DayOfWeekSelector: View {
    let scheduledWeekdays: Set<Int>
    let selectedWeekday: Int
    let onSelect: (Int) -> Void
    
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @Environment(\.colorScheme) private var colorScheme
    
    private var accent: Color { .scheduleAccent(for: colorScheme) }

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
                            Circle()
                                .fill(isScheduled ? accent.opacity(0.25) : Color.white.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .strokeBorder(isSelected ? Color.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                )
                                .glassEffect(.regular.tint(isScheduled ? accent : .clear), in: Circle())
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        }
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
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    private let selectionHaptic = UISelectionFeedbackGenerator()
    
    // Keep enough repeated rows to feel infinite without paying for an oversized subtree on open.
    private let multiplier = 6
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

#Preview {
    ScheduleView()
        .environmentObject(ScheduleViewModel())
        .environmentObject(TourFrameStore())
}

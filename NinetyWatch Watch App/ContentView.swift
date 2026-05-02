//
//  ContentView.swift
//  NinetyWatch Watch App
//
//  Created by Cristian on 02/04/26.
//

import SwiftUI

private enum WatchCopyKey {
    case appName
    case nextAlarm
    case tapToChange
    case noActiveAlarms
    case setOnIPhone
    case today
    case tomorrow
    case monitoring
    case scheduled
    case waiting
    case attention
    case openWatchToSet
    case synced
    case queued
    case watchOnly
    case setAlarm
    case save
    case saved
    case syncPending
    case phoneUnavailable
    case syncFailed
    case syncing
}

private struct WatchCopy {
    let localeIdentifier: String

    private var normalizedIdentifier: String {
        localeIdentifier.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    private var languageCode: String {
        if normalizedIdentifier.hasPrefix("zh-hans") { return "zh-Hans" }
        if normalizedIdentifier.hasPrefix("ar") { return "ar" }
        if normalizedIdentifier.hasPrefix("it") { return "it" }
        if normalizedIdentifier.hasPrefix("es") { return "es" }
        return "en"
    }

    func text(_ key: WatchCopyKey) -> String {
        switch languageCode {
        case "it":
            switch key {
            case .appName: return "Ninety"
            case .nextAlarm: return "Prossima sveglia"
            case .tapToChange: return "Tocca per modificare"
            case .noActiveAlarms: return "Nessuna sveglia attiva"
            case .setOnIPhone: return "Imposta la prossima su iPhone"
            case .today: return "Oggi"
            case .tomorrow: return "Domani"
            case .monitoring: return "Monitoraggio attivo"
            case .scheduled: return "Sveglia programmata"
            case .waiting: return "In attesa della prossima sveglia"
            case .attention: return "Attenzione"
            case .openWatchToSet: return "Apri l'app su Watch per impostarla"
            case .synced: return "Sincronizzato"
            case .queued: return "Connesso"
            case .watchOnly: return "Solo Watch"
            case .setAlarm: return "Set Ninety Alarm"
            case .save: return "Salva"
            case .saved: return "Salvato"
            case .syncPending: return "Da sincronizzare"
            case .phoneUnavailable: return "iPhone non raggiungibile"
            case .syncFailed: return "Sync non riuscito"
            case .syncing: return "Sincronizzo"
            }
        case "es":
            switch key {
            case .appName: return "Ninety"
            case .nextAlarm: return "Próxima alarma"
            case .tapToChange: return "Toca para cambiar"
            case .noActiveAlarms: return "No hay alarmas activas"
            case .setOnIPhone: return "Configura la próxima en iPhone"
            case .today: return "Hoy"
            case .tomorrow: return "Mañana"
            case .monitoring: return "Seguimiento activo"
            case .scheduled: return "Alarma programada"
            case .waiting: return "Esperando la próxima alarma"
            case .attention: return "Atención"
            case .openWatchToSet: return "Abre la app en el Watch para configurarla"
            case .synced: return "Sincronizado"
            case .queued: return "Conectado"
            case .watchOnly: return "Solo Watch"
            case .setAlarm: return "Set Ninety Alarm"
            case .save: return "Guardar"
            case .saved: return "Guardado"
            case .syncPending: return "Por sincronizar"
            case .phoneUnavailable: return "iPhone no disponible"
            case .syncFailed: return "Sincronización fallida"
            case .syncing: return "Sincronizando"
            }
        case "zh-Hans":
            switch key {
            case .appName: return "Ninety"
            case .nextAlarm: return "下一个闹钟"
            case .tapToChange: return "点按修改"
            case .noActiveAlarms: return "没有已激活的闹钟"
            case .setOnIPhone: return "请在 iPhone 上设置下一次闹钟"
            case .today: return "今天"
            case .tomorrow: return "明天"
            case .monitoring: return "监测中"
            case .scheduled: return "闹钟已安排"
            case .waiting: return "等待下一次闹钟"
            case .attention: return "注意"
            case .openWatchToSet: return "打开 Watch App 以设置"
            case .synced: return "已同步"
            case .queued: return "已连接"
            case .watchOnly: return "仅 Watch"
            case .setAlarm: return "Set Ninety Alarm"
            case .save: return "保存"
            case .saved: return "已保存"
            case .syncPending: return "待同步"
            case .phoneUnavailable: return "iPhone 不可用"
            case .syncFailed: return "同步失败"
            case .syncing: return "正在同步"
            }
        case "ar":
            switch key {
            case .appName: return "Ninety"
            case .nextAlarm: return "المنبه التالي"
            case .tapToChange: return "اضغط للتعديل"
            case .noActiveAlarms: return "لا توجد منبهات نشطة"
            case .setOnIPhone: return "اضبط المنبه التالي على iPhone"
            case .today: return "اليوم"
            case .tomorrow: return "غدًا"
            case .monitoring: return "المراقبة نشطة"
            case .scheduled: return "المنبه مجدول"
            case .waiting: return "بانتظار المنبه التالي"
            case .attention: return "تنبيه"
            case .openWatchToSet: return "افتح التطبيق على الساعة لضبطه"
            case .synced: return "تمت المزامنة"
            case .queued: return "متصل"
            case .watchOnly: return "الساعة فقط"
            case .setAlarm: return "Set Ninety Alarm"
            case .save: return "حفظ"
            case .saved: return "تم الحفظ"
            case .syncPending: return "بانتظار المزامنة"
            case .phoneUnavailable: return "iPhone غير متاح"
            case .syncFailed: return "فشلت المزامنة"
            case .syncing: return "تتم المزامنة"
            }
        default:
            switch key {
            case .appName: return "Ninety"
            case .nextAlarm: return "Next alarm"
            case .tapToChange: return "Tap to change"
            case .noActiveAlarms: return "No active alarms"
            case .setOnIPhone: return "Set your next alarm on iPhone"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .monitoring: return "Monitoring active"
            case .scheduled: return "Alarm scheduled"
            case .waiting: return "Waiting for the next alarm"
            case .attention: return "Attention"
            case .openWatchToSet: return "Open the Watch app to set it"
            case .synced: return "Synced"
            case .queued: return "Connected"
            case .watchOnly: return "Watch only"
            case .setAlarm: return "Set Ninety Alarm"
            case .save: return "Save"
            case .saved: return "Saved"
            case .syncPending: return "Pending sync"
            case .phoneUnavailable: return "iPhone unavailable"
            case .syncFailed: return "Sync failed"
            case .syncing: return "Syncing"
            }
        }
    }
}

private enum WatchTimeField: Hashable {
    case hour, minute
}

struct ContentView: View {
    @StateObject private var sensorManager = WatchSensorManager.shared
    @StateObject private var hapticManager = HapticWakeUpManager.shared
    @State private var isEditingTime = false

    private var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WatchPageBackground()

                WatchAlarmSetupView(sensorManager: sensorManager, copy: copy, isEditingTime: $isEditingTime)
                
                if !isEditingTime {
                    VStack {
                        Spacer()
                        WatchStatusFooter(sensorManager: sensorManager)
                            .padding(.bottom, -2) // Subtle nudge to the absolute edge
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                
                if hapticManager.isPlaying {
                    AlarmView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .containerBackground(.black.gradient, for: .navigation)
            .onAppear {
                sensorManager.refreshStoredAlarmStateIfNeeded()
                sensorManager.requestHealthPermissions { _ in }
            }
        }
    }
}

private struct WatchStatusFooter: View {
    @ObservedObject var sensorManager: WatchSensorManager
    
    private var isSynced: Bool {
        sensorManager.connectionStatus.contains("reachable") || sensorManager.connectionStatus.contains("enabled")
    }
    
    private var statusText: String {
        if isSynced {
            return "Synced"
        } else if sensorManager.connectionStatus.contains("unavailable") {
            return "Phone Offline"
        } else {
            return "Connecting..."
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isSynced ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: (isSynced ? Color.green : Color.red).opacity(0.5), radius: 2)
            
            Text(statusText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(.white.opacity(0.04))
        }
    }
}

private struct WatchPageBackground: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}

// MARK: - Alarm Setup

private struct WatchAlarmSetupView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    let copy: WatchCopy

    @State private var wakeTime = WatchAlarmSetupView.defaultWakeTime()
    @State private var internalHour = 7
    @State private var internalMinute = 0
    @State private var isApplyingSyncedAlarm = false
    @State private var initialField: WatchTimeField = .hour
    @State private var idleCrownValue: Double = 0
    @Binding var isEditingTime: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            if isEditingTime {
                TimeWheelField(hour: $internalHour, minute: $internalMinute, initialFocus: initialField)
                    .padding(.bottom, 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                HStack(spacing: 8) {
                    Button {
                        cancelEditing()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .background {
                        Circle()
                        .fill(.white.opacity(0.12))
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
                            }
                    }
                    .foregroundStyle(.white.opacity(0.92))

                    Button {
                        updateWakeTimeFromInternal()
                        sensorManager.setNextAlarm(wakeTime: wakeTime)
                        withAnimation(.snappy(duration: 0.22)) {
                            isEditingTime = false
                        }
                    } label: {
                            HStack(spacing: 4) {
                                Image(systemName: buttonIconName)
                                Text(buttonTitle)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.blue) // Use a more consistent blue for the Watch
                    .disabled(sensorManager.weeklyAlarmSyncState == .saving)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            } else {
                Button {
                    initialField = .hour
                    withAnimation(.snappy(duration: 0.22)) {
                        isEditingTime = true
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(displayedAlarmDate == nil ? copy.text(.noActiveAlarms) : copy.text(.nextAlarm))
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(.blue.opacity(0.92))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .padding(.bottom, 2)

                        Text(timeText(for: displayedAlarmDate))
                            .font(.system(size: 44, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                                    }
                            }

                        Text(copy.text(.tapToChange))
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))

                        if let date = displayedAlarmDate {
                            Text(dateText(for: date))
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(copy.text(.setOnIPhone))
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundStyle(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
        .animation(.snappy(duration: 0.22), value: isEditingTime)
        .onAppear {
            applySyncedNextAlarm()
        }
        .onChange(of: internalHour) {
            guard !isApplyingSyncedAlarm else { return }
            sensorManager.markNextAlarmDraftChanged()
        }
        .onChange(of: internalMinute) {
            guard !isApplyingSyncedAlarm else { return }
            sensorManager.markNextAlarmDraftChanged()
        }
        .onChange(of: sensorManager.nextAlarmDate) {
            applySyncedNextAlarm()
        }
        // Crown rotation: rotating from the main screen (not editing) opens the picker.
        // Requires ≥3 low-sensitivity clicks to avoid accidental triggers.
        .focusable(!isEditingTime)
        .digitalCrownRotation(
            $idleCrownValue,
            from: -12,
            through: 12,
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: idleCrownValue) { _, newValue in
            guard !isEditingTime else {
                idleCrownValue = 0
                return
            }
            if abs(newValue) >= 3 {
                initialField = .hour
                withAnimation(.snappy(duration: 0.22)) {
                    isEditingTime = true
                }
                idleCrownValue = 0
            }
        }
        .onChange(of: isEditingTime) { _, editing in
            if editing { idleCrownValue = 0 }
        }
    }

    private var buttonTitle: String {
        switch sensorManager.weeklyAlarmSyncState {
        case .saving:
            return copy.text(.syncing)
        case .saved:
            return copy.text(.saved)
        case .pending:
            return copy.text(.syncPending)
        case .unreachable:
            return copy.text(.phoneUnavailable)
        case .failed:
            return copy.text(.syncFailed)
        case .synced:
            return copy.text(.save)
        }
    }

    private var buttonIconName: String {
        switch sensorManager.weeklyAlarmSyncState {
        case .saved, .synced:
            return "checkmark"
        case .saving:
            return "arrow.triangle.2.circlepath"
        case .pending:
            return "clock.arrow.circlepath"
        case .unreachable, .failed:
            return "exclamationmark.triangle"
        }
    }

    private var buttonTint: Color {
        switch sensorManager.weeklyAlarmSyncState {
        case .saved, .synced:
            return .green
        case .saving:
            return .blue
        case .pending:
            return .yellow
        case .unreachable, .failed:
            return .red
        }
    }

    private var displayedAlarmDate: Date? {
        switch sensorManager.weeklyAlarmSyncState {
        case .saving, .pending, .unreachable:
            return wakeTime
        case .synced, .saved, .failed:
            return sensorManager.nextAlarmDate
        }
    }

    private static func defaultWakeTime() -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }

    private func applySyncedNextAlarm() {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            if sensorManager.weeklyAlarmSyncState != .saving {
                withAnimation(.snappy(duration: 0.18)) {
                    isEditingTime = false
                }
            }
            return
        }

        let calendar = Calendar.autoupdatingCurrent
        let syncedHour = calendar.component(.hour, from: nextAlarmDate)
        let syncedMinute = calendar.component(.minute, from: nextAlarmDate)

        isApplyingSyncedAlarm = true
        
        let newDate = Self.todayDate(hour: syncedHour, minute: syncedMinute)
        withAnimation(.snappy(duration: 0.22)) {
            wakeTime = newDate
            internalHour = syncedHour
            internalMinute = syncedMinute
        }

        DispatchQueue.main.async {
            isApplyingSyncedAlarm = false
        }

        if sensorManager.weeklyAlarmSyncState != .saving {
            withAnimation(.snappy(duration: 0.18)) {
                isEditingTime = false
            }
        }
    }

    private func updateWakeTimeFromInternal() {
        wakeTime = Self.todayDate(hour: internalHour, minute: internalMinute)
    }

    private static func todayDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }

    private func cancelEditing() {
        applySyncedNextAlarm()
        withAnimation(.snappy(duration: 0.22)) {
            isEditingTime = false
        }
    }


    private func dateText(for date: Date) -> String {
        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
                .locale(Locale.autoupdatingCurrent)
        )
    }

    private func timeText(for date: Date?) -> String {
        guard let date else { return "--:--" }
        return date.formatted(
            Date.FormatStyle()
                .locale(Locale.autoupdatingCurrent)
                .hour()
                .minute()
        )
    }
}

private struct TimeWheelField: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let initialFocus: WatchTimeField

    @State private var focusedField: WatchTimeField
    @State private var crownValue: Double = 0

    init(hour: Binding<Int>, minute: Binding<Int>, initialFocus: WatchTimeField) {
        _hour = hour
        _minute = minute
        self.initialFocus = initialFocus
        _focusedField = State(initialValue: initialFocus)
    }

    private var selectedValue: Int {
        focusedField == .hour ? hour : minute
    }

    private var selectedRange: ClosedRange<Double> {
        focusedField == .hour ? 0...23 : 0...59
    }

    var body: some View {
        HStack(spacing: 8) {
            WatchCustomWheelPicker(selectedValue: $hour, range: 0...23, isFocused: focusedField == .hour) {
                focusedField = .hour
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = .hour
            }
            
            Text(":")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .opacity(0.5)
                .padding(.bottom, 2)

            WatchCustomWheelPicker(selectedValue: $minute, range: 0...59, isFocused: focusedField == .minute) {
                focusedField = .minute
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = .minute
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.8)
                }
        }
        .clipShape(Capsule())
        .onAppear {
            focusedField = initialFocus
            crownValue = Double(selectedValue)
        }
        .onChange(of: focusedField) { _, _ in
            crownValue = Double(selectedValue)
        }
        .onChange(of: hour) { _, newHour in
            guard focusedField == .hour else { return }
            crownValue = Double(newHour)
        }
        .onChange(of: minute) { _, newMinute in
            guard focusedField == .minute else { return }
            crownValue = Double(newMinute)
        }
        .onChange(of: crownValue) { _, newCrown in
            let rounded = Int(round(newCrown))
            switch focusedField {
            case .hour:
                if rounded != hour {
                    hour = rounded
                }
            case .minute:
                if rounded != minute {
                    minute = rounded
                }
            }
        }
        .focusable(true)
        .digitalCrownRotation(
            $crownValue,
            from: selectedRange.lowerBound,
            through: selectedRange.upperBound,
            by: 1,
            sensitivity: .low,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
    }
}

struct WatchCustomWheelPicker: View {
    @Binding var selectedValue: Int
    let range: ClosedRange<Int>
    var isFocused: Bool = false
    var onTap: (() -> Void)? = nil
    
    @State private var viewPosition: Int?
    @State private var userDidScroll = false
    
    private let multiplier = 3
    private var count: Int { range.upperBound - range.lowerBound + 1 }
    private let itemHeight: CGFloat = 34
    private let containerHeight: CGFloat = 100

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<(count * multiplier), id: \.self) { index in
                        let value = range.lowerBound + (index % count)

                        Text(String(format: "%02d", value))
                            .font(.system(size: 28, weight: isFocused ? .semibold : .light, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(height: itemHeight)
                            .foregroundStyle(isFocused ? Color.blue : Color.white.opacity(0.8))
                            .scrollTransition(axis: .vertical) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.55)
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                    .rotation3DEffect(
                                        .degrees(Double(phase.value) * -20),
                                        axis: (x: 1, y: 0, z: 0),
                                        perspective: 0.5
                                    )
                                    // Removed the offset that pushed items further away
                            }
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity)
                .scrollTargetLayout()
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }
            }
            .safeAreaPadding(.vertical, (containerHeight - itemHeight) / 2)
            .scrollPosition(id: $viewPosition, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .interacting {
                    userDidScroll = true
                } else if newPhase == .idle {
                    userDidScroll = false
                    if let pos = viewPosition {
                        let newValue = range.lowerBound + (pos % count)
                        if newValue != selectedValue {
                            selectedValue = newValue
                        }
                    }
                }
            }
            .onChange(of: viewPosition) { _, newPos in
                guard let new = newPos else { return }
                let newValue = range.lowerBound + (new % count)
                if userDidScroll && newValue != selectedValue {
                    selectedValue = newValue
                    WKInterfaceDevice.current().play(.click)
                }
            }
            .onChange(of: selectedValue) { _, newSelected in
                if !userDidScroll, let currentPos = viewPosition {
                    let currentShownValue = range.lowerBound + (currentPos % count)
                    if currentShownValue != newSelected {
                        var diff = newSelected - currentShownValue
                        let half = count / 2
                        if diff > half { diff -= count }
                        else if diff < -half { diff += count }
                        // Animate the scroll so the number rolls into place instead of jumping
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                            viewPosition = currentPos + diff
                        }
                    }
                }
            }
            .onAppear {
                let midIndexOrigin = (multiplier / 2) * count
                let offset = selectedValue - range.lowerBound
                viewPosition = midIndexOrigin + offset
            }
        }
        .frame(height: containerHeight)
    }
}

private struct SoftControlBackground: View {
    let cornerRadius: CGFloat
    var horizontalEdgesOnly = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color(red: 0.08, green: 0.13, blue: 0.24).opacity(0.22),
                        Color.white.opacity(0.018)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(edgeOverlay)
            .shadow(color: Color(red: 0.1, green: 0.18, blue: 0.35).opacity(0.08), radius: 10, x: 0, y: 0)
    }

    @ViewBuilder
    private var edgeOverlay: some View {
        if horizontalEdgesOnly {
            VStack(spacing: 0) {
                horizontalEdge
                Spacer(minLength: 0)
                horizontalEdge.opacity(0.55)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.blue.opacity(0.025),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.7
                )
        }
    }

    private var horizontalEdge: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.07),
                Color.white.opacity(0.07),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.7)
    }
}

// MARK: - Debug View

#if DEBUG
struct DebugNodeView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("🛠 Debug Node")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session: \(sensorManager.sessionState)")
                        .foregroundColor(.blue)
                    Text("Link: \(sensorManager.connectionStatus)")
                        .foregroundColor(.secondary)
                    
                    if sensorManager.hasPendingSchedule, let pending = sensorManager.pendingScheduleDescription {
                        Text("Queue: \(pending)")
                            .foregroundColor(.orange)
                    }

                    if sensorManager.hasReadySchedule, let ready = sensorManager.readyScheduleDescription {
                        Text("Ready: \(ready)")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption2)
                
                Divider()
                
                if !sensorManager.lastPayloadSent.isEmpty {
                    Text("Last Payload:")
                        .font(.caption2.bold())
                    Text(sensorManager.lastPayloadSent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Manual overrides for testing routing
                Group {
                    Button("Simulate Start (5s)") {
                        sensorManager.scheduleSmartAlarmSession(at: Date().addingTimeInterval(5))
                    }
                    .tint(.green)
                    
                    Button("Force Stop Session") {
                        sensorManager.stopSession()
                    }
                    .tint(.red)
                }
                .font(.caption)
            }
            .padding()
        }
    }
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

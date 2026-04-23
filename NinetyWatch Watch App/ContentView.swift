//
//  ContentView.swift
//  NinetyWatch Watch App
//
//  Created by Cristian on 02/04/26.
//

import SwiftUI
import WatchKit

private enum WatchScreenState {
    case idle
    case scheduled
    case active
    case error
}

private enum WatchCopyKey {
    case appName
    case wakeUpBy
    case noActiveAlarms
    case setOnIPhone
    case today
    case tomorrow
    case monitoring
    case scheduled
    case waiting
    case attention
    case openWatchToArm
    case synced
    case queued
    case watchOnly
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
            case .wakeUpBy: return "Sveglia entro"
            case .noActiveAlarms: return "Nessuna sveglia attiva"
            case .setOnIPhone: return "Imposta la prossima su iPhone"
            case .today: return "Oggi"
            case .tomorrow: return "Domani"
            case .monitoring: return "Monitoraggio attivo"
            case .scheduled: return "Sveglia programmata"
            case .waiting: return "In attesa della prossima sveglia"
            case .attention: return "Attenzione"
            case .openWatchToArm: return "Apri l'app su Watch per attivarla"
            case .synced: return "Sincronizzato"
            case .queued: return "Connesso"
            case .watchOnly: return "Solo Watch"
            }
        case "es":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "Despertar antes de"
            case .noActiveAlarms: return "No hay alarmas activas"
            case .setOnIPhone: return "Configura la próxima en iPhone"
            case .today: return "Hoy"
            case .tomorrow: return "Mañana"
            case .monitoring: return "Seguimiento activo"
            case .scheduled: return "Alarma programada"
            case .waiting: return "Esperando la próxima alarma"
            case .attention: return "Atención"
            case .openWatchToArm: return "Abre la app en el Watch para activarla"
            case .synced: return "Sincronizado"
            case .queued: return "Conectado"
            case .watchOnly: return "Solo Watch"
            }
        case "zh-Hans":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "最晚唤醒时间"
            case .noActiveAlarms: return "没有已激活的闹钟"
            case .setOnIPhone: return "请在 iPhone 上设置下一次闹钟"
            case .today: return "今天"
            case .tomorrow: return "明天"
            case .monitoring: return "监测中"
            case .scheduled: return "闹钟已安排"
            case .waiting: return "等待下一次闹钟"
            case .attention: return "注意"
            case .openWatchToArm: return "打开 Watch App 以激活"
            case .synced: return "已同步"
            case .queued: return "已连接"
            case .watchOnly: return "仅 Watch"
            }
        case "ar":
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "الاستيقاظ قبل"
            case .noActiveAlarms: return "لا توجد منبهات نشطة"
            case .setOnIPhone: return "اضبط المنبه التالي على iPhone"
            case .today: return "اليوم"
            case .tomorrow: return "غدًا"
            case .monitoring: return "المراقبة نشطة"
            case .scheduled: return "المنبه مجدول"
            case .waiting: return "بانتظار المنبه التالي"
            case .attention: return "تنبيه"
            case .openWatchToArm: return "افتح التطبيق على الساعة لتفعيله"
            case .synced: return "تمت المزامنة"
            case .queued: return "متصل"
            case .watchOnly: return "الساعة فقط"
            }
        default:
            switch key {
            case .appName: return "Ninety"
            case .wakeUpBy: return "Wake up by"
            case .noActiveAlarms: return "No active alarms"
            case .setOnIPhone: return "Set your next alarm on iPhone"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .monitoring: return "Monitoring active"
            case .scheduled: return "Alarm scheduled"
            case .waiting: return "Waiting for the next alarm"
            case .attention: return "Attention"
            case .openWatchToArm: return "Open the Watch app to arm it"
            case .synced: return "Synced"
            case .queued: return "Connected"
            case .watchOnly: return "Watch only"
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var sensorManager = WatchSensorManager.shared
    @StateObject private var hapticManager = HapticWakeUpManager.shared

    private var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }

    private var currentState: WatchScreenState {
        let state = sensorManager.sessionState.lowercased()

        if state.contains("error") || state.contains("invalidated") {
            return .error
        }

        if state.contains("started") || state.contains("active") || state.contains("monitoring") || state.contains("avviata") {
            return .active
        }

        if sensorManager.nextAlarmDate != nil || sensorManager.hasPendingSchedule {
            return .scheduled
        }

        return .idle
    }

    var body: some View {
        ZStack {
            TabView {
                // Tab 1: Main Status UI
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        nextAlarmCard
                        footerStatus
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                
                // Tab 2: Debug Node
                DebugNodeView(sensorManager: sensorManager)
            }
            .tabViewStyle(.verticalPage)
            .background(Color.black.ignoresSafeArea())
            
            if hapticManager.isPlaying {
                AlarmView()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .onAppear {
            sensorManager.refreshStoredAlarmStateIfNeeded()
            sensorManager.requestHealthPermissions { _ in }
        }
    }

    private var header: some View {
        HStack {
            Text(copy.text(.appName))
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    private var nextAlarmCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(copy.text(.wakeUpBy))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(nextAlarmPrimaryText)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            if let secondaryText = nextAlarmSecondaryText {
                Text(secondaryText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var footerStatus: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(footerStatusColor)
                .frame(width: 6, height: 6)

            Text(footerStatusLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }

    private var nextAlarmPrimaryText: String {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            return copy.text(.noActiveAlarms)
        }

        return formattedAlarm(date: nextAlarmDate).primary
    }

    private var nextAlarmSecondaryText: String? {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            return sensorManager.hasPendingSchedule ? copy.text(.openWatchToArm) : copy.text(.setOnIPhone)
        }

        let formatted = formattedAlarm(date: nextAlarmDate)

        switch currentState {
        case .active:
            return copy.text(.monitoring)
        case .scheduled:
            return formatted.secondary
        case .error:
            return sensorManager.sessionState
        case .idle:
            return copy.text(.waiting)
        }
    }

    private func formattedAlarm(date: Date) -> (primary: String, secondary: String?) {
        let calendar = Calendar.autoupdatingCurrent
        let locale = Locale.autoupdatingCurrent
        let time = date.formatted(Date.FormatStyle().locale(locale).hour().minute())

        if calendar.isDateInToday(date) {
            return ("\(copy.text(.today)) · \(time)", nil)
        }

        if calendar.isDateInTomorrow(date) {
            return ("\(copy.text(.tomorrow)) · \(time)", nil)
        }

        let dayFormatter = Date.FormatStyle()
            .locale(locale)
            .weekday(.abbreviated)
            .day()
            .month()

        return (time, date.formatted(dayFormatter))
    }

    private var footerStatusLabel: String {
        switch sensorManager.connectivityState {
        case .synced:
            return copy.text(.synced)
        case .queued:
            return copy.text(.queued)
        case .watchOnly:
            return copy.text(.watchOnly)
        }
    }

    private var footerStatusColor: Color {
        switch sensorManager.connectivityState {
        case .synced:
            return .green
        case .queued:
            return .yellow
        case .watchOnly:
            return .orange
        }
    }
}

// MARK: - Debug View

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

#Preview {
    ContentView()
}

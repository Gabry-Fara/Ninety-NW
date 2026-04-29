//
//  ContentView.swift
//  NinetyWatch Watch App
//
//  Created by Cristian on 02/04/26.
//

import SwiftUI

private enum WatchCopyKey {
    case appName
    case wakeUpBy
    case recordActivity
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
            case .wakeUpBy: return "Sveglia entro"
            case .recordActivity: return "Registra attività"
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
            case .wakeUpBy: return "Despertar antes de"
            case .recordActivity: return "Registrar actividad"
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
            case .wakeUpBy: return "最晚唤醒时间"
            case .recordActivity: return "记录活动"
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
            case .wakeUpBy: return "الاستيقاظ قبل"
            case .recordActivity: return "تسجيل النشاط"
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
            case .wakeUpBy: return "Wake up by"
            case .recordActivity: return "Record activity"
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

struct ContentView: View {
    @StateObject private var sensorManager = WatchSensorManager.shared
    @StateObject private var hapticManager = HapticWakeUpManager.shared

    private var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }

    var body: some View {
        ZStack {
            WatchPageBackground()

            WatchAlarmSetupView(sensorManager: sensorManager, copy: copy)
            
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
}

private struct WatchPageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.035, green: 0.055, blue: 0.105),
                Color(red: 0.055, green: 0.09, blue: 0.16),
                Color(red: 0.018, green: 0.03, blue: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Alarm Setup

private struct WatchAlarmSetupView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    let copy: WatchCopy

    @State private var wakeTime = WatchAlarmSetupView.defaultWakeTime()
    @State private var isApplyingSyncedAlarm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                if let headerEyebrow {
                    Text(headerEyebrow)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Text(headerTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            TimeWheelField(wakeTime: $wakeTime)

            Button {
                sensorManager.setNextAlarm(wakeTime: wakeTime)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: buttonIconName)
                    Text(buttonTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(buttonTint)
            .disabled(sensorManager.weeklyAlarmSyncState == .saving)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .onAppear {
            applySyncedNextAlarm()
        }
        .onChange(of: wakeTime) {
            guard !isApplyingSyncedAlarm else { return }
            sensorManager.markNextAlarmDraftChanged()
        }
        .onChange(of: sensorManager.nextAlarmDate) {
            applySyncedNextAlarm()
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

    private var headerTitle: String {
        guard
            let nextAlarmDate = sensorManager.nextAlarmDate,
            nextAlarmDate > Date(),
            nextAlarmDate.timeIntervalSinceNow <= 24 * 60 * 60
        else {
            return copy.text(.setAlarm)
        }

        let activityDate = nextAlarmDate.addingTimeInterval(-30 * 60)
        let weekday = nextAlarmDate.formatted(
            .dateTime
                .weekday(.wide)
                .locale(Locale.autoupdatingCurrent)
        )
        .capitalized(with: Locale.autoupdatingCurrent)
        let activityTime = activityDate.formatted(
            Date.FormatStyle()
                .locale(Locale.autoupdatingCurrent)
                .hour()
                .minute()
        )

        return "\(weekday) · \(activityTime)"
    }

    private var headerEyebrow: String? {
        guard
            let nextAlarmDate = sensorManager.nextAlarmDate,
            nextAlarmDate > Date(),
            nextAlarmDate.timeIntervalSinceNow <= 24 * 60 * 60
        else {
            return nil
        }

        return copy.text(.recordActivity)
    }

    private static func defaultWakeTime() -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }

    private func applySyncedNextAlarm() {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else { return }

        let calendar = Calendar.autoupdatingCurrent
        let syncedHour = calendar.component(.hour, from: nextAlarmDate)
        let syncedMinute = calendar.component(.minute, from: nextAlarmDate)

        isApplyingSyncedAlarm = true

        withAnimation(.snappy(duration: 0.22)) {
            wakeTime = Self.todayDate(hour: syncedHour, minute: syncedMinute)
        }

        DispatchQueue.main.async {
            isApplyingSyncedAlarm = false
        }
    }

    private static func todayDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }
}

private struct TimeWheelField: View {
    @Binding var wakeTime: Date

    var body: some View {
        ZStack {
            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .focusable(false)
                .frame(height: 80)
                .offset(y: -2)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black.opacity(0.7), location: 0.18),
                            .init(color: .black, location: 0.42),
                            .init(color: .black, location: 0.58),
                            .init(color: .black.opacity(0.7), location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 80)
        .background(SoftControlBackground(cornerRadius: 16))
        .overlay(alignment: .top) {
            edgeFade
        }
        .overlay(alignment: .bottom) {
            edgeFade.rotationEffect(.degrees(180))
        }
        .clipped()
    }

    private var edgeFade: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.3),
                Color.black.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 20)
        .allowsHitTesting(false)
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

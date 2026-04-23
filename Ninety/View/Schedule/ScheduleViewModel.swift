import Foundation
import SwiftUI

@MainActor
final class ScheduleViewModel: ObservableObject {
    private enum StorageKey {
        static let wakeTime = "scheduleWakeTimeInterval"
        static let wakeTimesDict = "scheduleWakeTimesDict"
        static let scheduledWeekdays = "scheduleWeekdayPlan"
    }

    @Published var wakeTimes: [String: TimeInterval] {
        didSet {
            UserDefaults.standard.set(wakeTimes, forKey: StorageKey.wakeTimesDict)
        }
    }
    
    @Published var selectedWeekday: Int = Calendar.current.component(.weekday, from: Date()) {
        didSet {
            logClock("selectedWeekday DID SET to: \(selectedWeekday)")
            updateCurrentWakeUpTime()
        }
    }
    
    @Published var currentWakeUpTime: Date
    @Published var scheduledWeekdays: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(scheduledWeekdays).sorted(), forKey: StorageKey.scheduledWeekdays)
        }
    }
    @Published var lastScheduledSession: SmartAlarmManager.ScheduledSleepSession?
    @Published var isScheduling = false
    @Published var schedulingError: String?
    @Published var selectedDayHour: Int = 7
    @Published var selectedDayMinute: Int = 0
    @Published var clockLogs: [String] = []
    
    func logClock(_ msg: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let fullMsg = "[\(timeString)] \(msg)"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.clockLogs.append(fullMsg)
            if self.clockLogs.count > 100 {
                self.clockLogs.removeFirst(self.clockLogs.count - 100)
            }
            print(fullMsg)
        }
    }

    init() {
        let storedWakeTimes = UserDefaults.standard.dictionary(forKey: StorageKey.wakeTimesDict) as? [String: TimeInterval] ?? [:]
        
        // Backward compatibility: migrate old single time stored as timeIntervalSince1970
        var initialWakeTimes = storedWakeTimes
        if initialWakeTimes.isEmpty {
            if let oldStored = UserDefaults.standard.object(forKey: StorageKey.wakeTime) as? TimeInterval {
                // Convert legacy timeIntervalSince1970 to seconds-since-midnight
                let legacyDate = Date(timeIntervalSince1970: oldStored)
                let cal = Calendar.current
                let h = cal.component(.hour, from: legacyDate)
                let m = cal.component(.minute, from: legacyDate)
                let midnightOffset = TimeInterval(h * 3600 + m * 60)
                for i in 1...7 { initialWakeTimes[String(i)] = midnightOffset }
            }
        } else {
            // One-time migration: convert any legacy timestamps to seconds-since-midnight.
            // Legacy timestamps are either very large (> 86400) or negative.
            var migrated = false
            let migrationCal = Calendar(identifier: .gregorian)
            for (key, value) in initialWakeTimes {
                if value > 86400 || value < 0 {
                    let legacyDate = Date(timeIntervalSince1970: value)
                    let h = migrationCal.component(.hour, from: legacyDate)
                    let m = migrationCal.component(.minute, from: legacyDate)
                    // Ensure we don't carry over corrupted sub-minute precision
                    initialWakeTimes[key] = TimeInterval(h * 3600 + m * 60)
                    migrated = true
                }
            }
            if migrated {
                UserDefaults.standard.set(initialWakeTimes, forKey: StorageKey.wakeTimesDict)
            }
        }
        wakeTimes = initialWakeTimes
        
        currentWakeUpTime = ScheduleViewModel.defaultWakeTime

        let storedWeekdays = UserDefaults.standard.array(forKey: StorageKey.scheduledWeekdays) as? [Int] ?? []
        scheduledWeekdays = Set(storedWeekdays)
        lastScheduledSession = nil
        logClock("INIT ViewModel finished.")
        updateCurrentWakeUpTime()
        lastScheduledSession = nextUpcomingSession
    }

    static var defaultWakeTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? .now
    }

    var isAlarmEnabled: Bool {
        !scheduledWeekdays.isEmpty
    }

    var isAlarmEnabledForSelectedDay: Bool {
        scheduledWeekdays.contains(selectedWeekday)
    }

    var projectedSession: SmartAlarmManager.ScheduledSleepSession {
        nextUpcomingSession ?? fallbackProjectedSession
    }

    var nextUpcomingSession: SmartAlarmManager.ScheduledSleepSession? {
        guard let nextWakeUpDate = nextUpcomingWakeUpDate else {
            return nil
        }
        return makeSession(for: nextWakeUpDate)
    }

    var wakeTimeLabel: String {
        currentWakeUpTime.formatted(date: .omitted, time: .shortened)
    }

    var scheduledDayLabel: String {
        let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        guard let wakeUpDate = nextUpcomingSession?.wakeUpDate else {
            return "Pick your days".localized(for: preferredLang)
        }
        if Calendar.current.isDateInToday(wakeUpDate) {
            return "Today".localized(for: preferredLang)
        }
        if Calendar.current.isDateInTomorrow(wakeUpDate) {
            return "Tomorrow".localized(for: preferredLang)
        }
        let locale = Locale(identifier: preferredLang)
        return wakeUpDate.formatted(.dateTime.weekday(.wide).locale(locale))
    }

    var nextUpcomingLabel: String {
        let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        guard let session = nextUpcomingSession else {
            return "No days selected".localized(for: preferredLang)
        }
        let locale = Locale(identifier: preferredLang)
        let day = session.wakeUpDate.formatted(.dateTime.weekday(.abbreviated).locale(locale))
        let time = session.wakeUpDate.formatted(Date.FormatStyle().locale(locale).hour().minute())
        return "\(day) · \(time)"
    }

    var primaryButtonTitle: String {
        let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        guard !isScheduling else {
            return "Updating Plan...".localized(for: preferredLang)
        }
        guard nextUpcomingSession != nil else {
            return "Choose Days to Plan".localized(for: preferredLang)
        }
        return "\("Next Up".localized(for: preferredLang)) · \(nextUpcomingLabel)"
    }

    func scheduleSession() async {
        guard !isScheduling else { return }
        guard let nextUpcomingSession else {
            await SmartAlarmManager.shared.cancelSessionNow()
            lastScheduledSession = nil
            schedulingError = nil
            return
        }

        isScheduling = true
        schedulingError = nil
        defer { isScheduling = false }

        let granted = await requestAlarmPermissions()
        guard granted else {
            let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            schedulingError = "Permissions are required to schedule your weekly wake-up plan.".localized(for: preferredLang)
            return
        }

        await SmartAlarmManager.shared.rescheduleSystemAlarm(for: nextUpcomingSession.wakeUpDate)
        lastScheduledSession = nextUpcomingSession
    }

    func cancelSession() {
        SleepSessionManager.shared.log("UI Interaction: Cancelled system scheduled session")
        SmartAlarmManager.shared.cancelSession()
        lastScheduledSession = nil
    }

    func toggleScheduledWeekday(_ weekday: Int) {
        if scheduledWeekdays.contains(weekday) {
            scheduledWeekdays.remove(weekday)
        } else {
            scheduledWeekdays.insert(weekday)
        }

        lastScheduledSession = nextUpcomingSession

        SleepSessionManager.shared.log("UI Interaction: Toggled alarm for weekday \(weekday). Active: \(scheduledWeekdays.contains(weekday))")

        Task {
            if scheduledWeekdays.isEmpty {
                cancelSession()
            } else {
                await scheduleSession()
            }
        }
    }
    
    func toggleSelectedDay() {
        toggleScheduledWeekday(selectedWeekday)
    }

    func updateWakeTime(hour: Int, minute: Int) {
        logClock("updateWakeTime CALLED with \(hour):\(minute) for weekday \(selectedWeekday)")
        let key = String(selectedWeekday)
        wakeTimes[key] = TimeInterval(hour * 3600 + minute * 60).rounded()
        
        SleepSessionManager.shared.log("UI Interaction: Updated wake time to \(String(format: "%02d:%02d", hour, minute)) for weekday \(selectedWeekday)")
        logClock("wakeTimes[\(key)] updated to \(wakeTimes[key]!)")
        
        selectedDayHour = hour
        selectedDayMinute = minute
        currentWakeUpTime = Self.todayDate(hour: hour, minute: minute)
        
        lastScheduledSession = nextUpcomingSession

        guard scheduledWeekdays.contains(selectedWeekday) else {
            return
        }

        Task {
            await scheduleSession()
        }
    }
    
    private func updateCurrentWakeUpTime() {
        let key = String(selectedWeekday)
        let totalSeconds = (wakeTimes[key] ?? TimeInterval(7 * 3600)).rounded()
        let totalSecondsInt = Int(totalSeconds)
        
        let h = totalSecondsInt / 3600
        let m = (totalSecondsInt % 3600) / 60
        
        logClock("updateCurrentWakeUpTime CALLED for key \(key). Computed: \(h):\(m). WakeTimes Dict: \(wakeTimes)")
        
        selectedDayHour = h
        selectedDayMinute = m
        currentWakeUpTime = Self.todayDate(hour: h, minute: m)
    }

    /// Builds a Date for today at the given hour and minute.
    static func todayDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? .now
    }

    func userFriendlyWatchStatus(from status: String) -> String {
        let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        if status.contains("No watch session activity") {
            return "Not started yet".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("Open Ninety on Apple Watch to arm Smart Alarm") ||
            status.localizedCaseInsensitiveContains("Queued")
        {
            return "Open the Watch app to finish setting up".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("armed") {
            return "Scheduled".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("Session Started") {
            return "Tracking in progress".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("Monitoring Paused") {
            return "Wake-up delivered".localized(for: preferredLang)
        }
        return status
    }

    func userFriendlyAlarmStatus(from status: String) -> String {
        let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        if status == "No alarms configured." {
            return "No alarms configured.".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("Authorized") {
            return "Ready".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("Failsafe Alarm Scheduled") || status.localizedCaseInsensitiveContains("Active Failsafe Alarm Scheduled") {
            return "Scheduled".localized(for: preferredLang)
        }
        if status.localizedCaseInsensitiveContains("DYNAMIC WAKE EVENT") || status.localizedCaseInsensitiveContains("Executed") {
            return "Wake-up triggered".localized(for: preferredLang)
        }
        return status
    }

    private var nextUpcomingWakeUpDate: Date? {
        guard !scheduledWeekdays.isEmpty else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()

        return scheduledWeekdays.compactMap { weekday -> Date? in
            let wakeKey = String(weekday)
            let secondsSinceMidnight = wakeTimes[wakeKey] ?? TimeInterval(7 * 3600) // default 07:00
            let hour = Int(secondsSinceMidnight) / 3600
            let minute = (Int(secondsSinceMidnight) % 3600) / 60
            
            var candidateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            candidateComponents.weekday = weekday
            candidateComponents.hour = hour
            candidateComponents.minute = minute
            candidateComponents.second = 0

            guard var candidateDate = calendar.date(from: candidateComponents) else {
                return nil
            }

            if candidateDate <= now {
                candidateDate = calendar.date(byAdding: .day, value: 7, to: candidateDate) ?? candidateDate
            }

            return candidateDate
        }
        .min()
    }

    private var fallbackProjectedSession: SmartAlarmManager.ScheduledSleepSession {
        // If the wake-up time is in the past, push it to tomorrow
        var wakeUpDate = currentWakeUpTime
        if wakeUpDate <= Date() {
            wakeUpDate = Calendar.current.date(byAdding: .day, value: 1, to: wakeUpDate) ?? wakeUpDate
        }
        return makeSession(for: wakeUpDate)
    }

    private func makeSession(for wakeUpDate: Date) -> SmartAlarmManager.ScheduledSleepSession {
        SmartAlarmManager.ScheduledSleepSession(
            wakeUpDate: wakeUpDate,
            monitoringStartDate: wakeUpDate.addingTimeInterval(-SmartAlarmManager.monitoringLeadTime)
        )
    }

    private func requestAlarmPermissions() async -> Bool {
        await withCheckedContinuation { continuation in
            SmartAlarmManager.shared.requestPermissions { granted in
                continuation.resume(returning: granted)
            }
        }
    }

}

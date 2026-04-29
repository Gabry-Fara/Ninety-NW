import Foundation
import SwiftUI

@MainActor
final class ScheduleViewModel: ObservableObject {
    private enum StorageKey {
        static let wakeTime = "scheduleWakeTimeInterval"
        static let wakeTimesDict = "scheduleWakeTimesDict"
        static let scheduledWeekdays = "scheduleWeekdayPlan"
        static let weekdayMutationTimes = "scheduleWeekdayMutationTimes"
    }

    static let externalScheduleDidChangeNotification = Notification.Name("NinetyExternalScheduleDidChange")
    static let externalScheduleChangedWeekdayKey = "weekday"

    struct WeeklyAlarmSnapshot {
        let weekday: Int
        let hour: Int
        let minute: Int
        let wakeUpDate: Date

        var session: SmartAlarmManager.ScheduledSleepSession {
            SmartAlarmManager.ScheduledSleepSession(
                wakeUpDate: wakeUpDate,
                monitoringStartDate: wakeUpDate.addingTimeInterval(-SmartAlarmManager.monitoringLeadTime)
            )
        }
    }

    struct WeeklyAlarmOperationResult {
        let affectedAlarm: WeeklyAlarmSnapshot?
        let nextAlarm: WeeklyAlarmSnapshot?
        let didScheduleSystemAlarm: Bool
    }

    struct WatchWeeklyAlarmApplyResult {
        let affectedAlarm: WeeklyAlarmSnapshot?
        let nextAlarm: WeeklyAlarmSnapshot?
        let didScheduleSystemAlarm: Bool
        let didApply: Bool
        let isStale: Bool
    }

    enum WeeklyAlarmError: LocalizedError {
        case invalidWeekday
        case invalidTime
        case invalidOffset
        case inactiveWeekday
        case crossesDayBoundary

        var errorDescription: String? {
            switch self {
            case .invalidWeekday:
                return "Quel giorno non è valido."
            case .invalidTime:
                return "Quell'orario non è valido."
            case .invalidOffset:
                return "Dimmi di quanti minuti vuoi spostare la sveglia."
            case .inactiveWeekday:
                return "Non hai nessuna sveglia Ninety attiva per quel giorno."
            case .crossesDayBoundary:
                return "Questo spostamento cambierebbe giorno. Imposta direttamente la sveglia sul nuovo giorno corretto."
            }
        }
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
    @Published private var weekdayMutationTimes: [String: TimeInterval] {
        didSet {
            UserDefaults.standard.set(weekdayMutationTimes, forKey: StorageKey.weekdayMutationTimes)
        }
    }
    @Published var lastScheduledSession: SmartAlarmManager.ScheduledSleepSession?
    @Published var isScheduling = false
    @Published var schedulingError: String?
    @Published var selectedDayHour: Int = 7
    @Published var selectedDayMinute: Int = 0
    @Published var clockLogs: [String] = []

    private var externalScheduleObserver: NSObjectProtocol?
    
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
        wakeTimes = Self.loadWakeTimesFromStorage()
        currentWakeUpTime = ScheduleViewModel.defaultWakeTime

        self.scheduledWeekdays = Self.loadScheduledWeekdaysFromStorage()
        self.weekdayMutationTimes = Self.loadWeekdayMutationTimesFromStorage()
        
        lastScheduledSession = nil
        observeExternalScheduleChanges()
        logClock("INIT ViewModel finished.")
        updateCurrentWakeUpTime()
        lastScheduledSession = nextUpcomingSession
    }

    deinit {
        if let externalScheduleObserver {
            NotificationCenter.default.removeObserver(externalScheduleObserver)
        }
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
        nextUpcomingAlarm?.session
    }

    var nextUpcomingAlarm: WeeklyAlarmSnapshot? {
        scheduledWeekdays.compactMap { alarmSnapshot(for: $0) }.min {
            $0.wakeUpDate < $1.wakeUpDate
        }
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

    @discardableResult
    func scheduleSession() async -> Bool {
        guard !isScheduling else { return false }
        guard let nextUpcomingSession else {
            await SmartAlarmManager.shared.cancelSessionNow()
            lastScheduledSession = nil
            schedulingError = nil
            return true
        }

        isScheduling = true
        schedulingError = nil
        defer { isScheduling = false }

        let granted = await requestAlarmPermissions()
        guard granted else {
            let preferredLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            schedulingError = "Permissions are required to schedule your weekly wake-up plan.".localized(for: preferredLang)
            return false
        }

        await SmartAlarmManager.shared.rescheduleSystemAlarm(for: nextUpcomingSession.wakeUpDate)
        lastScheduledSession = nextUpcomingSession
        return true
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
        markMutation(for: weekday)

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
        storeWakeTime(weekday: selectedWeekday, hour: hour, minute: minute)
        markMutation(for: selectedWeekday)
        
        SleepSessionManager.shared.log("UI Interaction: Updated wake time to \(String(format: "%02d:%02d", hour, minute)) for weekday \(selectedWeekday)")
        logClock("wakeTimes[\(selectedWeekday)] updated to \(wakeTimes[String(selectedWeekday)]!)")
        
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

    func setWeeklyAlarm(weekday: Int, wakeTime: Date) async throws -> WeeklyAlarmOperationResult {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: wakeTime)
        let minute = calendar.component(.minute, from: wakeTime)
        return try await setWeeklyAlarm(weekday: weekday, hour: hour, minute: minute)
    }

    func setWeeklyAlarm(weekday: Int, hour: Int, minute: Int) async throws -> WeeklyAlarmOperationResult {
        try validate(weekday: weekday, hour: hour, minute: minute)

        storeWakeTime(weekday: weekday, hour: hour, minute: minute)
        scheduledWeekdays.insert(weekday)
        markMutation(for: weekday)
        lastScheduledSession = nextUpcomingSession

        SleepSessionManager.shared.log("Siri: Set weekly alarm for weekday \(weekday) at \(String(format: "%02d:%02d", hour, minute))")

        let didSchedule = await scheduleSession()
        return WeeklyAlarmOperationResult(
            affectedAlarm: alarmSnapshot(for: weekday),
            nextAlarm: nextUpcomingAlarm,
            didScheduleSystemAlarm: didSchedule
        )
    }

    func applyWatchWeeklyAlarm(weekday: Int, hour: Int, minute: Int, createdAt: Date) async throws -> WatchWeeklyAlarmApplyResult {
        try validate(weekday: weekday, hour: hour, minute: minute)

        let createdAtInterval = createdAt.timeIntervalSince1970
        let latestMutationInterval = mutationTime(for: weekday)
        guard createdAtInterval >= latestMutationInterval else {
            let nextAlarm = nextUpcomingAlarm
            SleepSessionManager.shared.log(
                "Watch UI: Ignored stale weekly alarm for weekday \(weekday) at \(String(format: "%02d:%02d", hour, minute))"
            )
            return WatchWeeklyAlarmApplyResult(
                affectedAlarm: alarmSnapshot(for: weekday),
                nextAlarm: nextAlarm,
                didScheduleSystemAlarm: false,
                didApply: false,
                isStale: true
            )
        }

        storeWakeTime(weekday: weekday, hour: hour, minute: minute)
        scheduledWeekdays.insert(weekday)
        markMutation(for: weekday, timestamp: createdAtInterval)
        lastScheduledSession = nextUpcomingSession

        SleepSessionManager.shared.log(
            "Watch UI: Updated weekly alarm for weekday \(weekday) to \(String(format: "%02d:%02d", hour, minute))"
        )

        let didSchedule = await scheduleSession()
        postExternalScheduleChange(weekday: weekday)

        return WatchWeeklyAlarmApplyResult(
            affectedAlarm: alarmSnapshot(for: weekday),
            nextAlarm: nextUpcomingAlarm,
            didScheduleSystemAlarm: didSchedule,
            didApply: true,
            isStale: false
        )
    }

    func moveWeeklyAlarm(weekday: Int, offsetMinutes: Int, forward: Bool) async throws -> WeeklyAlarmOperationResult {
        guard (1...7).contains(weekday) else { throw WeeklyAlarmError.invalidWeekday }
        guard scheduledWeekdays.contains(weekday) else { throw WeeklyAlarmError.inactiveWeekday }
        guard offsetMinutes > 0 else { throw WeeklyAlarmError.invalidOffset }

        let currentSeconds = Int((wakeTimes[String(weekday)] ?? TimeInterval(7 * 3600)).rounded())
        let signedOffset = (forward ? offsetMinutes : -offsetMinutes) * 60
        let newSeconds = currentSeconds + signedOffset

        guard (0..<24 * 3600).contains(newSeconds) else {
            throw WeeklyAlarmError.crossesDayBoundary
        }

        let hour = newSeconds / 3600
        let minute = (newSeconds % 3600) / 60
        SleepSessionManager.shared.log("Siri: Move weekly alarm for weekday \(weekday) by \(signedOffset / 60)m")
        return try await setWeeklyAlarm(weekday: weekday, hour: hour, minute: minute)
    }

    func cancelWeeklyAlarm(weekday: Int) async throws -> WeeklyAlarmOperationResult {
        guard (1...7).contains(weekday) else { throw WeeklyAlarmError.invalidWeekday }
        guard scheduledWeekdays.contains(weekday) else { throw WeeklyAlarmError.inactiveWeekday }

        let previousAlarm = alarmSnapshot(for: weekday)
        scheduledWeekdays.remove(weekday)
        markMutation(for: weekday)
        lastScheduledSession = nextUpcomingSession

        SleepSessionManager.shared.log("Siri: Cancel weekly alarm for weekday \(weekday)")

        let didSchedule = await scheduleSession()
        return WeeklyAlarmOperationResult(
            affectedAlarm: previousAlarm,
            nextAlarm: nextUpcomingAlarm,
            didScheduleSystemAlarm: didSchedule
        )
    }

    private func clearCurrentSelection() {
        lastScheduledSession = nextUpcomingSession
    }

    private func mutationTime(for weekday: Int) -> TimeInterval {
        weekdayMutationTimes[String(weekday)] ?? 0
    }

    private func markMutation(for weekday: Int, at date: Date = Date()) {
        markMutation(for: weekday, timestamp: date.timeIntervalSince1970)
    }

    private func markMutation(for weekday: Int, timestamp: TimeInterval) {
        weekdayMutationTimes[String(weekday)] = timestamp
    }

    private func postExternalScheduleChange(weekday: Int) {
        NotificationCenter.default.post(
            name: Self.externalScheduleDidChangeNotification,
            object: self,
            userInfo: [Self.externalScheduleChangedWeekdayKey: weekday]
        )
    }

    private func observeExternalScheduleChanges() {
        externalScheduleObserver = NotificationCenter.default.addObserver(
            forName: Self.externalScheduleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let changedWeekday = notification.userInfo?[Self.externalScheduleChangedWeekdayKey] as? Int
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.reloadScheduleFromStorage(changedWeekday: changedWeekday)
            }
        }
    }

    private func reloadScheduleFromStorage(changedWeekday: Int?) {
        wakeTimes = Self.loadWakeTimesFromStorage()
        scheduledWeekdays = Self.loadScheduledWeekdaysFromStorage()
        weekdayMutationTimes = Self.loadWeekdayMutationTimesFromStorage()
        updateCurrentWakeUpTime()
        lastScheduledSession = nextUpcomingSession

        if let changedWeekday {
            logClock("External schedule change reloaded for weekday \(changedWeekday).")
        } else {
            logClock("External schedule change reloaded.")
        }
    }

    private static func loadWakeTimesFromStorage() -> [String: TimeInterval] {
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

        return initialWakeTimes
    }

    private static func loadScheduledWeekdaysFromStorage() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: StorageKey.scheduledWeekdays) as? [Int] ?? [])
    }

    private static func loadWeekdayMutationTimesFromStorage() -> [String: TimeInterval] {
        guard let dictionary = UserDefaults.standard.dictionary(forKey: StorageKey.weekdayMutationTimes) else {
            return [:]
        }
        return dictionary as? [String: TimeInterval] ?? [:]
    }

    func alarmSnapshot(for weekday: Int) -> WeeklyAlarmSnapshot? {
        guard scheduledWeekdays.contains(weekday),
              let (hour, minute) = wakeTimeComponents(for: weekday),
              let wakeUpDate = nextWakeUpDate(for: weekday, hour: hour, minute: minute)
        else {
            return nil
        }

        return WeeklyAlarmSnapshot(
            weekday: weekday,
            hour: hour,
            minute: minute,
            wakeUpDate: wakeUpDate
        )
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
        if status.localizedCaseInsensitiveContains("Session Started") ||
            status.localizedCaseInsensitiveContains("Recording") ||
            status.localizedCaseInsensitiveContains("Delivering backlog")
        {
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
        nextUpcomingAlarm?.wakeUpDate
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

    private func validate(weekday: Int, hour: Int, minute: Int) throws {
        guard (1...7).contains(weekday) else { throw WeeklyAlarmError.invalidWeekday }
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw WeeklyAlarmError.invalidTime
        }
    }

    private func storeWakeTime(weekday: Int, hour: Int, minute: Int) {
        let key = String(weekday)
        wakeTimes[key] = TimeInterval(hour * 3600 + minute * 60).rounded()

        if selectedWeekday == weekday {
            selectedDayHour = hour
            selectedDayMinute = minute
            currentWakeUpTime = Self.todayDate(hour: hour, minute: minute)
        }
    }

    private func wakeTimeComponents(for weekday: Int) -> (hour: Int, minute: Int)? {
        guard (1...7).contains(weekday) else { return nil }

        let totalSeconds = Int((wakeTimes[String(weekday)] ?? TimeInterval(7 * 3600)).rounded())
        return (totalSeconds / 3600, (totalSeconds % 3600) / 60)
    }

    private func nextWakeUpDate(for weekday: Int, hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var candidateDate = calendar.date(from: components) else {
            return nil
        }

        if candidateDate <= now {
            candidateDate = calendar.date(byAdding: .day, value: 7, to: candidateDate) ?? candidateDate
        }

        return candidateDate
    }

    private func requestAlarmPermissions() async -> Bool {
        await withCheckedContinuation { continuation in
            SmartAlarmManager.shared.requestPermissions { granted in
                continuation.resume(returning: granted)
            }
        }
    }

}

import Foundation
import SwiftUI

enum TimeView: String, CaseIterable {
    case day, week, month
}

struct SleepData: Identifiable {
    let id = UUID()
    let date: Date
    let sleepDuration: Double
}

@MainActor
final class ScheduleViewModel: ObservableObject {
    private enum StorageKey {
        static let wakeTime = "scheduleWakeTimeInterval"
        static let scheduledWeekdays = "scheduleWeekdayPlan"
    }

    @Published var wakeUpTime: Date {
        didSet {
            UserDefaults.standard.set(wakeUpTime.timeIntervalSince1970, forKey: StorageKey.wakeTime)
        }
    }
    @Published var scheduledWeekdays: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(scheduledWeekdays).sorted(), forKey: StorageKey.scheduledWeekdays)
        }
    }
    @Published var lastScheduledSession: SmartAlarmManager.ScheduledSleepSession?
    @Published var isScheduling = false
    @Published var schedulingError: String?
    @Published var sleepData: [SleepData] = []
    @Published var filteredSleepData: [SleepData] = []
    @Published var timeView: TimeView = .week

    init() {
        let storedWakeTime = UserDefaults.standard.object(forKey: StorageKey.wakeTime) as? TimeInterval
        let storedWeekdays = UserDefaults.standard.array(forKey: StorageKey.scheduledWeekdays) as? [Int] ?? []
        wakeUpTime = storedWakeTime.map(Date.init(timeIntervalSince1970:)) ?? Self.defaultWakeTime
        scheduledWeekdays = Set(storedWeekdays)
        lastScheduledSession = nil
        generateSampleSleepData()
        filterSleepData()
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
        wakeUpTime.formatted(date: .omitted, time: .shortened)
    }

    var scheduledDayLabel: String {
        guard let wakeUpDate = nextUpcomingSession?.wakeUpDate else {
            return "Pick your days"
        }
        if Calendar.current.isDateInToday(wakeUpDate) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(wakeUpDate) {
            return "Tomorrow"
        }
        return wakeUpDate.formatted(.dateTime.weekday(.wide))
    }

    var nextUpcomingLabel: String {
        guard let session = nextUpcomingSession else {
            return "No days selected"
        }
        let day = session.wakeUpDate.formatted(.dateTime.weekday(.abbreviated))
        let time = session.wakeUpDate.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(time)"
    }

    var primaryButtonTitle: String {
        guard !isScheduling else {
            return "Updating Plan..."
        }
        guard nextUpcomingSession != nil else {
            return "Choose Days to Plan"
        }
        return "Next Up · \(nextUpcomingLabel)"
    }

    func scheduleSession() async {
        guard !isScheduling else { return }
        guard let nextUpcomingSession else {
            SmartAlarmManager.shared.cancelSession()
            lastScheduledSession = nil
            schedulingError = nil
            return
        }

        isScheduling = true
        schedulingError = nil
        defer { isScheduling = false }

        let granted = await requestAlarmPermissions()
        guard granted else {
            schedulingError = "Permissions are required to schedule your weekly wake-up plan."
            return
        }

        SmartAlarmManager.shared.scheduleSystemAlarm(for: nextUpcomingSession.wakeUpDate)
        lastScheduledSession = nextUpcomingSession
    }

    func cancelSession() {
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

        Task {
            if scheduledWeekdays.isEmpty {
                cancelSession()
            } else {
                await scheduleSession()
            }
        }
    }

    func updateWakeTime(_ date: Date) {
        wakeUpTime = date
        lastScheduledSession = nextUpcomingSession

        guard !scheduledWeekdays.isEmpty else {
            return
        }

        Task {
            await scheduleSession()
        }
    }

    func userFriendlyWatchStatus(from status: String) -> String {
        if status.contains("No watch session activity") {
            return "Not started yet"
        }
        if status.localizedCaseInsensitiveContains("Queued") {
            return "Open the Watch app to finish setting up"
        }
        if status.localizedCaseInsensitiveContains("Session Started") {
            return "Tracking in progress"
        }
        if status.localizedCaseInsensitiveContains("Monitoring Paused") {
            return "Wake-up delivered"
        }
        return status
    }

    func userFriendlyAlarmStatus(from status: String) -> String {
        if status == "No alarms configured." {
            return "Not scheduled yet"
        }
        if status.localizedCaseInsensitiveContains("Authorized") {
            return "Ready"
        }
        if status.localizedCaseInsensitiveContains("Failsafe Alarm Scheduled") || status.localizedCaseInsensitiveContains("Active Failsafe Alarm Scheduled") {
            return "Scheduled"
        }
        if status.localizedCaseInsensitiveContains("DYNAMIC WAKE EVENT") || status.localizedCaseInsensitiveContains("Executed") {
            return "Wake-up triggered"
        }
        return status
    }

    func filterSleepData() {
        let calendar = Calendar.current
        let now = Date()

        switch timeView {
        case .day:
            filteredSleepData = sleepData.filter {
                calendar.isDate($0.date, inSameDayAs: now)
            }
        case .week:
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                filteredSleepData = sleepData.filter {
                    $0.date >= weekAgo && $0.date <= now
                }
            }
        case .month:
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredSleepData = sleepData.filter {
                    $0.date >= monthAgo && $0.date <= now
                }
            }
        }
    }

    private var nextUpcomingWakeUpDate: Date? {
        guard !scheduledWeekdays.isEmpty else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)

        return scheduledWeekdays.compactMap { weekday in
            var candidateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            candidateComponents.weekday = weekday
            candidateComponents.hour = wakeComponents.hour
            candidateComponents.minute = wakeComponents.minute
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
        let wakeUpDate = normalizedWakeUpDate(from: wakeUpTime)
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

    private func normalizedWakeUpDate(from requestedWakeUpDate: Date) -> Date {
        guard requestedWakeUpDate <= Date() else {
            return requestedWakeUpDate
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: requestedWakeUpDate) ?? requestedWakeUpDate
    }

    private func generateSampleSleepData() {
        sleepData = [
            SleepData(date: Date().addingTimeInterval(-86400 * 6), sleepDuration: 7.0),
            SleepData(date: Date().addingTimeInterval(-86400 * 5), sleepDuration: 6.5),
            SleepData(date: Date().addingTimeInterval(-86400 * 4), sleepDuration: 8.0),
            SleepData(date: Date().addingTimeInterval(-86400 * 3), sleepDuration: 7.5),
            SleepData(date: Date().addingTimeInterval(-86400 * 2), sleepDuration: 6.0),
            SleepData(date: Date().addingTimeInterval(-86400), sleepDuration: 7.2),
            SleepData(date: Date(), sleepDuration: 8.0)
        ]
    }
}

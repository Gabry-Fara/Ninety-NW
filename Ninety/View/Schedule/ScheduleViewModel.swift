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
    }

    @Published var wakeUpTime: Date {
        didSet {
            UserDefaults.standard.set(wakeUpTime.timeIntervalSince1970, forKey: StorageKey.wakeTime)
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
        wakeUpTime = storedWakeTime.map(Date.init(timeIntervalSince1970:)) ?? Self.defaultWakeTime
        generateSampleSleepData()
        filterSleepData()
    }

    static var defaultWakeTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? .now
    }

    var projectedSession: SmartAlarmManager.ScheduledSleepSession {
        let wakeUpDate = normalizedWakeUpDate(from: wakeUpTime)
        let monitoringStartDate = wakeUpDate.addingTimeInterval(-SmartAlarmManager.monitoringLeadTime)
        return SmartAlarmManager.ScheduledSleepSession(
            wakeUpDate: wakeUpDate,
            monitoringStartDate: monitoringStartDate
        )
    }

    var wakeTimeLabel: String {
        wakeUpTime.formatted(date: .omitted, time: .shortened)
    }

    var scheduledDayLabel: String {
        if Calendar.current.isDateInToday(projectedSession.wakeUpDate) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(projectedSession.wakeUpDate) {
            return "Tomorrow"
        }
        return projectedSession.wakeUpDate.formatted(.dateTime.weekday(.wide))
    }

    func scheduleSession() async {
        guard !isScheduling else { return }

        isScheduling = true
        schedulingError = nil
        defer { isScheduling = false }

        let granted = await requestAlarmPermissions()
        guard granted else {
            schedulingError = "Permissions are required to schedule the wake-up session."
            return
        }

        lastScheduledSession = SmartAlarmManager.shared.scheduleSleepSession(endingAt: wakeUpTime)
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

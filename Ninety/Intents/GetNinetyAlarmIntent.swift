// GetNinetyAlarmIntent.swift
// Ninety
//
// Use case 2 — "Ehi Siri, martedì a che ore è la sveglia di Ninety?"
// Queries the current alarm state and returns a spoken dialog response.

import AppIntents
import Foundation

struct GetNinetyAlarmIntent: AppIntent {

    // -------------------------------------------------------------------------
    // MARK: - Metadata
    // -------------------------------------------------------------------------

    static let title: LocalizedStringResource = "Controlla Sveglia Ninety"
    static let description = IntentDescription(
        "Chiedi a Siri a che ora è impostata la sveglia Ninety e se è attiva."
    )
    static let openAppWhenRun: Bool = false

    // -------------------------------------------------------------------------
    // MARK: - Parameters
    // -------------------------------------------------------------------------

    /// Optional day filter. If nil, query the next upcoming alarm.
    @Parameter(
        title: "Giorno",
        description: "Il giorno per cui vuoi conoscere l'orario della sveglia (opzionale).",
        requestValueDialog: IntentDialog("Per quale giorno vuoi sapere l'orario della sveglia?")
    )
    var queryDate: Date?

    // -------------------------------------------------------------------------
    // MARK: - Parameter Summary
    // -------------------------------------------------------------------------

    static var parameterSummary: some ParameterSummary {
        Summary("Dimmi la prossima sveglia Ninety")
    }

    // -------------------------------------------------------------------------
    // MARK: - Perform
    // -------------------------------------------------------------------------

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let scheduleVM  = ScheduleViewModel()       // reads from UserDefaults – lightweight
        let alarmStatus = SmartAlarmManager.shared.alarmStatus

        // Determine which weekday the user is asking about.
        let targetDate   = queryDate ?? Date()
        let targetWeekday = Calendar.current.component(.weekday, from: targetDate)

        // Resolve the alarm time for that weekday.
        guard let alarmDate = resolvedAlarmDate(for: targetWeekday, using: scheduleVM) else {
            // No alarm configured for this day.
            let dayName = weekdayName(for: targetWeekday)
            let dialog = "Non hai nessuna sveglia Ninety impostata per \(dayName)."
            return .result(dialog: IntentDialog(stringLiteral: dialog))
        }

        let timeFormatter = Date.FormatStyle().hour().minute()
        let timeLabel     = alarmDate.formatted(timeFormatter)
        let dayName       = weekdayName(for: targetWeekday)

        // Determine if the alarm is currently live/active in AlarmKit.
        let isActive = alarmIsActive(status: alarmStatus, date: alarmDate)
        let activeLabel = isActive ? "ed è attualmente attiva" : "ma non è attualmente attiva"

        let dialog = "La sveglia per \(dayName) è impostata entro le \(timeLabel) \(activeLabel)."
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }

    // -------------------------------------------------------------------------
    // MARK: - Helpers
    // -------------------------------------------------------------------------

    /// Resolves the scheduled alarm `Date` for a given weekday (1 = Sunday, …, 7 = Saturday).
    @MainActor
    private func resolvedAlarmDate(for weekday: Int, using vm: ScheduleViewModel) -> Date? {
        guard vm.scheduledWeekdays.contains(weekday) else { return nil }

        let key = String(weekday)
        let secondsSinceMidnight = vm.wakeTimes[key] ?? TimeInterval(7 * 3600)
        let hour   = Int(secondsSinceMidnight) / 3600
        let minute = (Int(secondsSinceMidnight) % 3600) / 60

        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = weekday
        components.hour    = hour
        components.minute  = minute
        components.second  = 0

        guard var candidate = calendar.date(from: components) else { return nil }
        if candidate <= now {
            candidate = calendar.date(byAdding: .day, value: 7, to: candidate) ?? candidate
        }
        return candidate
    }

    /// Returns true when the AlarmManager currently has a live alarm near `date`.
    private func alarmIsActive(status: String, date: Date) -> Bool {
        // The alarmStatus string is the canonical source of truth exposed by SmartAlarmManager.
        // An active failsafe alarm carries "Active Failsafe Alarm Scheduled" in its description.
        guard status.localizedCaseInsensitiveContains("Active Failsafe Alarm Scheduled") ||
              status.localizedCaseInsensitiveContains("Failsafe Set") else {
            return false
        }
        // Additionally verify the target time is still in the future.
        return date > Date()
    }

    /// Localized Italian weekday name for a given Gregorian weekday index (1 = Sunday).
    private func weekdayName(for weekday: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "it_IT")
        // `weekdaySymbols` is 0-indexed: index 0 = Sunday.
        let symbols = calendar.weekdaySymbols      // ["domenica", "lunedì", …]
        guard weekday >= 1, weekday <= 7 else { return "quel giorno" }
        return symbols[weekday - 1]
    }
}

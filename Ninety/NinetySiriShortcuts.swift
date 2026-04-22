import AppIntents
import Foundation

#if os(iOS)
struct NinetyShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // 1. Creazione della sveglia
        AppShortcut(
            intent: SetNinetyAlarmIntent(),
            phrases: [
                "Imposta la sveglia \(.applicationName)",
                "Svegliami con \(.applicationName)",
                "Punta la sveglia \(.applicationName)",
                "Set the \(.applicationName) alarm",
                "Wake me up with \(.applicationName)",
                "Set my alarm with \(.applicationName)"
            ],
            shortTitle: "Imposta Sveglia",
            systemImageName: "alarm"
        )
        
        // 2. Interrogazione stato
        AppShortcut(
            intent: GetNinetyAlarmIntent(),
            phrases: [
                "A che ora è la sveglia di \(.applicationName)",
                "Dimmi la prossima sveglia \(.applicationName)",
                "C'è una sveglia attiva in \(.applicationName)",
                "What time is the \(.applicationName) alarm",
                "Tell me the next \(.applicationName) alarm",
                "Is there an active alarm in \(.applicationName)"
            ],
            shortTitle: "Controlla Sveglia",
            systemImageName: "clock"
        )
        
        // 3. Modifica dinamica ('Hands-free')
        // We cannot interpolate Int types in AppShortcuts. Siri will ask conversationally or resolve naturally.
        AppShortcut(
            intent: UpdateNinetyAlarmIntent(),
            phrases: [
                "Sposta la sveglia \(.applicationName)",
                "Modifica la sveglia \(.applicationName)",
                "Sposta l'orario di \(.applicationName)",
                "Move the \(.applicationName) alarm",
                "Change the \(.applicationName) alarm",
                "Update the \(.applicationName) alarm"
            ],
            shortTitle: "Sposta Sveglia",
            systemImageName: "arrow.forward.circle"
        )
    }
}
#endif

// SetNinetyAlarmIntent.swift
// Ninety
//
// Use case 1 — "Ehi Siri, domani svegliami con Ninety entro le 9"
// Schedules the absolute failsafe alarm (Level 1) through SmartAlarmManager.

import AppIntents
import Foundation

struct SetNinetyAlarmIntent: AppIntent {

    // -------------------------------------------------------------------------
    // MARK: - Metadata
    // -------------------------------------------------------------------------

    static let title: LocalizedStringResource = "Imposta Sveglia Ninety"
    static let description = IntentDescription("Imposta la sveglia Ninety con un orario limite massimo. L'algoritmo calcolerà il momento ottimale di risveglio basandosi sui tuoi cicli Ultradiani.")

    /// Ninety is a UI-less alarm app – no need to bring the foreground app up.
    static let openAppWhenRun: Bool = false

    // -------------------------------------------------------------------------
    // MARK: - Parameters
    // -------------------------------------------------------------------------

    /// The hard-limit wake-up time provided by the user ("entro le 9").
    @Parameter(
        title: "Orario Limite",
        description: "L'orario massimo entro cui vuoi essere svegliato.",
        requestValueDialog: IntentDialog("A che ora devo svegliarti al massimo?")
    )
    var limitTime: Date

    // -------------------------------------------------------------------------
    // MARK: - Parameter Summary (shown in Shortcuts app)
    // -------------------------------------------------------------------------

    static var parameterSummary: some ParameterSummary {
        Summary("Svegliami con Ninety entro le \(\.$limitTime)")
    }

    // -------------------------------------------------------------------------
    // MARK: - Perform
    // -------------------------------------------------------------------------

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Normalize: if the user said a time in the past, push it to tomorrow.
        let targetDate = normalizedDate(from: limitTime)

        // Schedule Level 1 – Absolute Failsafe – and start the monitoring window.
        let session = SmartAlarmManager.shared.scheduleSleepSession(endingAt: targetDate)

        let timeFormatter = Date.FormatStyle().hour().minute()
        let limitLabel  = session.wakeUpDate.formatted(timeFormatter)
        let windowLabel = session.monitoringStartDate.formatted(timeFormatter)

        let dialog = "Perfetto! La sveglia Ninety è impostata entro le \(limitLabel). Inizierò a monitorare i tuoi cicli alle \(windowLabel). Buona notte!"
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }

    // -------------------------------------------------------------------------
    // MARK: - Helpers
    // -------------------------------------------------------------------------

    /// If `date` is already in the past, advance it by 24 h so it lands tomorrow.
    private func normalizedDate(from date: Date) -> Date {
        guard date <= Date() else { return date }
        return Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
    }
}


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


// UpdateNinetyAlarmIntent.swift
// Ninety
//
// Use case 3 — "Ehi Siri, sposta la mia sveglia di Ninety di un'ora in avanti"
// Cancels the existing AlarmKit alarm and reschedules it with an offset applied.

import AppIntents
import Foundation

// ---------------------------------------------------------------------------
// MARK: - Offset Direction Enum
// ---------------------------------------------------------------------------

/// Whether the user wants to move the alarm forward or backward in time.
enum AlarmOffsetDirection: String, AppEnum {
    case forward  = "avanti"
    case backward = "indietro"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Direzione"
    static let caseDisplayRepresentations: [AlarmOffsetDirection: DisplayRepresentation] = [
        .forward:  "in avanti",
        .backward: "indietro"
    ]
}

// ---------------------------------------------------------------------------
// MARK: - Intent
// ---------------------------------------------------------------------------

struct UpdateNinetyAlarmIntent: AppIntent {

    // -------------------------------------------------------------------------
    // MARK: - Metadata
    // -------------------------------------------------------------------------

    static let title: LocalizedStringResource = "Sposta Sveglia Ninety"
    static let description = IntentDescription(
        "Sposta la sveglia Ninety di un certo numero di minuti o ore in avanti o indietro."
    )
    static let openAppWhenRun: Bool = false

    // -------------------------------------------------------------------------
    // MARK: - Parameters
    // -------------------------------------------------------------------------

    /// Offset amount expressed in **minutes**.
    /// The user can say "un'ora" (= 60), "30 minuti", etc.
    @Parameter(
        title: "Minuti di spostamento",
        description: "Quanti minuti vuoi spostare la sveglia? (es. 60 per un'ora)",
        default: 60,
        requestValueDialog: IntentDialog("Di quanti minuti vuoi spostare la sveglia?")
    )
    var offsetMinutes: Int

    /// Direction: forward (+) or backward (–).
    @Parameter(
        title: "Direzione",
        description: "Vuoi spostare la sveglia in avanti o indietro?",
        default: AlarmOffsetDirection.forward,
        requestValueDialog: IntentDialog("Vuoi spostarla in avanti o indietro?")
    )
    var direction: AlarmOffsetDirection

    // -------------------------------------------------------------------------
    // MARK: - Parameter Summary
    // -------------------------------------------------------------------------

    static var parameterSummary: some ParameterSummary {
        Summary("Sposta la sveglia Ninety")
    }

    // -------------------------------------------------------------------------
    // MARK: - Perform
    // -------------------------------------------------------------------------

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = SmartAlarmManager.shared

        // 1. Retrieve the currently scheduled alarm time.
        //    SmartAlarmManager stores the active alarm's ID; the actual target date
        //    lives inside ScheduleViewModel (UserDefaults-backed).
        let scheduleVM = ScheduleViewModel()

        guard let currentSession = scheduleVM.nextUpcomingSession else {
            return .result(
                dialog: IntentDialog(
                    "Non ho trovato nessuna sveglia Ninety attiva da spostare."
                )
            )
        }

        // 2. Compute the offset (positive = forward, negative = backward).
        let sign: Double = direction == .forward ? 1 : -1
        let offsetSeconds = sign * Double(offsetMinutes) * 60
        let newWakeUpDate = currentSession.wakeUpDate.addingTimeInterval(offsetSeconds)

        // Make sure the new time is still in the future.
        guard newWakeUpDate > Date() else {
            let dialog = "Spostando la sveglia indietro di \(offsetMinutes) minuti otterrei un orario già passato. Non ho modificato nulla."
            return .result(
                dialog: IntentDialog(stringLiteral: dialog)
            )
        }

        // 3. Cancel the old alarm and reschedule with the new time.
        manager.cancelSession()
        let newSession = manager.scheduleSleepSession(endingAt: newWakeUpDate)

        // 4. Build a friendly confirmation dialog.
        let timeFormatter = Date.FormatStyle().hour().minute()
        let newTimeLabel  = newSession.wakeUpDate.formatted(timeFormatter)
        let directionLabel = direction == .forward ? "avanti" : "indietro"
        let minuteLabel = offsetMinutes == 60 ? "un'ora" : "\(offsetMinutes) minuti"
        let dialog = "Fatto! Ho spostato la sveglia Ninety di \(minuteLabel) in \(directionLabel). Il nuovo orario limite è le \(newTimeLabel)."

        return .result(
            dialog: IntentDialog(stringLiteral: dialog)
        )
    }
}

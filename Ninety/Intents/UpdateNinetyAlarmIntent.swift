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

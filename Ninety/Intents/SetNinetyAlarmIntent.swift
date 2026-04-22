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

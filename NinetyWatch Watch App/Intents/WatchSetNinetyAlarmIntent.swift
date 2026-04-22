// WatchSetNinetyAlarmIntent.swift
// NinetyWatch Watch App
//
// Cross-device relay: captures "Ehi Siri, svegliami con Ninety entro le 9"
// on the Apple Watch and delegates execution to the iPhone via WCSession.

import AppIntents
import Foundation

struct WatchSetNinetyAlarmIntent: AppIntent {

    static let title: LocalizedStringResource = "Imposta Sveglia Ninety"
    static let description = IntentDescription("Imposta la sveglia Ninety dall'Apple Watch. Il comando viene inoltrato all'iPhone per la programmazione su AlarmKit.")
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Orario Limite",
        description: "L'orario massimo entro cui vuoi essere svegliato.",
        requestValueDialog: IntentDialog("A che ora devo svegliarti al massimo?")
    )
    var limitTime: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Svegliami con Ninety entro le \(\.$limitTime)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let dialog = try await WatchIntentRelay.shared.relay(
                action: "setAlarm",
                params: ["limitTime": limitTime.timeIntervalSince1970]
            )
            return .result(dialog: IntentDialog(stringLiteral: dialog))
        } catch {
            let errorMsg = "Non sono riuscito a comunicare con l'iPhone: \(error.localizedDescription)"
            return .result(dialog: IntentDialog(stringLiteral: errorMsg))
        }
    }
}

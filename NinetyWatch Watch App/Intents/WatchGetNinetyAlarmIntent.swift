// WatchGetNinetyAlarmIntent.swift
// NinetyWatch Watch App
//
// Cross-device relay: captures "Ehi Siri, a che ora è la sveglia di Ninety?"
// on the Apple Watch and asks the iPhone for the current alarm state.

import AppIntents
import Foundation

struct WatchGetNinetyAlarmIntent: AppIntent {

    static let title: LocalizedStringResource = "Controlla Sveglia Ninety"
    static let description = IntentDescription("Chiedi a Siri dall'Apple Watch a che ora è la sveglia Ninety.")
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Giorno",
        description: "Il giorno per cui vuoi controllare la sveglia (opzionale).",
        requestValueDialog: IntentDialog("Per quale giorno vuoi sapere l'orario?")
    )
    var queryDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Dimmi la prossima sveglia Ninety")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            var params: [String: Any] = [:]
            if let queryDate {
                params["queryDate"] = queryDate.timeIntervalSince1970
            }

            let dialog = try await WatchIntentRelay.shared.relay(
                action: "getAlarm",
                params: params
            )
            return .result(dialog: IntentDialog(stringLiteral: dialog))
        } catch {
            let errorMsg = "Non sono riuscito a comunicare con l'iPhone: \(error.localizedDescription)"
            return .result(dialog: IntentDialog(stringLiteral: errorMsg))
        }
    }
}

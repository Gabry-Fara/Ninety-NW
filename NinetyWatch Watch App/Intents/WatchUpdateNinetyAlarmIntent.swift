// WatchUpdateNinetyAlarmIntent.swift
// NinetyWatch Watch App
//
// Cross-device relay: captures "Ehi Siri, sposta la mia sveglia di Ninety
// di un'ora in avanti" on the Apple Watch and relays to iPhone.

import AppIntents
import Foundation

/// Direction enum mirroring the iOS-side AlarmOffsetDirection.
enum WatchAlarmOffsetDirection: String, AppEnum {
    case forward  = "avanti"
    case backward = "indietro"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Direzione"
    static let caseDisplayRepresentations: [WatchAlarmOffsetDirection: DisplayRepresentation] = [
        .forward:  "in avanti",
        .backward: "indietro"
    ]
}

struct WatchUpdateNinetyAlarmIntent: AppIntent {

    static let title: LocalizedStringResource = "Sposta Sveglia Ninety"
    static let description = IntentDescription("Sposta la sveglia Ninety dall'Apple Watch. Il comando viene inoltrato all'iPhone.")
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Minuti di spostamento",
        description: "Quanti minuti vuoi spostare la sveglia?",
        default: 60,
        requestValueDialog: IntentDialog("Di quanti minuti vuoi spostare la sveglia?")
    )
    var offsetMinutes: Int

    @Parameter(
        title: "Direzione",
        description: "Vuoi spostare la sveglia in avanti o indietro?",
        default: WatchAlarmOffsetDirection.forward,
        requestValueDialog: IntentDialog("Vuoi spostarla in avanti o indietro?")
    )
    var direction: WatchAlarmOffsetDirection

    static var parameterSummary: some ParameterSummary {
        Summary("Sposta la sveglia Ninety")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let dialog = try await WatchIntentRelay.shared.relay(
                action: "updateAlarm",
                params: [
                    "offsetMinutes": offsetMinutes,
                    "direction": direction.rawValue
                ]
            )
            return .result(dialog: IntentDialog(stringLiteral: dialog))
        } catch {
            let errorMsg = "Non sono riuscito a comunicare con l'iPhone: \(error.localizedDescription)"
            return .result(dialog: IntentDialog(stringLiteral: errorMsg))
        }
    }
}

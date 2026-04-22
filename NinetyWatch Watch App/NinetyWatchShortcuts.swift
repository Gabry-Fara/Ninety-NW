// NinetyWatchShortcuts.swift
// NinetyWatch Watch App
//
// AppShortcutsProvider for the watchOS companion.
// Registers the same natural-language phrases as the iOS side, but routes
// them through the Watch relay intents that delegate to iPhone via WCSession.

import AppIntents

struct NinetyWatchShortcuts: AppShortcutsProvider {

    static var shortcutTileColor: ShortcutTileColor { .navy }

    static var appShortcuts: [AppShortcut] {

        // --  Imposta sveglia (relay → iPhone AlarmKit)
        AppShortcut(
            intent: WatchSetNinetyAlarmIntent(),
            phrases: [
                "Svegliami con \(.applicationName)",
                "Imposta la sveglia \(.applicationName)",
                "Domani svegliami con \(.applicationName)",
                "Wake me up with \(.applicationName)",
                "Set my \(.applicationName) alarm"
            ],
            shortTitle: "Imposta Sveglia",
            systemImageName: "moon.zzz.fill"
        )

        // -- Controlla sveglia (relay → iPhone state)
        AppShortcut(
            intent: WatchGetNinetyAlarmIntent(),
            phrases: [
                "Quando è la prossima sveglia \(.applicationName)",
                "A che ora è la sveglia di \(.applicationName)",
                "La sveglia \(.applicationName) è attiva",
                "When is my \(.applicationName) alarm",
                "What time is my \(.applicationName) alarm"
            ],
            shortTitle: "Controlla Sveglia",
            systemImageName: "alarm"
        )

        // -- Sposta sveglia (relay → iPhone reschedule)
        AppShortcut(
            intent: WatchUpdateNinetyAlarmIntent(),
            phrases: [
                "Sposta la mia sveglia \(.applicationName) di un'ora in avanti",
                "Posticipa la sveglia \(.applicationName)",
                "Move my \(.applicationName) alarm"
            ],
            shortTitle: "Sposta Sveglia",
            systemImageName: "arrow.clockwise"
        )
    }
}

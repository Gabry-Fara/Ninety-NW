import AppIntents

#if os(iOS)
struct NinetyShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .navy }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetNinetyAlarmIntent(),
            phrases: [
                "Svegliami con \(.applicationName)",
                "Imposta sveglia con \(.applicationName)",
                "Imposta la sveglia con \(.applicationName)",
                "Set alarm with \(.applicationName)"
            ],
            shortTitle: "Imposta Sveglia",
            systemImageName: "alarm"
        )
        

        AppShortcut(
            intent: GetNinetyAlarmIntent(),
            phrases: [
                "Controlla sveglia con \(.applicationName)",
                "A che ora è la sveglia con \(.applicationName)",
                "Dimmi la prossima sveglia con \(.applicationName)",
                "Check alarm with \(.applicationName)"
            ],
            shortTitle: "Controlla Sveglia",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: UpdateNinetyAlarmIntent(),
            phrases: [
                "Sposta sveglia con \(.applicationName)",
                "Modifica sveglia con \(.applicationName)",
                "Move alarm with \(.applicationName)"
            ],
            shortTitle: "Sposta Sveglia",
            systemImageName: "arrow.forward.circle"
        )

        AppShortcut(
            intent: CancelNinetyAlarmIntent(),
            phrases: [
                "Annulla sveglia con \(.applicationName)",
                "Disattiva sveglia con \(.applicationName)",
                "Cancel alarm with \(.applicationName)"
            ],
            shortTitle: "Annulla Sveglia",
            systemImageName: "xmark.circle"
        )
    }
}
#endif

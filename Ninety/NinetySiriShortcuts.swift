import AppIntents
import Foundation

struct ScheduleWakeUpIntent: AppIntent {
    static let title: LocalizedStringResource = "Schedule Wake Up"
    static let description = IntentDescription("Schedule a Ninety wake-up session that starts monitoring 30 minutes before the requested wake-up time.")
    static let openAppWhenRun = false

    @Parameter(
        title: "Wake Up Time",
        requestValueDialog: IntentDialog("What time should I wake you up?")
    )
    var wakeUpTime: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Wake me up at \(\.$wakeUpTime)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let session = await MainActor.run {
            SmartAlarmManager.shared.scheduleSleepSession(endingAt: wakeUpTime)
        }

        let wakeUpText = session.wakeUpDate.formatted(date: .abbreviated, time: .shortened)
        let monitoringText = session.monitoringStartDate.formatted(date: .abbreviated, time: .shortened)

        return .result(
            dialog: IntentDialog("Wake-up scheduled for \(wakeUpText). Monitoring starts at \(monitoringText).")
        )
    }
}

struct NinetyShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScheduleWakeUpIntent(),
            phrases: [
                "Wake me up with \(.applicationName)",
                "Schedule my wake up in \(.applicationName)",
                "Set my sleep session in \(.applicationName)"
            ],
            shortTitle: "Wake Up",
            systemImageName: "alarm"
        )
    }
}

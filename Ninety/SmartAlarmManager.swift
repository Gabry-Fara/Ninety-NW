import Foundation
import Combine
import UserNotifications
import AVFoundation
import AudioToolbox
import AppIntents

#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
class SmartAlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SmartAlarmManager()
    nonisolated static let monitoringLeadTime: TimeInterval = 30 * 60
    nonisolated static let wakePreAlertDuration: TimeInterval = 60

    struct ScheduledSleepSession {
        let wakeUpDate: Date
        let monitoringStartDate: Date
    }

    private enum StorageKey {
        static let stopTombstone = "NinetyAlarmStopTombstone"
    }

    private struct AlarmStopTombstone: Codable {
        let alarmInstanceID: UUID?
        let targetDate: Date?
        let stoppedAt: Date
        let createdAt: Date?
    }

    private enum WakeAlarmStartReason {
        case lightSleep
        case deadlineFallback
        case watchRequest

        var statusText: String {
            switch self {
            case .lightSleep:
                return "Alarm active: light sleep confirmed"
            case .deadlineFallback:
                return "Alarm active: final minute"
            case .watchRequest:
                return "Alarm active from Apple Watch"
            }
        }
    }
    
    @Published var alarmStatus: String = "No alarms configured."
    @Published var monitoringCountdown: String = ""
    @Published var isWakeAlarmActive: Bool = false
    
    private var absoluteAlarmID: UUID?
    private var monitoringTimer: Timer?   // fires when the 30-minute tracking window opens
    private var countdownTimer: Timer?    // updates the countdown string every second
    private var layer2Task: Task<Void, Never>?
    private var alarmStartTimer: Timer?
    private var alarmAlertTimer: Timer?
    private var wakeTargetDate: Date?
    private var alarmCreatedAt: Date?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in
            await cleanupOrphanedSystemAlarmsIfNeeded()
        }
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            SmartAlarmManager.shared.cancelSession()
        }
        completionHandler()
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        #if canImport(AlarmKit)
        Task {
            do {
                _ = try await AlarmManager.shared.requestAuthorization()
                self.alarmStatus = "AlarmKit Authorized"
                completion(true)
            } catch {
                self.alarmStatus = "AlarmKit Auth Failed: \(error)"
                completion(false)
            }
        }
        #else
        self.alarmStatus = "[Mock] AlarmKit Authorized (Not Available in this SDK)"
        completion(true)
        #endif
    }
    
#if canImport(AlarmKit)
    struct NinetyAlarmMetadata: AlarmMetadata {}
    
    private func createWakeAlarmAttributes() -> AlarmAttributes<NinetyAlarmMetadata> {
        let pauseButton = AlarmButton(text: "Pause", textColor: .blue, systemImageName: "pause.fill")
        let resumeButton = AlarmButton(text: "Resume", textColor: .blue, systemImageName: "play.fill")
        let presentation = AlarmPresentation(
            alert: .init(title: "Ninety Wake Up"),
            countdown: .init(title: "Ninety Wake Up", pauseButton: pauseButton),
            paused: .init(title: "Ninety Wake Up", resumeButton: resumeButton)
        )
        return AlarmAttributes(presentation: presentation, tintColor: .blue)
    }
    #endif

    func scheduleSleepSession(endingAt requestedWakeUpDate: Date, alarmID: UUID? = nil, createdAt: Date? = nil) -> ScheduledSleepSession {
        let wakeUpDate = normalizedWakeUpDate(from: requestedWakeUpDate)
        let monitoringStartDate = monitoringStartDate(for: wakeUpDate)
        scheduleSystemAlarm(for: wakeUpDate, alarmID: alarmID, createdAt: createdAt)
        return ScheduledSleepSession(wakeUpDate: wakeUpDate, monitoringStartDate: monitoringStartDate)
    }
    
    func cancelSession(alarmID: UUID? = nil, stoppedAt: Date? = nil) {
        Task {
            await cancelSessionNow(alarmID: alarmID, stoppedAt: stoppedAt)
        }
    }

    func cancelSessionNow(alarmID: UUID? = nil, stoppedAt: Date? = nil) async {
        if let alarmID, let absoluteAlarmID, alarmID != absoluteAlarmID {
            let stopDate = stoppedAt ?? Date()
            recordStopTombstone(
                alarmID: alarmID,
                targetDate: nil,
                stoppedAt: stopDate,
                createdAt: nil
            )
            cancelSystemAlarm(id: alarmID)
            SleepSessionManager.shared.stopWatchAlarmPlayback(
                alarmID: alarmID,
                targetDate: nil,
                stoppedAt: stopDate
            )
            return
        }

        await clearScheduledSession(resetStatus: true, stoppedAt: stoppedAt ?? Date())
    }

    func rescheduleSystemAlarm(for targetDate: Date, alarmID: UUID? = nil, createdAt: Date? = nil) async {
        await clearScheduledSession(resetStatus: false)
        await scheduleSystemAlarmAfterClearing(for: targetDate, alarmID: alarmID, createdAt: createdAt)
    }

    private func clearScheduledSession(resetStatus: Bool, stoppedAt: Date? = nil) async {
        let cancelledAlarmID = absoluteAlarmID
        let cancelledTargetDate = wakeTargetDate
        let cancelledCreatedAt = alarmCreatedAt

        if let stoppedAt {
            recordStopTombstone(
                alarmID: cancelledAlarmID,
                targetDate: cancelledTargetDate,
                stoppedAt: stoppedAt,
                createdAt: cancelledCreatedAt
            )
        }

        monitoringTimer?.invalidate()
        monitoringTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        alarmStartTimer?.invalidate()
        alarmStartTimer = nil
        alarmAlertTimer?.invalidate()
        alarmAlertTimer = nil
        wakeTargetDate = nil
        alarmCreatedAt = nil
        monitoringCountdown = ""
        isWakeAlarmActive = false

        layer2Task?.cancel()
        layer2Task = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        cancelAllSystemAlarms()
        absoluteAlarmID = nil

        SleepSessionManager.shared.syncAlarmState(
            targetDate: nil,
            alarmID: cancelledAlarmID,
            createdAt: cancelledCreatedAt,
            stoppedAt: stoppedAt
        )
        if resetStatus || stoppedAt != nil {
            SleepSessionManager.shared.stopWatchAlarmPlayback(
                alarmID: cancelledAlarmID,
                targetDate: cancelledTargetDate,
                stoppedAt: stoppedAt
            )
        }
        SleepSessionManager.shared.pauseWatchMonitoring()

        if resetStatus {
            self.alarmStatus = "No alarms configured."
        }
    }
    
    func scheduleSystemAlarm(for targetDate: Date, alarmID: UUID? = nil, createdAt: Date? = nil) {
        Task {
            await rescheduleSystemAlarm(for: targetDate, alarmID: alarmID, createdAt: createdAt)
        }
    }

    private func scheduleSystemAlarmAfterClearing(for targetDate: Date, alarmID requestedAlarmID: UUID? = nil, createdAt requestedCreatedAt: Date? = nil) async {
        let alarmID = requestedAlarmID ?? UUID()
        let createdAt = requestedCreatedAt ?? Date()
        guard !shouldIgnoreScheduleDueToStop(alarmID: alarmID, targetDate: targetDate, createdAt: createdAt) else {
            self.alarmStatus = "Alarm ignored because it was already stopped."
            return
        }

        self.absoluteAlarmID = alarmID
        self.alarmCreatedAt = createdAt

        SleepSessionManager.shared.syncAlarmState(
            targetDate: targetDate,
            alarmID: alarmID,
            createdAt: createdAt
        )

        let monitoringStart = monitoringStartDate(for: targetDate)
        let now = Date()

        // Cancel any previous pending monitoring timer
        monitoringTimer?.invalidate()
        countdownTimer?.invalidate()
        alarmStartTimer?.invalidate()
        alarmAlertTimer?.invalidate()
        wakeTargetDate = targetDate

        SleepSessionManager.shared.startWatchSession(
            targetDate: targetDate,
            alarmID: alarmID,
            createdAt: createdAt
        )

        if monitoringStart <= now {
            // We're already inside the 30-minute window — start immediately.
            self.alarmStatus = "Tracking window open on Apple Watch"
        } else {
            // The watch is armed immediately; the phone keeps a local countdown
            // so the user can still see when the monitoring window opens.
            let delay = monitoringStart.timeIntervalSinceNow
            self.alarmStatus = "Open Ninety on Apple Watch once before sleep to arm Smart Alarm"

            // Live countdown
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self else { return }
                let remaining = monitoringStart.timeIntervalSinceNow
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if remaining <= 0 {
                        self.countdownTimer?.invalidate()
                        self.monitoringCountdown = ""
                    } else {
                        let mins = Int(remaining) / 60
                        let secs = Int(remaining) % 60
                        self.monitoringCountdown = String(format: "Monitoring in %02d:%02d", mins, secs)
                    }
                }
            }

            // Schedule Watch session start
            monitoringTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.alarmStatus = "🟢 Tracking window open on Apple Watch"
                    self.monitoringCountdown = ""
                }
            }
        }

        self.alarmStatus = monitoringStart <= now
            ? "🟢 Tracking window open | Alarm set: \(targetDate.formatted(date: .omitted, time: .shortened))"
            : "⏳ Alarm set: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"

        #if canImport(AlarmKit)
        do {
            let countdownDuration = Alarm.CountdownDuration(
                preAlert: Self.wakePreAlertDuration,
                postAlert: nil
            )
            let configuration = AlarmManager.AlarmConfiguration(
                countdownDuration: countdownDuration,
                schedule: .fixed(targetDate),
                attributes: createWakeAlarmAttributes(),
                stopIntent: StopNinetyWakeAlarmIntent()
            )
            _ = try await AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
            scheduleLocalWakeStart(at: targetDate)
            if !isWakeAlarmActive {
                self.alarmStatus = self.alarmStatus.contains("🟢")
                    ? "🟢 Tracking window open | ✅ AlarmKit alarm set: \(targetDate.formatted(date: .omitted, time: .shortened))"
                    : "⏳ ✅ AlarmKit alarm set: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"
            }
        } catch {
            self.alarmStatus = "System Alarm Schedule failed: \(error)"
        }
        #else
        scheduleLocalWakeStart(at: targetDate)
        if !isWakeAlarmActive {
            self.alarmStatus = "[Sim] Alarm set: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"
        }
        #endif
    }
    
    // Layer Two: The Dynamic Heuristic Trigger
    func triggerDynamicAlarm() {
        startWakeAlarm(reason: .lightSleep)
    }

    func startDeadlineWakeAlarm() {
        startWakeAlarm(reason: .deadlineFallback)
    }

    func startWakeAlarmFromWatch(alarmID: UUID? = nil) {
        if let alarmID {
            absoluteAlarmID = alarmID
        }
        startWakeAlarm(reason: .watchRequest)
    }

    func currentAlarmInstanceID() -> UUID? {
        absoluteAlarmID
    }

    private func startWakeAlarm(reason: WakeAlarmStartReason) {
        guard !isWakeAlarmActive else { return }
        isWakeAlarmActive = true
        self.alarmStatus = reason.statusText
        cancelLocalWakeStartTimer()
        scheduleAlarmAlertStatus(at: Date().addingTimeInterval(Self.wakePreAlertDuration))
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        monitoringCountdown = ""
        
        SleepSessionManager.shared.triggerWatchHapticWakeUp()
        SleepSessionManager.shared.finishMonitoringAfterAlarmFired()

        #if canImport(AlarmKit)
        guard let alarmID = currentAlarmID() else {
            self.alarmStatus = "Alarm active, but AlarmKit alarm was not found"
            return
        }
        absoluteAlarmID = alarmID

        do {
            if let alarm = currentSystemAlarm(for: alarmID), alarm.state == .alerting {
                self.alarmStatus = "Alarm alerting"
            } else if let alarm = currentSystemAlarm(for: alarmID), alarm.state == .countdown {
                self.alarmStatus = "Alarm active: countdown"
            } else {
                try AlarmManager.shared.countdown(id: alarmID)
                self.alarmStatus = "Alarm active: countdown"
            }
        } catch {
            self.alarmStatus = "Alarm active; AlarmKit countdown unavailable: \(error)"
        }
        #else
        self.alarmStatus = "[Sim] Alarm active: countdown"

        layer2Task = Task {
            let content = UNMutableNotificationContent()
            content.title = "NINETY: OPTIMAL WAKE TIME!"
            content.body = "You are in a light sleep phase. Wake up now!"
            content.sound = .defaultCritical

            let requestID = UUID().uuidString
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Self.wakePreAlertDuration, repeats: false)
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed mock notification: \(error)")
            }

            do {
                try await Task.sleep(nanoseconds: UInt64(Self.wakePreAlertDuration * 1_000_000_000))
                if !Task.isCancelled {
                    self.alarmStatus = "[Sim] Alarm alerting"
                    self.playMockAlarmSound()
                }
            } catch {
                // Task was cancelled
            }
        }
        #endif
    }

    private func scheduleLocalWakeStart(at targetDate: Date) {
        alarmStartTimer?.invalidate()
        wakeTargetDate = targetDate

        let wakeStartDate = targetDate.addingTimeInterval(-Self.wakePreAlertDuration)
        let delay = wakeStartDate.timeIntervalSinceNow
        guard delay > 0 else {
            if targetDate > Date() {
                startWakeAlarm(reason: .deadlineFallback)
            }
            return
        }

        alarmStartTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard
                    let self,
                    let scheduledTarget = self.wakeTargetDate,
                    abs(scheduledTarget.timeIntervalSince(targetDate)) < 1
                else {
                    return
                }

                self.startWakeAlarm(reason: .deadlineFallback)
            }
        }
    }

    private func scheduleAlarmAlertStatus(at alertDate: Date) {
        alarmAlertTimer?.invalidate()
        let delay = alertDate.timeIntervalSinceNow
        guard delay > 0 else {
            alarmStatus = "Alarm alerting"
            return
        }

        alarmAlertTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isWakeAlarmActive else { return }
                self.alarmStatus = "Alarm alerting"
            }
        }
    }

    private func cancelLocalWakeStartTimer() {
        alarmStartTimer?.invalidate()
        alarmStartTimer = nil
    }

    #if canImport(AlarmKit)
    private func currentAlarmID() -> UUID? {
        if let absoluteAlarmID {
            return absoluteAlarmID
        }

        return (try? AlarmManager.shared.alarms.first?.id) ?? nil
    }

    private func currentSystemAlarm(for alarmID: UUID) -> Alarm? {
        (try? AlarmManager.shared.alarms.first { $0.id == alarmID }) ?? nil
    }
    #endif

    private func stopTombstone() -> AlarmStopTombstone? {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.stopTombstone) else {
            return nil
        }

        guard let tombstone = try? JSONDecoder().decode(AlarmStopTombstone.self, from: data) else {
            UserDefaults.standard.removeObject(forKey: StorageKey.stopTombstone)
            return nil
        }

        return tombstone
    }

    private func recordStopTombstone(alarmID: UUID?, targetDate: Date?, stoppedAt: Date, createdAt: Date?) {
        let tombstone = AlarmStopTombstone(
            alarmInstanceID: alarmID,
            targetDate: targetDate,
            stoppedAt: stoppedAt,
            createdAt: createdAt
        )

        if let existing = stopTombstone(), existing.stoppedAt > stoppedAt {
            return
        }

        guard let data = try? JSONEncoder().encode(tombstone) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.stopTombstone)
    }

    private func shouldIgnoreScheduleDueToStop(alarmID: UUID, targetDate: Date, createdAt: Date) -> Bool {
        guard let tombstone = stopTombstone() else { return false }
        guard tombstone.stoppedAt >= createdAt else { return false }

        if let stoppedID = tombstone.alarmInstanceID, stoppedID == alarmID {
            return true
        }

        if let stoppedTarget = tombstone.targetDate, abs(stoppedTarget.timeIntervalSince(targetDate)) < 1 {
            return true
        }

        return false
    }

    private func cleanupOrphanedSystemAlarmsIfNeeded() async {
        let scheduleViewModel = ScheduleViewModel(observesExternalChanges: false)
        guard scheduleViewModel.nextUpcomingSession == nil else { return }
        await clearScheduledSession(resetStatus: true)
    }

    private func cancelAllSystemAlarms() {
        #if canImport(AlarmKit)
        let trackedAlarmIDs = Set((try? AlarmManager.shared.alarms.map(\.id)) ?? [])
        for alarmID in trackedAlarmIDs {
            try? AlarmManager.shared.cancel(id: alarmID)
        }
        #endif
    }

    private func cancelSystemAlarm(id alarmID: UUID) {
        #if canImport(AlarmKit)
        try? AlarmManager.shared.cancel(id: alarmID)
        #endif
    }
    
    private func playMockAlarmSound() {
        // Mock a physical systemic alarm overriding the device speakers
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            AudioServicesPlayAlertSound(SystemSoundID(1005))

            // Vibrate loop fallback
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            // Stop after 30 seconds for sanity
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                timer.invalidate()
            }
        } catch {
            print("Failed to initialize physical alarm audio layer: \(error)")
        }
    }
    
    // MARK: - Post-Alarm Feedback
    
    func playPostAlarmFeedback(minutesSaved: Int) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            let message = "Buongiorno, ti ho svegliato \(minutesSaved) minuti prima del tuo limite massimo perché il tuo ciclo era al picco di efficienza."
            let utterance = AVSpeechUtterance(string: message)
            
            // Prefer an Italian voice since the dialog is in Italian.
            if let voice = AVSpeechSynthesisVoice(language: "it-IT") {
                utterance.voice = voice
            }
            
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.volume = 1.0
            
            speechSynthesizer.speak(utterance)
        } catch {
            print("Failed to configure audio session for post-alarm feedback: \(error)")
        }
    }

    private func normalizedWakeUpDate(from requestedWakeUpDate: Date) -> Date {
        guard requestedWakeUpDate <= Date() else {
            return requestedWakeUpDate
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: requestedWakeUpDate) ?? requestedWakeUpDate
    }

    private func monitoringStartDate(for wakeUpDate: Date) -> Date {
        wakeUpDate.addingTimeInterval(-Self.monitoringLeadTime)
    }
}

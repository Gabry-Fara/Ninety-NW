import Foundation
import Combine
import UserNotifications
import AVFoundation
import AudioToolbox

#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
class SmartAlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SmartAlarmManager()
    static let monitoringLeadTime: TimeInterval = 30 * 60

    struct ScheduledSleepSession {
        let wakeUpDate: Date
        let monitoringStartDate: Date
    }
    
    @Published var alarmStatus: String = "No alarms configured."
    @Published var monitoringCountdown: String = ""
    
    private var absoluteAlarmID: UUID?
    private var monitoringTimer: Timer?   // fires when the 30-min tracking window opens
    private var countdownTimer: Timer?    // updates the countdown string every second
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
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
    
    private func createDefaultAttributes() -> AlarmAttributes<NinetyAlarmMetadata> {
        let presentation = AlarmPresentation(
            alert: .init(title: "Ninety Wake Up")
        )
        return AlarmAttributes(presentation: presentation, tintColor: .blue)
    }
    #endif

    func scheduleSleepSession(endingAt requestedWakeUpDate: Date) -> ScheduledSleepSession {
        let wakeUpDate = normalizedWakeUpDate(from: requestedWakeUpDate)
        let monitoringStartDate = monitoringStartDate(for: wakeUpDate)
        scheduleSystemAlarm(for: wakeUpDate)
        return ScheduledSleepSession(wakeUpDate: wakeUpDate, monitoringStartDate: monitoringStartDate)
    }
    
    func cancelSession() {
        Task {
            await cancelSessionNow()
        }
    }

    func cancelSessionNow() async {
        await clearScheduledSession(resetStatus: true)
    }

    func rescheduleSystemAlarm(for targetDate: Date) async {
        await clearScheduledSession(resetStatus: false)
        await scheduleSystemAlarmAfterClearing(for: targetDate)
    }

    private func clearScheduledSession(resetStatus: Bool) async {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        monitoringCountdown = ""

        let previousAlarmID = absoluteAlarmID
        absoluteAlarmID = nil

        if let alarmID = previousAlarmID {
            #if canImport(AlarmKit)
            try? AlarmManager.shared.cancel(id: alarmID)
            #endif
        }

        SleepSessionManager.shared.syncAlarmState(targetDate: nil)
        SleepSessionManager.shared.pauseWatchMonitoring()

        if resetStatus {
            self.alarmStatus = "No alarms configured."
        }
    }
    
    func scheduleSystemAlarm(for targetDate: Date) {
        Task {
            await rescheduleSystemAlarm(for: targetDate)
        }
    }

    private func scheduleSystemAlarmAfterClearing(for targetDate: Date) async {
        let alarmID = UUID()
        self.absoluteAlarmID = alarmID

        SleepSessionManager.shared.syncAlarmState(targetDate: targetDate)

        let monitoringStart = monitoringStartDate(for: targetDate)
        let now = Date()

        // Cancel any previous pending monitoring timer
        monitoringTimer?.invalidate()
        countdownTimer?.invalidate()

        SleepSessionManager.shared.startWatchSession(targetDate: targetDate)

        if monitoringStart <= now {
            // We're already inside the 30-min window — start immediately
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
            ? "🟢 Tracking window open | Failsafe: \(targetDate.formatted(date: .omitted, time: .shortened))"
            : "⏳ Failsafe: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"

        #if canImport(AlarmKit)
        do {
            let configuration = AlarmManager.AlarmConfiguration(
                schedule: .fixed(targetDate),
                attributes: createDefaultAttributes()
            )
            _ = try await AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
            self.alarmStatus = self.alarmStatus.contains("🟢")
                ? "🟢 Tracking window open | ✅ Failsafe set: \(targetDate.formatted(date: .omitted, time: .shortened))"
                : "⏳ ✅ Failsafe set: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"
        } catch {
            self.alarmStatus = "System Alarm Schedule failed: \(error)"
        }
        #else
        self.alarmStatus = "[Sim] Failsafe: \(targetDate.formatted(date: .omitted, time: .shortened)) | Open Watch once before sleep"
        #endif
    }
    
    // Layer Two: The Dynamic Heuristic Trigger
    func triggerDynamicAlarm() {
        self.alarmStatus = "🚨 DYNAMIC WAKE EVENT TRIGGERED VIA ALARMKIT!"
        SleepSessionManager.shared.pauseWatchMonitoring()
        SleepSessionManager.shared.triggerWatchHapticWakeUp()
        
        // Clean up the Layer 1 failsafe alarm after Layer 2 has fired
        if let oldID = absoluteAlarmID {
            #if canImport(AlarmKit)
            Task {
                try? AlarmManager.shared.cancel(id: oldID)
            }
            #endif
            absoluteAlarmID = nil
        }
        
        #if canImport(AlarmKit)
        Task {
            do {
                // Layer 2 (Dynamic Heuristic Trigger) — near-immediate fire
                let targetTime = Date().addingTimeInterval(2) // AlarmKit requires at least a few seconds in the future
                let configuration = AlarmManager.AlarmConfiguration(
                    schedule: .fixed(targetTime),
                    attributes: createDefaultAttributes()
                )
                _ = try await AlarmManager.shared.schedule(id: UUID(), configuration: configuration)
                self.alarmStatus = "✅ Livello 2 Executed! 🔥 Waking User!"
            } catch {
                self.alarmStatus = "Dynamic execution failed: \(error)"
            }
        }
        #else
        self.alarmStatus = "[Mock] Livello 2 Executed! 🔥 Waking User!"
        
        Task {
            let content = UNMutableNotificationContent()
            content.title = "NINETY: OPTIMAL WAKE TIME!"
            content.body = "You are in a light sleep phase. Wake up now!"
            content.sound = .defaultCritical
            
            // Add a slight delay to ensure the request processes safely if tapped quickly
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            do {
                let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed mock notification: \(error)")
            }
            
            self.playMockAlarmSound()
        }
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

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
    
    @Published var alarmStatus: String = "No alarms configured."
    
    private var absoluteAlarmID: UUID?
    private var audioPlayer: AVAudioPlayer?
    
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
    
    func scheduleSystemAlarm(for targetDate: Date) {
        let alarmID = UUID()
        self.absoluteAlarmID = alarmID
        self.alarmStatus = "Absolute Failsafe Set for \(targetDate.formatted(date: .omitted, time: .shortened))"
        SleepSessionManager.shared.startWatchSession(targetDate: targetDate)
        
        #if canImport(AlarmKit)
        Task {
            do {
                // Livello 1 (Failsafe Assoluto)
                let configuration = AlarmManager.AlarmConfiguration(
                    schedule: .fixed(targetDate), 
                    attributes: createDefaultAttributes()
                )
                try await AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
                self.alarmStatus = "✅ Active Failsafe Alarm Scheduled in System"
            } catch {
                self.alarmStatus = "System Alarm Schedule failed: \(error)"
            }	
        }
        #else
        self.alarmStatus = "[Mock] Failsafe Alarm Scheduled for \(targetDate.formatted(date: .omitted, time: .shortened))"
        #endif
    }
    
    // Layer Two: The Dynamic Heuristic Trigger
    func triggerDynamicAlarm() {
        self.alarmStatus = "🚨 DYNAMIC WAKE EVENT TRIGGERED VIA ALARMKIT!"
        SleepSessionManager.shared.pauseWatchMonitoring()
        
        // Pulizia chirurgica della sveglia di Livello 1 dopo che Livello 2 è scattata
        if let oldID = absoluteAlarmID {
            #if canImport(AlarmKit)
            Task {
                try? await AlarmManager.shared.cancel(id: oldID)
            }
            #endif
            absoluteAlarmID = nil
        }
        
        #if canImport(AlarmKit)
        Task {
            do {
                // Livello 2 (Trigger Euristico Dinamico) a zero secondi (modifica la precedente/trigger immediato)
                let targetTime = Date().addingTimeInterval(2) // Devi assegnare almeno qualche secondo nel futuro
                let configuration = AlarmManager.AlarmConfiguration(
                    schedule: .fixed(targetTime),
                    attributes: createDefaultAttributes()
                )
                try await AlarmManager.shared.schedule(id: UUID(), configuration: configuration)
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
            
            // If there's an actual specific sound file in bundle, use it. Otherwise, use system vibrate + generic alert
            if let url = Bundle.main.url(forResource: "WakeUpChime", withExtension: "m4a") ?? Bundle.main.url(forResource: "WakeUpChime", withExtension: "mp3") {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // loop infinitely
                audioPlayer?.play()
            } else {
                // Fallback hardware alarm integration when custom audio file isn't present
                AudioServicesPlayAlertSound(1005) // Standard iOS Alarm / Calypso Sound
                
                // Vibrate loop fallback
                let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                // Stop after 30 seconds for sanity
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    timer.invalidate()
                }
            }
        } catch {
            print("Failed to initialize physical alarm audio layer: \(error)")
        }
    }
}

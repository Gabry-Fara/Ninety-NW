//
//  SettingsViewModel.swift
//  Ninety
//
//  Created by Deimante Valunaite on 11/07/2024.
//

import SwiftUI
import UserNotifications

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case night = "Night"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .night: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

class SettingsViewModel: ObservableObject {
    @AppStorage("appTheme") var selectedTheme: AppTheme = .system
    
    // Smart Alarm configuration
    @AppStorage("smartWakeWindow") var smartWakeWindow: Int = 30 // minutes before alarm to start sensing
    @AppStorage("hapticAlarm") var hapticAlarm: Bool = true // vibrate gently before ringing
    @AppStorage("saveToHealthKit") var saveToHealthKit: Bool = true // save sleep data
    
    @AppStorage("isNotificationsEnabled") var isNotificationsEnabled: Bool = false {
        didSet {
            if isNotificationsEnabled {
                enableNotifications()
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    private func enableNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isNotificationsEnabled = true
                } else {
                    self.isNotificationsEnabled = false
                }
            }
        }
    }
}

//
//  NinetyApp.swift
//  Ninety
//
//  Created by Deimante Valunaite on 07/07/2024.
//

import SwiftUI

@main
struct NinetyApp: App {
    
    init() {
        // Core initialization to bind WCSession & UNUserNotification delegates immediately on launch.
        // If these are not instantly mapped, WCSession cannot wake the iOS app from suspended states!
        _ = SleepSessionManager.shared
        _ = SmartAlarmManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ScheduleView()
        }
    }
}

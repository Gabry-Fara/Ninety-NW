# Ninety Master Guide

## Build & Test Commands
- **IDE:** This is a standard Xcode project. Open `Ninety.xcodeproj` and build the `Ninety` and `NinetyWatch Watch App` schemes.
- **CLI Build (iOS):** `xcodebuild -project Ninety.xcodeproj -scheme Ninety -destination 'generic/platform=iOS'`
- **CLI Build (watchOS):** `xcodebuild -project Ninety.xcodeproj -scheme "NinetyWatch Watch App" -destination 'generic/platform=watchOS'`

## Architecture
- **Primary Pattern:** Model-View-ViewModel (MVVM) in SwiftUI.
- **Dependency Injection:** The project currently relies heavily on Singletons (`.shared` instances like `SleepSessionManager.shared`, `SmartAlarmManager.shared`) rather than pure DI via Swift properties/initializers.
- **Initialization:** Core singletons (`SleepSessionManager` and `SmartAlarmManager`) are initialized at app launch in the `@main` App struct to bind `WCSession` and `UNUserNotification` delegates immediately for background wake-ups.

## Tech Stack
- **Languages:** Swift 5.0
- **UI Framework:** SwiftUI
- **Deployment Targets:** iOS 26.0 watchOS 26.0
- **Key Frameworks:** 
  - `AlarmKit` (iOS 26 / Next-Gen)
  - `HealthKit`, `CoreMotion` (`CMMotionManager` for accelerometer)
  - `WatchConnectivity` (`WCSessionDelegate`)
  - `AppIntents` / `AppShortcutsProvider` (Siri Integration)

## Coding Standards
- **Naming Conventions:** Standard Swift CamelCase for variables/functions, PascalCase for Types/Structs/Classes. Use `ViewModel` suffix for ObservableObjects.
- **State Management:** Leverage `@MainActor` on ViewModels, `@Published` for reactive properties, and `@AppStorage` for persistent preferences like AppTheme.
- **Error Handling:** Standard Swift concurrency (`async/await`) and safe property unwrapping. Strings are predominantly used for `schedulingError` state propagation to user interfaces.
- **Background Integrity:** Ensure `defer` blocks are used for lock-like state properties (e.g., `isScheduling`). 

## Knowledge Retrieval
- **Architectural Queries:** Before scanning individual files, ALWAYS read `graphify-out/GRAPH_REPORT.md` to understand the system topology and "God Node" relationships.
- **Cross-Module Logic:** Use the "Suggested Questions" in the graph report to identify potential coupling risks when modifying `SleepSessionManager` or `WatchSensorManager`.
- **System Map:** If you are unsure how a new feature (like `LiquidGlass`) fits in, refer to the graph's Community Bridges section.

## Graph Context (System Topology)
Based on the `graphify-out` abstraction analysis:
- **God Nodes (Core Abstractions):** `SleepSessionManager` and `WatchSensorManager` are the central arteries routing data from the watch edge node to the view models and the smart alarm system.
- **Distributed Smart Alarm Pipeline:** Encompasses `EdgeSensorNode` -> `WatchConnectivity` -> `iPhone Compute Node` -> `AlarmKit`.
- **Background Execution Stack:** Heavily reliant on `WKExtendedRuntimeSession` on watchOS, daisy-chain background tasks, and `UIBackgroundTaskIdentifier` on iOS to maintain connectivity while sleeping.
- **Community Bridges:** Ensure stability in cross-communication logic inside `SleepSessionManager`, as it connects Sleep Inference, Schedule ViewModels, Smart Alarm Siri Integration, and Watch Edge components.

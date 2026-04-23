//
//  ContentView.swift
//  NinetyWatch Watch App
//
//  Created by Cristian on 02/04/26.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var sensorManager = WatchSensorManager.shared
    @StateObject private var hapticManager = HapticWakeUpManager.shared

    private var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }

    private var currentState: WatchScreenState {
        let state = sensorManager.sessionState.lowercased()

        if state.contains("error") || state.contains("invalidated") {
            return .error
        }

        if state.contains("started") || state.contains("active") || state.contains("monitoring") || state.contains("avviata") {
            return .active
        }

        if sensorManager.nextAlarmDate != nil || sensorManager.hasPendingSchedule {
            return .scheduled
        }

        return .idle
    }

    var body: some View {
        ZStack {
            TabView {
                // Tab 1: Main Status UI
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Spacer()
                    nextAlarmCard
                    Spacer()
                    footerStatus
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                // Tab 2: Debug Node
                DebugNodeView(sensorManager: sensorManager)
            }
            .tabViewStyle(.verticalPage)
            .background(Color.black.ignoresSafeArea())
            
            if hapticManager.isPlaying {
                AlarmView()
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .onAppear {
            sensorManager.refreshStoredAlarmStateIfNeeded()
            sensorManager.requestHealthPermissions { _ in }
        }
    }

    private var header: some View {
        HStack {
            Text(copy.text(.appName))
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    private var nextAlarmCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(copy.text(.wakeUpBy))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(nextAlarmPrimaryText)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            if let secondaryText = nextAlarmSecondaryText {
                Text(secondaryText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var footerStatus: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(footerStatusColor)
                .frame(width: 6, height: 6)

            Text(footerStatusLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }

    private var nextAlarmPrimaryText: String {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            return copy.text(.noActiveAlarms)
        }

        return formattedAlarm(date: nextAlarmDate).primary
    }

    private var nextAlarmSecondaryText: String? {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            return sensorManager.hasPendingSchedule ? copy.text(.openWatchToArm) : copy.text(.setOnIPhone)
        }

        let formatted = formattedAlarm(date: nextAlarmDate)

        switch currentState {
        case .active:
            return copy.text(.monitoring)
        case .scheduled:
            return formatted.secondary
        case .error:
            return sensorManager.sessionState
        case .idle:
            return copy.text(.waiting)
        }
    }

    private func formattedAlarm(date: Date) -> (primary: String, secondary: String?) {
        let calendar = Calendar.autoupdatingCurrent
        let locale = Locale.autoupdatingCurrent
        let time = date.formatted(Date.FormatStyle().locale(locale).hour().minute())

        if calendar.isDateInToday(date) {
            return ("\(copy.text(.today)) · \(time)", nil)
        }

        if calendar.isDateInTomorrow(date) {
            return ("\(copy.text(.tomorrow)) · \(time)", nil)
        }

        let weekdayFormatter = Date.FormatStyle()
            .locale(locale)
            .weekday(.wide)
            
        let dayName = date.formatted(weekdayFormatter).capitalized
        
        let dateSecondaryFormatter = Date.FormatStyle()
            .locale(locale)
            .day()
            .month()

        return ("\(dayName) · \(time)", date.formatted(dateSecondaryFormatter))
    }

    private var footerStatusLabel: String {
        switch sensorManager.connectivityState {
        case .synced:
            return copy.text(.synced)
        case .queued:
            return copy.text(.queued)
        case .watchOnly:
            return copy.text(.watchOnly)
        }
    }

    private var footerStatusColor: Color {
        switch sensorManager.connectivityState {
        case .synced:
            return .green
        case .queued:
            return .yellow
        case .watchOnly:
            return .orange
        }
    }
}

// MARK: - Debug View

struct DebugNodeView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("🛠 Debug Node")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session: \(sensorManager.sessionState)")
                        .foregroundColor(.blue)
                    Text("Link: \(sensorManager.connectionStatus)")
                        .foregroundColor(.secondary)
                    
                    if sensorManager.hasPendingSchedule, let pending = sensorManager.pendingScheduleDescription {
                        Text("Queue: \(pending)")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption2)
                
                Divider()
                
                if !sensorManager.lastPayloadSent.isEmpty {
                    Text("Last Payload:")
                        .font(.caption2.bold())
                    Text(sensorManager.lastPayloadSent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Manual overrides for testing routing
                Group {
                    Button("Simulate Start (5s)") {
                        sensorManager.scheduleSmartAlarmSession(at: Date().addingTimeInterval(5))
                    }
                    .tint(.green)
                    
                    Button("Force Stop Session") {
                        sensorManager.stopSession()
                    }
                    .tint(.red)
                }
                .font(.caption)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

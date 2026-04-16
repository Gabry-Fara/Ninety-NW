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
    
    var body: some View {
        TabView {
            DashboardView(sensorManager: sensorManager)
                .containerBackground(.background, for: .tabView)
            ControlsView(sensorManager: sensorManager)
                .containerBackground(.background, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            sensorManager.requestHealthPermissions { _ in }
            // Triggering the extended runtime session init off the main thread prompts user without freezing
            DispatchQueue.global().async {
                let preloadSession = WKExtendedRuntimeSession()
                preloadSession.invalidate()
            }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var sensorManager: WatchSensorManager

    private var isInteractiveDeliveryAvailable: Bool {
        sensorManager.connectionStatus == "Phone reachable" || sensorManager.connectionStatus.hasPrefix("Syncing")
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isInteractiveDeliveryAvailable ? "link.icloud.fill" : "exclamationmark.icloud.fill")
                .font(.system(size: 40))
                .foregroundColor(isInteractiveDeliveryAvailable ? .green : .orange)
                .symbolEffect(.pulse, isActive: isInteractiveDeliveryAvailable)
                .accessibilityLabel(isInteractiveDeliveryAvailable ? "Phone reachable" : "Phone unreachable")
            
            Text("Ninety Node")
                .font(.headline)
            
            VStack(spacing: 4) {
                Text(sensorManager.sessionState)
                    .font(.caption2.bold())
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                
                Text(sensorManager.connectionStatus)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            if let pendingScheduleDescription = sensorManager.pendingScheduleDescription {
                VStack(spacing: 4) {
                    Text("Action Required")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                    Text("\(pendingScheduleDescription)\nKeep the app open to arm Smart Alarm.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            if !sensorManager.lastPayloadSent.isEmpty {
                Text(sensorManager.lastPayloadSent)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .accessibilityLabel("Last sensor payload: \(sensorManager.lastPayloadSent)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ControlsView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    
    var body: some View {
        List {
            Section(header: Text("Session Control")) {
                if sensorManager.hasPendingSchedule {
                    Button(action: {
                        sensorManager.armPendingScheduleIfPossible()
                    }) {
                        HStack {
                            Image(systemName: "bolt.badge.clock.fill")
                            Text("Arm Queued Session")
                        }
                    }
                    .listItemTint(.orange)
                }

                Button(action: {
                    // Simulating scheduling 5 seconds from now for immediate testing
                    let futureDate = Date().addingTimeInterval(5)
                    sensorManager.scheduleSmartAlarmSession(at: futureDate)
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Simulate")
                    }
                }
                .listItemTint(.green)
                
                Button(action: {
                    sensorManager.stopSession()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop")
                    }
                }
                .listItemTint(.red)
            }
        }
    }
}

#Preview {
    ContentView()
}

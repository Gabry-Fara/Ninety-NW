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
            ControlsView(sensorManager: sensorManager)
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            sensorManager.setupWatchConnectivity()
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
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: sensorManager.connectionStatus == "Reachable" ? "link.icloud.fill" : "exclamationmark.icloud.fill")
                .font(.system(size: 40))
                .foregroundColor(sensorManager.connectionStatus == "Reachable" ? .green : .orange)
                .symbolEffect(.pulse, isActive: sensorManager.connectionStatus == "Reachable")
            
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
            
            if !sensorManager.lastPayloadSent.isEmpty {
                Text(sensorManager.lastPayloadSent)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
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

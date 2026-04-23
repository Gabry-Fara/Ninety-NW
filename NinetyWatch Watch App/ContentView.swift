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
    
    // Abstract indicator of WCSession health to mitigate LOS (Loss of Signal) risk
    private var isConnected: Bool {
        sensorManager.connectionStatus == "Phone reachable" || sensorManager.connectionStatus.hasPrefix("Syncing")
    }
    
    var body: some View {
        ZStack {
            TabView {
                minimalistNodeView
                DebugNodeView(sensorManager: sensorManager)
            }
            .tabViewStyle(.verticalPage)
            
            if hapticManager.isPlaying {
                AlarmView()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .background(Color.black)
        .onAppear {
            sensorManager.requestHealthPermissions { _ in }
            // CoreMotion and permissions handled below
        }
    }
    
    private var minimalistNodeView: some View {
        VStack(spacing: 8) {
            // Minimalist Connectivity Indicator
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: isConnected ? .green : .red, radius: 4)
                .padding(.bottom, 4)
            
            // Minimalist Status Text
            Text(statusMessage)
                .font(.footnote)
                .foregroundColor(isConnected ? .white : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var statusMessage: String {
        // If there's an active session or a queued schedule, display its status cleanly.
        if sensorManager.hasPendingSchedule, let pending = sensorManager.pendingScheduleDescription {
            return "Sveglia attiva entro le \(pending)"
        }
        
        // Check for active text
        let state = sensorManager.sessionState.lowercased()
        if state.contains("running") || state.contains("active") {
            return "Monitoraggio ciclo attivo"
        }
        
        return "Ninety in attesa..."
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

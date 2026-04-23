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
    
    // Abstract indicator of WCSession health to mitigate LOS (Loss of Signal) risk
    private var isConnected: Bool {
        sensorManager.connectionStatus == "Phone reachable" || sensorManager.connectionStatus.hasPrefix("Syncing")
    }
    
    var body: some View {
        TabView {
            minimalistNodeView
            DebugNodeView(sensorManager: sensorManager)
        }
        .tabViewStyle(.verticalPage)
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
        if sensorManager.hasPendingSchedule, let pending = sensorManager.pendingScheduleDescription {
            return "Apri Ninety una volta prima di dormire. \(pending)"
        }

        if sensorManager.hasArmedSchedule, let armed = sensorManager.armedScheduleDescription {
            return "Smart Alarm pronta. \(armed)"
        }
        
        let state = sensorManager.sessionState.lowercased()
        if state.contains("recording") || state.contains("started") || state.contains("running") || state.contains("active") {
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

                    if sensorManager.hasArmedSchedule, let armed = sensorManager.armedScheduleDescription {
                        Text("Armed: \(armed)")
                            .foregroundColor(.green)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

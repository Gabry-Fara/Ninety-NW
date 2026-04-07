//
//  ContentView.swift
//  NinetyWatch Watch App
//
//  Created by Cristian on 02/04/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sensorManager = WatchSensorManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Ninety Watch Node")
                    .font(.headline)
                
                HStack {
                    Text("State:")
                    Spacer()
                    Text(sensorManager.sessionState)
                        .foregroundColor(.blue)
                }
                .font(.footnote)
                
                HStack {
                    Text("Tx:")
                    Spacer()
                    Text(sensorManager.connectionStatus)
                        .foregroundColor(sensorManager.connectionStatus == "Reachable" ? .green : .orange)
                }
                .font(.footnote)
                
                Text(sensorManager.lastPayloadSent)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
                
                Button("Start Simulated Session") {
                    // Simulating scheduling 5 seconds from now for immediate testing
                    let futureDate = Date().addingTimeInterval(5)
                    sensorManager.scheduleSmartAlarmSession(at: futureDate)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("Stop Session") {
                    sensorManager.stopSession()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
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

#Preview {
    ContentView()
}

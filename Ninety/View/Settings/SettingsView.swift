//
//  SettingsView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State var hours: Int = 0
    @State var minutes: Int = 0
    
    var body: some View {
        Form {
//            Section(header: Text("Profile")) {
//                HStack {
//                    Image(systemName: "person.circle.fill")
//                        .foregroundStyle(.tint)
//                        .font(.title2)
//                    TextField("Username", text: $settingsViewModel.username)
//                }
//                
//                HStack {
//                    Image(systemName: "envelope.fill")
//                        .foregroundStyle(.tint)
//                        .font(.title2)
//                    TextField("Email", text: $settingsViewModel.email)
//                        .keyboardType(.emailAddress)
//                        .autocapitalization(.none)
//                }
//                
//                Toggle(isOn: $settingsViewModel.isNotificationsEnabled) {
//                    Label("Notifications", systemImage: "bell.badge.fill")
//                }
//                .tint(.accentColor)
//            }
            
            Section(header: Text("Appearance")) {
                Picker(selection: $settingsViewModel.selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.rawValue, systemImage: theme.icon)
                            .tag(theme)
                    }
                } label: {
                    Label("Theme", systemImage: "paintbrush.fill")
                }
                .pickerStyle(.navigationLink)
            }
            
//            Section(header: Text("Sleeping Preferences")) {
//                NavigationLink(destination: EmptyView()) {
//                    Label("Achievements", systemImage: "star.fill")
//                }
//                
//                Picker(selection: $hours) {
//                    ForEach(0..<12, id: \.self) { i in
//                        Text("\(i) hours").tag(i)
//                    }
//                } label: {
//                    Label("Hour Goal", systemImage: "target")
//                }
//                .pickerStyle(.menu)
//                
//                Picker(selection: $minutes) {
//                    ForEach(0..<60, id: \.self) { i in
//                        Text("\(i) min").tag(i)
//                    }
//                } label: {
//                    Label("Minute Goal", systemImage: "clock")
//                }
//                .pickerStyle(.menu)
//            }
            
            Section(header: Text("General")) {
                NavigationLink(destination: EmptyView()) {
                    Label("About", systemImage: "info.circle.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    SettingsView()
}

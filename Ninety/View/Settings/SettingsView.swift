//
//  SettingsView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 24) {
                VStack(spacing: 32) {
                    
                    // Smart Alarm Section
                    settingsSection("SMART ALARM") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "timer", color: .blue, title: "Wake Window") {
                                Picker("Wake Window", selection: $settingsViewModel.smartWakeWindow) {
                                    Text("15 min").tag(15)
                                    Text("30 min").tag(30)
                                    Text("45 min").tag(45)
                                    Text("60 min").tag(60)
                                }
                                .labelsHidden()
                                .tint(.secondary)
                            }
                            
                            Divider().padding(.leading, 44)
                            
                            settingsToggleRow(icon: "water.waves", color: .indigo, title: "Haptic Pre-Alarm", isOn: $settingsViewModel.hapticAlarm)
                        }
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPEARANCE")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            
                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        settingsViewModel.selectedTheme = theme
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: theme.icon)
                                            .font(.title2)
                                        Text(theme.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                                .buttonStyle(GlassButtonStyle(
                                    isProminent: settingsViewModel.selectedTheme == theme,
                                    tint: settingsViewModel.selectedTheme == theme ? .blue : nil
                                ))
                            }
                        }
                    }
                    
                    // Permissions Section
                    settingsSection("PERMISSIONS") {
                        VStack(spacing: 0) {
                            settingsToggleRow(icon: "bell.badge.fill", color: .red, title: "Notifications", isOn: $settingsViewModel.isNotificationsEnabled)
                            
                            Divider().padding(.leading, 44)
                            
                            settingsToggleRow(icon: "heart.text.square.fill", color: .pink, title: "Apple Health", isOn: $settingsViewModel.saveToHealthKit)
                        }
                    }
                    
                    // General Section
                    settingsSection("GENERAL") {
                        Button {
                            // Make action for 'About'
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                Text("About Ninety")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .background {
            HorizonBackground(isActive: false)
                .ignoresSafeArea()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        .onAppear {
            settingsViewModel.checkNotificationStatus()
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            
            content()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        }
    }
    
    @ViewBuilder
    private func settingsRow<Content: View>(icon: String, color: Color, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            content()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func settingsToggleRow(icon: String, color: Color, title: String, isOn: Binding<Bool>) -> some View {
        settingsRow(icon: icon, color: color, title: title) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.blue)
        }
    }
}

#Preview {
    SettingsView()
}

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
                        
                        VStack(spacing: 0) {
                            // Visual Previews
                            HStack(spacing: 40) {
                                Spacer()
                                // Light Preview
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        settingsViewModel.selectedTheme = .light
                                    }
                                } label: {
                                    ThemePreviewView(theme: .light, isSelected: settingsViewModel.selectedTheme == .light)
                                }
                                .buttonStyle(.plain)
                                
                                // Night Preview
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        settingsViewModel.selectedTheme = .night
                                    }
                                } label: {
                                    ThemePreviewView(theme: .night, isSelected: settingsViewModel.selectedTheme == .night)
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            .padding(.vertical, 24)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                            
                            Spacer().frame(height: 16)
                            
                            // Automatic Toggle
                            settingsSection("") {
                                settingsToggleRow(
                                    icon: "circle.lefthalf.filled",
                                    color: .primary,
                                    title: "Automatic",
                                    isOn: Binding(
                                        get: { settingsViewModel.selectedTheme == .system },
                                        set: { isOn in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if isOn {
                                                    settingsViewModel.selectedTheme = .system
                                                } else {
                                                    // Default to light if turning off automatic
                                                    settingsViewModel.selectedTheme = .light
                                                }
                                            }
                                        }
                                    )
                                )
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
private struct ThemePreviewView: View {
    let theme: AppTheme
    let isSelected: Bool

    private var previewGradient: LinearGradient {
        switch theme {
        case .system:
            return LinearGradient(
                colors: [Color(white: 0.92), Color(white: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                colors: [Color("F8FAFC"), Color("CBD5E1")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .night:
            return LinearGradient(
                colors: [Color("0F172A"), Color("1E3A8A")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var iconName: String {
        switch theme {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .night:
            return "moon.stars.fill"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(previewGradient)
                .frame(width: 96, height: 128)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .blue)
                            .padding(8)
                    }
                }
                .overlay {
                    VStack(spacing: 10) {
                        Circle()
                            .fill(.white.opacity(theme == .night ? 0.18 : 0.65))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: iconName)
                                    .foregroundStyle(theme == .night ? .white : .black.opacity(0.75))
                            }

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(theme == .night ? 0.16 : 0.55))
                            .frame(width: 56, height: 10)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(theme == .night ? 0.10 : 0.38))
                            .frame(width: 42, height: 10)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.16), lineWidth: isSelected ? 3 : 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 16, y: 10)

            Text(theme.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

//
//  SettingsView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showingAbout = false
    
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
                            settingsToggleRow(
                                icon: "circle.lefthalf.filled",
                                color: .primary,
                                title: "Automatic",
                                isOn: Binding(
                                    get: { settingsViewModel.selectedTheme == .system },
                                    set: { isOn in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            settingsViewModel.selectedTheme = isOn ? .system : .light
                                        }
                                    }
                                )
                            )
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
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
                            showingAbout = true
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
        .sheet(isPresented: $showingAbout) {
            AboutView()
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

// MARK: - About View

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HorizonBackground(isActive: false)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 16) {
                        Image("Logo design")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .accessibilityHidden(true)

                        VStack(spacing: 4) {
                            Text("Ninety")
                                .font(.title.bold())
                            Text("Version \(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Text("Smart sleep tracking powered by on-device ML. Your data stays on your devices.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .scrollContentBackground(.hidden)
            .containerBackground(.clear, for: .navigation)
        }
    }
}

private struct ThemePreviewView: View {
    let theme: AppTheme
    let isSelected: Bool

    private var previewBackground: some ShapeStyle {
        switch theme {
        case .light:
            return AnyShapeStyle(Color.white)
        case .night:
            return AnyShapeStyle(Color.black.opacity(0.92))
        case .system:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white, Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var accentColor: Color {
        switch theme {
        case .light:
            return .orange
        case .night:
            return .blue
        case .system:
            return .purple
        }
    }

    private var titleColor: Color {
        switch theme {
        case .light:
            return .black.opacity(0.8)
        case .night:
            return .white.opacity(0.9)
        case .system:
            return .primary
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(previewBackground)
                .overlay {
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule()
                            .fill(accentColor.opacity(0.9))
                            .frame(width: 42, height: 8)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(accentColor.opacity(theme == .light ? 0.18 : 0.28))
                            .frame(height: 26)

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor.opacity(0.85))
                                .frame(width: 8, height: 8)
                            Capsule()
                                .fill(titleColor.opacity(0.2))
                                .frame(width: 30, height: 8)
                        }
                    }
                    .padding(14)
                }
                .frame(width: 104, height: 148)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .blue)
                            .padding(10)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                }
                .shadow(color: .black.opacity(theme == .light ? 0.08 : 0.22), radius: 12, y: 6)

            Text(theme.rawValue)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}

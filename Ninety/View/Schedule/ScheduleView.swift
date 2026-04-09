//
//  ScheduleView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI
import UserNotifications

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
   
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sleep Wheel
                Section {
                    HStack {
                        Spacer()
                        SleepTimeSlider()
                            .padding(.vertical, 35)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // MARK: - Bedtime & Wake Up Summary
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Bedtime", systemImage: "moon.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(viewModel.getTime(angle: viewModel.startAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Wake Up", systemImage: "sun.max.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(viewModel.getTime(angle: viewModel.toAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Days of the Week
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active Days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(viewModel.daysOfWeek, id: \.id) { day in
                                Text(day.initial)
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(viewModel.selectedDays.contains(day.id) ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                    .foregroundStyle(viewModel.selectedDays.contains(day.id) ? Color.white : Color.primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            if viewModel.selectedDays.contains(day.id) {
                                                viewModel.selectedDays.remove(day.id)
                                            } else {
                                                viewModel.selectedDays.insert(day.id)
                                            }
                                        }
                                    }
                                    .accessibilityLabel("\(day.id)")
                                    .accessibilityAddTraits(viewModel.selectedDays.contains(day.id) ? .isSelected : [])
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // MARK: - Reminder
                Section(footer: Text("You'll receive a notification 30 minutes before your scheduled bedtime.")) {
                    Toggle(isOn: $viewModel.isReminderEnabled) {
                        Label("Bedtime Reminder", systemImage: "bell.badge.fill")
                    }
                    .tint(.accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        
                        Divider()
                        
                        Button {
                            showingDiagnostics = true
                        } label: {
                            Label("Diagnostics", systemImage: "ladybug")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.body.weight(.medium))
                    }
                    .accessibilityLabel("More Options")
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDiagnostics) {
                NavigationStack {
                    DiagnosticsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingDiagnostics = false
                                }
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ViewBuilder
    func SleepTimeSlider() -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                ZStack {
                    let numbers = [12, 15, 18, 21, 0, 3, 6, 9]
                    
                    ForEach(numbers.indices, id: \.self) { index in
                        Text("\(numbers[index])")
                            .foregroundStyle(.secondary)
                            .font(.caption2.weight(.medium))
                            .rotationEffect(.init(degrees: Double(index) * -45))
                            .offset(y: (width - 90) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 45 ))
                    }
                }
                
                Circle()
                    .stroke(Color(UIColor.quaternarySystemFill), lineWidth: 40)
                
                let reverseRotation = (viewModel.startProgress > viewModel.toProgress) ? -Double((1 - viewModel.startProgress) * 360) : 0
                
                Circle()
                    .trim(from: viewModel.startProgress > viewModel.toProgress ? 0 : viewModel.startProgress, to: viewModel.toProgress + (-reverseRotation / 360))
                    .stroke(Color.accentColor, style:
                                StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.init(degrees: -90))
                    .rotationEffect(.init(degrees: reverseRotation))
                
                // Bedtime Handle
                Image(systemName: "moon.stars.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -viewModel.startAngle))
                    .background(Color(UIColor.systemBackground), in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: viewModel.startAngle))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.onDrag(value: value, fromSlider: true)
                            }
                    )
                    .rotationEffect(.init(degrees: -90))
                    .accessibilityLabel("Bedtime")
                    .accessibilityValue(viewModel.getTime(angle: viewModel.startAngle).formatted(date: .omitted, time: .shortened))
                
                // Wake Up Handle
                Image(systemName: "alarm.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -viewModel.toAngle))
                    .background(Color(UIColor.systemBackground), in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: viewModel.toAngle))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.onDrag(value: value)
                            }
                    )
                    .rotationEffect(.init(degrees: -90))
                    .accessibilityLabel("Wake up")
                    .accessibilityValue(viewModel.getTime(angle: viewModel.toAngle).formatted(date: .omitted, time: .shortened))
                
                VStack(spacing: 4) {
                    Text("\(viewModel.getTimeDifference().0)h \(viewModel.getTimeDifference().1)m")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: screenBounds().width / 1.8, height: screenBounds().width / 1.8)
    }
}

extension View {
    func screenBounds() -> CGRect {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.screen.bounds ?? UIScreen.main.bounds
    }
}

#Preview {
    ScheduleView()
}

//
//  HomeView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI
import UserNotifications

struct HomeView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @ObservedObject private var sleepManager = SleepSessionManager.shared
   
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        SleepTimeSlider()
                            .padding(.vertical, 35) // Increased padding to prevent stroke clipping
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Bedtime", systemImage: "moon.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(homeViewModel.getTime(angle: homeViewModel.startAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Wake up", systemImage: "sun.max.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .labelStyle(.titleAndIcon) // Force trailing icon by flipping? Keep default for now.
                            Text(homeViewModel.getTime(angle: homeViewModel.toAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Live Sleep Stage")) {
                    HStack {
                        Label("Official Stage", systemImage: "waveform.path.ecg")
                        Spacer()
                        Text(sleepManager.officialStageDisplay)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Latest Epoch", systemImage: "clock.badge")
                        Spacer()
                        Text(sleepManager.latestEpochSummary)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.caption)
                }
                
                Section(header: Text("Schedule")) {
                    HStack(spacing: 8) {
                        ForEach(homeViewModel.daysOfWeek, id: \.id) { day in
                            Text(day.initial)
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(homeViewModel.selectedDays.contains(day.id) ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(homeViewModel.selectedDays.contains(day.id) ? Color.white : Color.primary)
                                .clipShape(Circle())
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if homeViewModel.selectedDays.contains(day.id) {
                                            homeViewModel.selectedDays.remove(day.id)
                                        } else {
                                            homeViewModel.selectedDays.insert(day.id)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                Section {
                    Toggle(isOn: $homeViewModel.isReminderEnabled) {
                        Label("Remind me to sleep", systemImage: "bed.double.fill")
                    }
                    .tint(.accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ninety")
            .toolbar {
                NavigationLink {
                    SleepChartView()
                } label: {
                    Label("Calendar", systemImage: "calendar")
                }
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
                            .foregroundColor(.secondary)
                            .font(.caption2.weight(.medium))
                            .rotationEffect(.init(degrees: Double(index) * -45))
                            .offset(y: (width - 90) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 45 ))
                    }
                }
                
                Circle()
                    .stroke(Color(UIColor.quaternarySystemFill), lineWidth: 40)
                
                let reverseRotation = (homeViewModel.startProgress > homeViewModel.toProgress) ? -Double((1 - homeViewModel.startProgress) * 360) : 0
                
                Circle()
                    .trim(from: homeViewModel.startProgress > homeViewModel.toProgress ? 0 : homeViewModel.startProgress, to: homeViewModel.toProgress + (-reverseRotation / 360))
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
                    .rotationEffect(.init(degrees: -homeViewModel.startAngle))
                    .background(Color(UIColor.systemBackground), in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: homeViewModel.startAngle))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                homeViewModel.onDrag(value: value, fromSlider: true)
                            }
                    )
                    .rotationEffect(.init(degrees: -90))
                
                // Wakeup Handle
                Image(systemName: "bell.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -homeViewModel.toAngle))
                    .background(Color(UIColor.systemBackground), in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: homeViewModel.toAngle))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                homeViewModel.onDrag(value: value)
                            }
                    )
                    .rotationEffect(.init(degrees: -90))
                
                VStack(spacing: 4) {
                    Text("\(homeViewModel.getTimeDifference().0)h \(homeViewModel.getTimeDifference().1)m")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
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
    HomeView()
}

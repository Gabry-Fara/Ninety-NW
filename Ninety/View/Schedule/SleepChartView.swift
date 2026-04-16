//
//  SleepChartView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 22/07/2024.
//

import Charts
import SwiftUI

struct SleepChartView: View {
    // Uses environment object — same data as ScheduleView, not a fresh instance
    @EnvironmentObject private var viewModel: ScheduleViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Picker("Time View", selection: $viewModel.timeView) {
                    ForEach(TimeView.allCases, id: \.self) { view in
                        Text(view.rawValue.capitalized).tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.timeView) { _, _ in
                    viewModel.filterSleepData()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("HOURS OF SLEEP")
                        .font(.caption.bold())
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    Chart {
                        RuleMark(y: .value("Goal", 7.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .annotation(alignment: .leading) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.secondary.opacity(0.6))

                        ForEach(viewModel.filteredSleepData) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Sleep Duration", data.sleepDuration)
                            )
                            .foregroundStyle(.blue.gradient)
                            .cornerRadius(6)
                        }
                    }
                    .frame(height: 260)
                    .chartYScale(domain: 0...10)
                    .chartYAxis {
                        AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let hours = value.as(Int.self) {
                                    Text("\(hours)h")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background {
            HorizonBackground(isActive: false)
                .ignoresSafeArea()
        }
        .navigationTitle("Sleep History")
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
    }
}

#Preview {
    NavigationStack {
        SleepChartView()
            .environmentObject(ScheduleViewModel())
    }
}

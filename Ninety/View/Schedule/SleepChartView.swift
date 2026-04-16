import Charts
import SwiftUI

struct SleepChartView: View {
    private enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    private struct ChartSleepData: Identifiable {
        let id = UUID()
        let date: Date
        let duration: Double
    }

    @State private var timeRange: TimeRange = .week

    private var displayedData: [ChartSleepData] {
        let allData = sampleData
        switch timeRange {
        case .week:
            return Array(allData.suffix(7))
        case .month:
            return allData
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Chart {
                RuleMark(y: .value("Goal", 7.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(alignment: .leading) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                ForEach(displayedData) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Sleep Duration", data.duration)
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
            .frame(height: 300)
            .chartYScale(domain: 0...8)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Sleep History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sampleData: [ChartSleepData] {
        [
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 13), duration: 7.1),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 12), duration: 7.4),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 11), duration: 6.8),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 10), duration: 7.9),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 9), duration: 8.0),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 8), duration: 6.9),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 7), duration: 7.3),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 6), duration: 7.0),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 5), duration: 6.5),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 4), duration: 8.0),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 3), duration: 7.5),
            ChartSleepData(date: Date().addingTimeInterval(-86400 * 2), duration: 6.0),
            ChartSleepData(date: Date().addingTimeInterval(-86400), duration: 7.2),
            ChartSleepData(date: Date(), duration: 8.0)
        ]
    }
}

#Preview {
    NavigationStack {
        SleepChartView()
    }
}

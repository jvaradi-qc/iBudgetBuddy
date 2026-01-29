import SwiftUI
import Charts

struct DailyTrendChartView: View {
    @ObservedObject var viewModel: ReportsViewModel

    var body: some View {
        Chart {
            ForEach(viewModel.dailyTrend) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Net", point.net)
                )
                .foregroundStyle(point.net >= 0 ? .green : .red)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(.gray.opacity(0.3))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding()
    }
}

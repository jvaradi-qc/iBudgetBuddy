import SwiftUI
import Charts

struct MonthlyTrendChartView: View {
    @ObservedObject var viewModel: ReportsViewModel
    private let monthSymbols = Calendar.current.shortMonthSymbols

    struct SeriesPoint: Identifiable {
        let id = UUID()
        let month: String
        let value: Double
        let type: String
    }

    // Always create points for every month, even when value is 0
    var combinedSeries: [SeriesPoint] {
        viewModel.monthlyTrend.flatMap { point in
            let monthLabel = monthSymbols[point.month - 1]

            return [
                SeriesPoint(
                    month: monthLabel,
                    value: point.income,      // positive or 0
                    type: "Income"
                ),
                SeriesPoint(
                    month: monthLabel,
                    value: -point.expenses,   // negative or 0
                    type: "Expenses"
                )
            ]
        }
    }

    var body: some View {
        Chart(combinedSeries) { point in
            LineMark(
                x: .value("Month", point.month),
                y: .value("Amount", point.value)
            )
            .interpolationMethod(.linear)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(by: .value("Type", point.type))
        }
        .chartForegroundStyleScale([
            "Income": Color.green,
            "Expenses": Color.red
        ])
        .chartLegend(position: .bottom)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .overlay {
            Chart {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .padding()
    }
}


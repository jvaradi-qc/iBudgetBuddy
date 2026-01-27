//
//  SummaryChartView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/26/26.
//


import SwiftUI
import Charts

struct SummaryChartView: View {
    @ObservedObject var viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: - Totals Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Summary")
                    .font(.headline)

                Text("\(monthName(viewModel.month)) \(viewModel.year)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // MARK: - Chart
            Chart {
                BarMark(
                    x: .value("Type", "Income"),
                    y: .value("Amount", viewModel.totalIncome)
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Type", "Expenses"),
                    y: .value("Amount", abs(viewModel.totalExpenses))
                )
                .foregroundStyle(.red)

                BarMark(
                    x: .value("Type", "Net"),
                    y: .value("Amount", viewModel.net)
                )
                .foregroundStyle(viewModel.net >= 0 ? .green.opacity(0.7) : .red.opacity(0.7))
            }
            .frame(height: 260)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func monthName(_ month: Int) -> String {
        Calendar.current.monthSymbols[month - 1]
    }
}

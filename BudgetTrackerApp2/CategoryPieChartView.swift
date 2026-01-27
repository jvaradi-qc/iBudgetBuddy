//
//  CategoryPieChartView.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/26/26.
//

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    @ObservedObject var viewModel: ReportsViewModel

    var breakdown: [CategoryBreakdownItem] {
        viewModel.computeCategoryBreakdown()
    }

    var body: some View {
        VStack {
            if breakdown.isEmpty {
                Text("No expense data for this month")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                Chart(breakdown) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.category.color)
                    .annotation(position: .overlay) {
                        CategorySliceLabel(item: item)
                    }
                }
                .frame(height: 320)
                .padding()
            }
        }
    }
}

private struct CategorySliceLabel: View {
    let item: CategoryBreakdownItem

    var body: some View {
        VStack(spacing: 2) {
            Text(item.category.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("$\(Int(item.amount)) (\(String(format: "%.0f", item.percent))%)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


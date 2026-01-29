import SwiftUI

struct CategoryPieChartView: View {
    @ObservedObject var viewModel: ReportsViewModel
    @State private var selected: CategoryBreakdownItem?

    var breakdown: [CategoryBreakdownItem] {
        viewModel.computeCategoryBreakdown()
    }

    var body: some View {
        VStack(spacing: 16) {
            if breakdown.isEmpty {
                Text("No expense data for this month")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                TappableDonutChart(breakdown: breakdown) { item in
                    selected = item
                }
                .frame(height: 320)

                NavigationLink(
                    destination: drillDownView,
                    isActive: Binding(
                        get: { selected != nil },
                        set: { if !$0 { selected = nil } }
                    )
                ) {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var drillDownView: some View {
        if let item = selected {
            CategoryDrillDownView(
                category: item.category,
                viewModel: viewModel
            )
        }
    }
}

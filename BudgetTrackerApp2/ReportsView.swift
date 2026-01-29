import SwiftUI

enum TrendMode: String, CaseIterable {
    case daily = "Daily"
    case monthly = "Monthly"
}

struct ReportsView: View {
    let budgetId: UUID

    @StateObject private var viewModel: ReportsViewModel
    @State private var selectedTab: ReportTab = .summary
    @State private var trendMode: TrendMode = .daily

    init(budgetId: UUID) {
        self.budgetId = budgetId
        _viewModel = StateObject(wrappedValue: ReportsViewModel(budgetId: budgetId))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                // MARK: - Month / Year Picker
                HStack(spacing: 12) {
                    MonthPicker(month: $viewModel.month)
                    YearPicker(year: $viewModel.year)
                }
                .padding(.horizontal)

                // MARK: - Main Segmented Control
                Picker("Report Type", selection: $selectedTab) {
                    ForEach(ReportTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Chart Content
                Group {
                    switch selectedTab {

                    case .summary:
                        SummaryChartView(viewModel: viewModel)

                    case .categories:
                        CategoryPieChartView(viewModel: viewModel)

                    case .trends:
                        VStack(spacing: 12) {

                            // Secondary Segmented Control
                            Picker("Trend Mode", selection: $trendMode) {
                                ForEach(TrendMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // Trend Charts
                            switch trendMode {
                            case .daily:
                                DailyTrendChartView(viewModel: viewModel)
                            case .monthly:
                                MonthlyTrendChartView(viewModel: viewModel)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Reports")
        }
    }
}

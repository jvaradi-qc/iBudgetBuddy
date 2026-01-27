import Foundation
import Combine

struct MonthlyTrendPoint: Identifiable {
    let id = UUID()
    let month: Int
    let income: Double      // positive
    let expenses: Double    // positive
}

struct CategoryBreakdownItem: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
    let percent: Double
}

final class ReportsViewModel: ObservableObject {

    @Published var month: Int {
        didSet { reload() }
    }

    @Published var year: Int {
        didSet { reload() }
    }

    // Unified transaction source (regular + recurring)
    @Published private(set) var transactions: [Transaction] = []

    @Published private(set) var categories: [Category] = []
    @Published private(set) var totalIncome: Double = 0
    @Published private(set) var totalExpenses: Double = 0
    @Published private(set) var net: Double = 0
    @Published private(set) var categoryTotals: [CategoryTotal] = []
    @Published private(set) var dailyTrend: [TrendDataPoint] = []
    @Published private(set) var monthlyTrend: [MonthlyTrendPoint] = []

    private let budgetId: UUID

    init(budgetId: UUID) {
        self.budgetId = budgetId
        let now = Date()
        let calendar = Calendar.current
        self.month = calendar.component(.month, from: now)
        self.year = calendar.component(.year, from: now)
        reload()
    }

    // MARK: - Reload all report data
    func reload() {
        categories = Database.shared.fetchCategories()

        // Unified: regular + recurring
        transactions = mergedTransactions(forMonth: month, year: year)

        computeSummary()
        computeCategoryTotals()
        computeDailyTrend()
        computeMonthlyTrend()
    }

    // MARK: - Merge regular + recurring for a given month
    func mergedTransactions(forMonth month: Int, year: Int) -> [Transaction] {
        let calendar = Calendar.current

        // Start and end of month
        let comps = DateComponents(year: year, month: month)
        guard let startDate = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: startDate),
              let endDate = calendar.date(byAdding: .day, value: range.count - 1, to: startDate)
        else { return [] }

        // Regular transactions
        let regular = Database.shared.fetchTransactions(budgetId: budgetId).filter { tx in
            let comps = calendar.dateComponents([.year, .month], from: tx.date)
            return comps.year == year && comps.month == month
        }

        // Recurring rules
        let recurringRules = Database.shared.fetchRecurring(budgetId: budgetId)

        // Expand recurring rules into actual instances for this month
        let expanded: [Transaction] = recurringRules.compactMap { rule in
            let runDate = rule.nextRunDate

            // Only realize if nextRunDate is inside this month
            if runDate >= startDate && runDate <= endDate {
                return Transaction(
                    id: UUID(),
                    budgetId: budgetId,
                    date: runDate,
                    description: rule.description,
                    amount: rule.isIncome ? rule.amount : -rule.amount,
                    isIncome: rule.isIncome,
                    categoryId: rule.categoryId,
                    isRecurringInstance: true,
                    recurringRuleId: rule.id
                )
            }

            return nil
        }

        return (regular + expanded).sorted { $0.date < $1.date }
    }

    // MARK: - Summary (merged)
    private func computeSummary() {
        totalIncome = transactions
            .filter { $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }

        totalExpenses = transactions
            .filter { $0.amount < 0 }
            .reduce(0) { $0 + $1.amount }

        net = totalIncome + totalExpenses
    }

    // MARK: - Category Totals (merged)
    private func computeCategoryTotals() {
        let grouped = Dictionary(grouping: transactions, by: { $0.categoryId })

        categoryTotals = grouped.compactMap { (categoryId, txns) in
            guard let categoryId else { return nil }
            let total = txns.reduce(0) { $0 + $1.amount }
            return CategoryTotal(categoryId: categoryId, total: total)
        }
        .sorted { abs($0.total) > abs($1.total) }
    }

    // MARK: - Daily Trend (merged, cumulative)
    private func computeDailyTrend() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { txn in
            calendar.component(.day, from: txn.date)
        }

        var runningNet: Double = 0
        dailyTrend = (1...daysInMonth(month: month, year: year)).map { day in
            let dayTotal = grouped[day]?.reduce(0) { $0 + $1.amount } ?? 0
            runningNet += dayTotal
            return TrendDataPoint(day: day, net: runningNet)
        }
    }

    // MARK: - Monthly Trend (merged, non‑cumulative)
    func computeMonthlyTrend() {
        monthlyTrend = (1...12).map { m in
            let txns = mergedTransactions(forMonth: m, year: year)

            let income = txns
                .filter { $0.amount > 0 }
                .reduce(0) { $0 + $1.amount }

            let expenses = txns
                .filter { $0.amount < 0 }
                .map { abs($0.amount) }
                .reduce(0, +)

            return MonthlyTrendPoint(
                month: m,
                income: income,
                expenses: expenses
            )
        }
    }

    // MARK: - Category Breakdown (merged)
    func computeCategoryBreakdown() -> [CategoryBreakdownItem] {
        let expenseTx = transactions.filter { tx in
            guard
                let categoryId = tx.categoryId,
                let cat = categories.first(where: { $0.id == categoryId })
            else { return false }

            return cat.type == .expense
        }

        let groupedById = Dictionary(grouping: expenseTx, by: { $0.categoryId! })

        let total = groupedById.values
            .flatMap { $0 }
            .map { abs($0.amount) }
            .reduce(0, +)

        guard total > 0 else { return [] }

        let items: [CategoryBreakdownItem] = groupedById.compactMap { (categoryId, txs) in
            guard let category = categories.first(where: { $0.id == categoryId }) else {
                return nil
            }

            let sum = txs.map { abs($0.amount) }.reduce(0, +)
            let pct = (sum / total) * 100.0

            return CategoryBreakdownItem(
                category: category,
                amount: sum,
                percent: pct
            )
        }

        return items.sorted { $0.amount > $1.amount }
    }

    // MARK: - Helpers
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        let comps = DateComponents(year: year, month: month)
        let date = calendar.date(from: comps)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }
}


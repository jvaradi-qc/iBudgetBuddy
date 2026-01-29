import Foundation
import SwiftUI
import Combine

final class ContentViewModel: ObservableObject {

    // MARK: - Published State
    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget? = nil

    @Published var transactions: [Transaction] = []
    @Published var recurring: [RecurringTransaction] = []

    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // MARK: - Summary
    var totalIncome: Double {
        transactions.filter { $0.amount > 0 }.map { $0.amount }.reduce(0, +)
    }

    var totalExpenses: Double {
        transactions.filter { $0.amount < 0 }.map { abs($0.amount) }.reduce(0, +)
    }

    var netAmount: Double {
        totalIncome - totalExpenses
    }

    // MARK: - Init
    init() {
        loadBudgets()
    }

    // MARK: - Budget Loading
    func loadBudgets() {
        budgets = Database.shared.fetchBudgets()

        // Restore default "My Budget" if DB is empty
        if budgets.isEmpty {
            let defaultBudget = Budget(id: UUID(), name: "My Budget")
            Database.shared.insertBudget(defaultBudget)
            budgets = [defaultBudget]
        }

        if selectedBudget == nil {
            selectedBudget = budgets.first
        }

        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }

    func selectBudget(_ budget: Budget) {
        selectedBudget = budget
        loadData(for: budget.id)
    }

    // MARK: - Load Transactions + Recurring
    func loadData(for budgetId: UUID) {

        // 1. Materialize recurring instances for the current month (based on "now")
        Database.shared.materializeRecurringForCurrentMonth(budgetId: budgetId)

        // 2. Determine selected month/year
        let calendar = Calendar.current
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        guard let startOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)
        else {
            transactions = []
            recurring = []
            return
        }

        // 3. Load REAL transactions (now includes materialized recurring)
        transactions = Database.shared.fetchTransactions(budgetId: budgetId)
            .filter { tx in
                tx.date >= startOfMonth && tx.date <= endOfMonth
            }
            .sorted { $0.date < $1.date }

        // 4. Load recurring rules AFTER materialization
        recurring = Database.shared.fetchRecurring(budgetId: budgetId)
    }

    // MARK: - Add
    func addTransaction(_ t: Transaction) {
        Database.shared.insert(transaction: t)
        loadData(for: t.budgetId)
    }

    func addRecurring(_ r: RecurringTransaction) {
        Database.shared.insertRecurring(r)
        loadData(for: r.budgetId)
    }

    // MARK: - Update
    func updateTransaction(_ t: Transaction) {
        Database.shared.updateTransaction(t)
        loadData(for: t.budgetId)
    }

    func updateRecurring(_ updated: RecurringTransaction) {

        // 1. Update the rule itself
        Database.shared.updateRecurring(updated)

        guard let budgetId = selectedBudget?.id else { return }

        // 2. Determine current selected month range
        let calendar = Calendar.current
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        guard let startOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)
        else { return }

        // 3. Fetch existing materialized instances for this rule
        let existing = Database.shared.fetchTransactions(budgetId: budgetId)
            .filter { tx in
                tx.isRecurringInstance &&
                tx.recurringRuleId == updated.id &&
                tx.date >= startOfMonth &&
                tx.date <= endOfMonth
            }

        // 4. Detect if frequency changed
        let oldRule = recurring.first(where: { $0.id == updated.id })
        let frequencyChanged = oldRule?.frequency != updated.frequency

        if frequencyChanged {
            // Frequency changed → delete old instances and re-materialize
            for tx in existing {
                Database.shared.deleteTransaction(id: tx.id)
            }

            Database.shared.materializeRecurringForCurrentMonth(budgetId: budgetId)
        } else {
            // Frequency unchanged → update existing instances in place
            for var tx in existing {
                tx.description = updated.description
                tx.isIncome = updated.isIncome
                // IMPORTANT: amount already has correct sign from the editor
                tx.amount = updated.amount
                tx.categoryId = updated.categoryId
                Database.shared.updateTransaction(tx)
            }
        }

        // 5. Reload UI
        loadData(for: budgetId)
    }

    // MARK: - Delete
    func deleteTransaction(at offsets: IndexSet) {
        guard let budgetId = selectedBudget?.id else { return }

        for index in offsets {
            let tx = transactions[index]
            Database.shared.deleteTransaction(id: tx.id)
        }

        loadData(for: budgetId)
    }

    func deleteRecurring(at offsets: IndexSet) {
        guard let budgetId = selectedBudget?.id else { return }

        for index in offsets {
            let item = recurring[index]
            Database.shared.deleteRecurring(id: item.id)
        }

        loadData(for: budgetId)
    }

    // MARK: - Budget Deletion
    func deleteCurrentBudget() {
        guard let budget = selectedBudget else { return }

        Database.shared.deleteTransactions(budgetId: budget.id)
        Database.shared.deleteRecurring(budgetId: budget.id)
        Database.shared.deleteBudget(id: budget.id)

        loadBudgets()

        if let first = budgets.first {
            selectedBudget = first
            loadData(for: first.id)
        } else {
            selectedBudget = nil
            transactions = []
            recurring = []
        }
    }
}

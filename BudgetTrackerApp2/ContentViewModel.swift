import Foundation
import Combine

final class ContentViewModel: ObservableObject {

    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget? = nil

    @Published var transactions: [Transaction] = []
    @Published var recurring: [RecurringTransaction] = []

    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private let db: DatabaseProtocol

    init(database: DatabaseProtocol = Database.shared) {
        self.db = database
        loadBudgets()

        if budgets.isEmpty {
            let defaultBudget = Budget(id: UUID(), name: "My Budget")
            db.insertBudget(defaultBudget)
            loadBudgets()
        }

        if let first = budgets.first {
            selectedBudget = first
            loadData(for: first.id)
        }
    }

    // MARK: - Loaders

    func loadBudgets() {
        budgets = db.fetchBudgets()
    }

    func loadData(for budgetId: UUID) {

        // 1. Materialize recurring instances for the current month
        Database.shared.materializeRecurringForCurrentMonth(budgetId: budgetId)

        // 2. Determine current month/year
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

    // MARK: - Budget Selection

    func selectBudget(_ budget: Budget) {
        selectedBudget = budget
        loadData(for: budget.id)
    }

    // MARK: - Budget Deletion

    func deleteCurrentBudget() {
        guard let budget = selectedBudget else { return }

        db.deleteTransactions(budgetId: budget.id)
        db.deleteRecurring(budgetId: budget.id)
        db.deleteBudget(id: budget.id)

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

    // MARK: - Computed Summary

    var totalIncome: Double {
        transactions.filter { $0.amount > 0 }.map(\.amount).reduce(0, +)
    }

    var totalExpenses: Double {
        transactions.filter { $0.amount < 0 }.map { abs($0.amount) }.reduce(0, +)
    }

    var netAmount: Double {
        totalIncome - totalExpenses
    }

    // MARK: - Transactions

    func addTransaction(_ tx: Transaction) {
        db.insert(transaction: tx)
        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }

    func updateTransaction(_ tx: Transaction) {
        db.updateTransaction(tx)
        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }

    func deleteTransaction(at offsets: IndexSet) {
        for index in offsets {
            let tx = transactions[index]
            db.deleteTransaction(id: tx.id)
        }
        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }

    // MARK: - Recurring

    func addRecurring(_ item: RecurringTransaction) {
        db.insertRecurring(item)
        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }

    func updateRecurring(_ item: RecurringTransaction) {
        db.updateRecurring(item)

        guard let budgetId = selectedBudget?.id else { return }

        // Remove existing materialized instances for this rule in the current month
        let calendar = Calendar.current
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        if let startOfMonth = calendar.date(from: comps),
           let range = calendar.range(of: .day, in: .month, for: startOfMonth),
           let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) {

            let existing = db.fetchTransactions(budgetId: budgetId)
                .filter { tx in
                    tx.isRecurringInstance &&
                    tx.recurringRuleId == item.id &&
                    tx.date >= startOfMonth &&
                    tx.date <= endOfMonth
                }

            for tx in existing {
                db.deleteTransaction(id: tx.id)
            }
        }

        // Re-materialize this month (this applies updated isIncome, amount, description, category)
        Database.shared.materializeRecurringForCurrentMonth(budgetId: budgetId)

        // Reload UI
        loadData(for: budgetId)
    }
}

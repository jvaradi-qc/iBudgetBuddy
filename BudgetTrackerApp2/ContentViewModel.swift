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
        transactions = db.fetchTransactions(budgetId: budgetId)
        recurring = db.fetchRecurring(budgetId: budgetId)
    }

    // MARK: - Budget Selection

    func selectBudget(_ budget: Budget) {
        selectedBudget = budget
        loadData(for: budget.id)
    }

    // MARK: - Budget Deletion (NEW)

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
        if let budget = selectedBudget {
            loadData(for: budget.id)
        }
    }
}

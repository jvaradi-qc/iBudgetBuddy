import Foundation
import Combine

final class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var selectedBudgetId: UUID?
    @Published var transactions: [Transaction] = []
    @Published var recurring: [RecurringTransaction] = []

    // MARK: - Editing State
    @Published var editingTransaction: Transaction?
    @Published var isPresentingEditTransaction = false

    @Published var editingRecurring: RecurringTransaction?
    @Published var isPresentingEditRecurring = false

    // MARK: - Budget Deletion State
    @Published var showDeleteBudgetAlert = false
    private var budgetPendingDeletion: Budget?

    // MARK: - Database Dependency
    private let db: DatabaseProtocol

    // MARK: - Initializer (Dependency Injection)
    init(database: DatabaseProtocol = Database.shared) {
        self.db = database


        loadBudgets()


        if budgets.isEmpty {
            let defaultBudget = Budget(id: UUID(), name: "My Budget")
            db.insertBudget(defaultBudget)

            loadBudgets()
        }

        if let first = budgets.first {
            selectedBudgetId = first.id
            loadTransactions()
            loadRecurring()
        }
    }

    // MARK: - Computed Properties for UI

    var selectedBudget: Budget? {
        budgets.first(where: { $0.id == selectedBudgetId })
    }

    var totalIncome: Double {
        let txIncome = transactions
            .filter { $0.amount > 0 }
            .map(\.amount)
            .reduce(0, +)

        let recurringIncome = recurring
            .filter { $0.isIncome }
            .map { $0.amount }
            .reduce(0, +)

        return txIncome + recurringIncome
    }

    var totalExpense: Double {
        let txExpense = transactions
            .filter { $0.amount < 0 }
            .map { abs($0.amount) }
            .reduce(0, +)

        let recurringExpense = recurring
            .filter { !$0.isIncome }
            .map { abs($0.amount) }
            .reduce(0, +)

        return txExpense + recurringExpense
    }

    var net: Double {
        totalIncome - totalExpense
    }

    // MARK: - Budgets

    func loadBudgets() {
        let fetched = db.fetchBudgets()
        budgets = fetched
    }

    func addBudget(_ budget: Budget) {
        db.insertBudget(budget)
        loadBudgets()
    }

    // MARK: - Budget Deletion

    func requestDeleteBudget(_ budget: Budget) {
        budgetPendingDeletion = budget
        showDeleteBudgetAlert = true
    }

    func confirmDeleteBudget() {
        guard let budget = budgetPendingDeletion else { return }

        db.deleteTransactions(budgetId: budget.id)
        db.deleteRecurring(budgetId: budget.id)
        db.deleteBudget(id: budget.id)

        loadBudgets()

        if selectedBudgetId == budget.id {
            selectedBudgetId = budgets.first?.id
            loadTransactions()
            loadRecurring()
        }

        budgetPendingDeletion = nil
        showDeleteBudgetAlert = false
    }

    // MARK: - Budget Selection

    func selectBudget(_ id: UUID) {
        selectedBudgetId = id
        loadTransactions()
        loadRecurring()
    }

    // MARK: - Transactions

    func loadTransactions() {
        guard let id = selectedBudgetId else {
            transactions = []
            return
        }
        transactions = db.fetchTransactions(budgetId: id)
    }

    func addTransaction(date: Date, description: String, amount: Double, isIncome: Bool) {
        guard let id = selectedBudgetId else { return }

        let signedAmount = isIncome ? abs(amount) : -abs(amount)

        let tx = Transaction(
            id: UUID(),
            budgetId: id,
            date: date,
            description: description,
            amount: signedAmount,
            isIncome: isIncome
        )

        db.insert(transaction: tx)
        loadTransactions()
    }

    func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let tx = transactions[index]
            db.deleteTransaction(id: tx.id)
        }
        loadTransactions()
    }

    // MARK: - Editing Transactions

    func startEditing(_ transaction: Transaction) {
        editingTransaction = transaction
        isPresentingEditTransaction = true
    }

    func finishEditing(updatedTransaction: Transaction) {
        db.updateTransaction(updatedTransaction)
        isPresentingEditTransaction = false
        editingTransaction = nil
        loadTransactions()
    }

    // MARK: - Recurring

    func loadRecurring() {
        guard let id = selectedBudgetId else {
            recurring = []
            return
        }
        recurring = db.fetchRecurring(budgetId: id)
    }

    func addRecurring(_ item: RecurringTransaction) {
        db.insertRecurring(item)
        loadRecurring()
    }

    func deleteRecurring(_ item: RecurringTransaction) {
        db.deleteRecurring(id: item.id)
        loadRecurring()
    }

    func startEditingRecurring(_ item: RecurringTransaction) {
        editingRecurring = item
        isPresentingEditRecurring = true
    }

    func finishEditingRecurring(_ updated: RecurringTransaction) {
        db.updateRecurring(updated)
        isPresentingEditRecurring = false
        editingRecurring = nil
        loadRecurring()
    }

    // MARK: - Process Recurring Items

    func processDueRecurringTransactions() {
        let now = Date()
        guard let id = selectedBudgetId else { return }

        let items = db.fetchRecurring(budgetId: id)

        for item in items where item.nextRunDate <= now {
            let signedAmount = item.isIncome ? abs(item.amount) : -abs(item.amount)

            let tx = Transaction(
                id: UUID(),
                budgetId: id,
                date: now,
                description: item.description,
                amount: signedAmount,
                isIncome: item.isIncome
            )

            db.insert(transaction: tx)

            let nextDate = item.frequency.nextDate(after: item.nextRunDate)
            db.updateRecurringDate(id: item.id, nextDate: nextDate)
        }

        loadTransactions()
        loadRecurring()
    }
}


//
//  ContentViewModel.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/22/26.
//

import Foundation
import SwiftUI
import Combine

final class ContentViewModel: ObservableObject {

    // MARK: - Published State
    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget? = nil

    // Real transactions (regular + materialized recurring)
    @Published var transactions: [Transaction] = []

    // Recurring rules (for editing only)
    @Published var recurring: [RecurringTransaction] = []

    // MARK: - Summary
    var totalIncome: Double {
        transactions
            .filter { $0.amount > 0 }
            .map { $0.amount }
            .reduce(0, +)
    }

    var totalExpenses: Double {
        transactions
            .filter { $0.amount < 0 }
            .map { abs($0.amount) }
            .reduce(0, +)
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
        // 1. Materialize recurring instances for the current month
        Database.shared.materializeRecurringForCurrentMonth(budgetId: budgetId)

        // 2. Determine current month/year
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        // 3. Load REAL transactions (now includes materialized recurring)
        transactions = Database.shared.fetchTransactions(budgetId: budgetId)
            .filter { tx in
                let comps = calendar.dateComponents([.year, .month], from: tx.date)
                return comps.year == year && comps.month == month
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

    func updateRecurring(_ r: RecurringTransaction) {
        Database.shared.updateRecurring(r)
        loadData(for: r.budgetId)
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
}


//
//  MockDatabase.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/14/26.
//


import Foundation
@testable import BudgetTrackerApp2

final class MockDatabase: DatabaseProtocol {

    // In-memory storage
    var budgets: [Budget] = []
    var transactions: [UUID: [Transaction]] = [:]
    var recurring: [UUID: [RecurringTransaction]] = [:]

    // MARK: - Budgets

    func fetchBudgets() -> [Budget] {
        budgets
    }

    func insertBudget(_ budget: Budget) {
        budgets.append(budget)
    }

    func deleteBudget(id: UUID) {
        budgets.removeAll { $0.id == id }
        transactions[id] = nil
        recurring[id] = nil
    }

    // MARK: - Transactions

    func fetchTransactions(budgetId: UUID) -> [Transaction] {
        transactions[budgetId] ?? []
    }

    func insert(transaction: Transaction) {
        transactions[transaction.budgetId, default: []].append(transaction)
    }

    func deleteTransaction(id: UUID) {
        for (budgetId, list) in transactions {
            transactions[budgetId] = list.filter { $0.id != id }
        }
    }

    func deleteTransactions(budgetId: UUID) {
        transactions[budgetId] = []
    }

    func updateTransaction(_ updated: Transaction) {
        // Ensure the budget entry exists
        var list = transactions[updated.budgetId, default: []]

        if let idx = list.firstIndex(where: { $0.id == updated.id }) {
            list[idx] = updated
        }

        // Save the updated list back
        transactions[updated.budgetId] = list
    }


    // MARK: - Recurring

    func fetchRecurring(budgetId: UUID) -> [RecurringTransaction] {
        recurring[budgetId] ?? []
    }

    func insertRecurring(_ item: RecurringTransaction) {
        recurring[item.budgetId, default: []].append(item)
    }

    func deleteRecurring(id: UUID) {
        for (budgetId, list) in recurring {
            recurring[budgetId] = list.filter { $0.id != id }
        }
    }

    func deleteRecurring(budgetId: UUID) {
        recurring[budgetId] = []
    }

    func updateRecurring(_ updated: RecurringTransaction) {
        guard var list = recurring[updated.budgetId] else { return }
        if let idx = list.firstIndex(where: { $0.id == updated.id }) {
            list[idx] = updated
        }
        recurring[updated.budgetId] = list
    }

    func updateRecurringDate(id: UUID, nextDate: Date) {
        for (budgetId, list) in recurring {
            if let idx = list.firstIndex(where: { $0.id == id }) {
                var item = list[idx]
                item.nextRunDate = nextDate
                var newList = list
                newList[idx] = item
                recurring[budgetId] = newList
                break
            }
        }
    }
}

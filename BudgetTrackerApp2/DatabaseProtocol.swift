//
//  DatabaseProtocol.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/14/26.
//


import Foundation

protocol DatabaseProtocol {
    // Budgets
    func fetchBudgets() -> [Budget]
    func insertBudget(_ budget: Budget)
    func deleteBudget(id: UUID)

    // Transactions
    func fetchTransactions(budgetId: UUID) -> [Transaction]
    func insert(transaction: Transaction)
    func deleteTransaction(id: UUID)
    func deleteTransactions(budgetId: UUID)
    func updateTransaction(_ updated: Transaction)

    // Recurring
    func fetchRecurring(budgetId: UUID) -> [RecurringTransaction]
    func insertRecurring(_ item: RecurringTransaction)
    func deleteRecurring(id: UUID)
    func deleteRecurring(budgetId: UUID)
    func updateRecurring(_ updated: RecurringTransaction)
    func updateRecurringDate(id: UUID, nextDate: Date)
}

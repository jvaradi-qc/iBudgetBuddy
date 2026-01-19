import Foundation
import SQLite3
import os

final class Database: DatabaseProtocol {
    static let shared = Database()

    private var db: OpaquePointer?
    private var dbPath: String = ""

    private let logger = Logger(subsystem: "com.vitalcode.iBudgetBuddy",
                                category: "database")

    private init() {
        openDatabase()
        createTablesIfNeeded()
    }

    // MARK: - Open DB

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("budget.sqlite")

        dbPath = fileURL.path

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            logger.debug("Opened SQLite database at path: \(self.dbPath, privacy: .public)")
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.fault("Failed to open database. Error: \(message, privacy: .public)")
        }
    }

    // MARK: - Create Tables

    private func createTablesIfNeeded() {
        execute("""
        CREATE TABLE IF NOT EXISTS budgets (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
        );
        """)

        execute("""
        CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            budgetId TEXT NOT NULL,
            date DOUBLE NOT NULL,
            description TEXT NOT NULL,
            amount DOUBLE NOT NULL,
            isIncome INTEGER NOT NULL
        );
        """)

        execute("""
        CREATE TABLE IF NOT EXISTS recurring (
            id TEXT PRIMARY KEY,
            budgetId TEXT NOT NULL,
            description TEXT NOT NULL,
            amount DOUBLE NOT NULL,
            isIncome INTEGER NOT NULL,
            frequency TEXT NOT NULL,
            nextRunDate DOUBLE NOT NULL
        );
        """)
    }

    // MARK: - Execute Helper

    private func execute(_ query: String) {
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("SQLite prepare failed. Query: \(query, privacy: .public) — Error: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    // MARK: - Safe Bind Helper

    private func bindText(_ stmt: OpaquePointer?, index: Int32, _ value: String) {
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        value.withCString { cStr in
            sqlite3_bind_text(stmt, index, cStr, -1, SQLITE_TRANSIENT)
        }
    }

    // MARK: - Budgets

    func insertBudget(_ b: Budget) {
        let query = "INSERT INTO budgets (id, name) VALUES (?, ?);"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, b.id.uuidString)
            bindText(stmt, index: 2, b.name)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Insert budget failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func fetchBudgets() -> [Budget] {
        let query = "SELECT id, name FROM budgets;"
        var stmt: OpaquePointer?
        var results: [Budget] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard let idCString = sqlite3_column_text(stmt, 0),
                      let nameCString = sqlite3_column_text(stmt, 1)
                else { continue }

                let idString = String(cString: idCString)
                let name = String(cString: nameCString)

                guard let id = UUID(uuidString: idString) else { continue }

                results.append(Budget(id: id, name: name))
            }
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Fetch budgets failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
        return results
    }

    func deleteBudget(id: UUID) {
        let query = "DELETE FROM budgets WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Delete budget failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    // MARK: - Transactions

    func insert(transaction: Transaction) {
        let query = """
        INSERT INTO transactions (id, budgetId, date, description, amount, isIncome)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, transaction.id.uuidString)
            bindText(stmt, index: 2, transaction.budgetId.uuidString)
            sqlite3_bind_double(stmt, 3, transaction.date.timeIntervalSince1970)
            bindText(stmt, index: 4, transaction.description)
            sqlite3_bind_double(stmt, 5, transaction.amount)
            sqlite3_bind_int(stmt, 6, transaction.isIncome ? 1 : 0)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Insert transaction failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func fetchTransactions(budgetId: UUID) -> [Transaction] {
        let query = """
        SELECT id, date, description, amount, isIncome
        FROM transactions
        WHERE budgetId = ?
        ORDER BY date DESC;
        """
        var stmt: OpaquePointer?
        var results: [Transaction] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)

            while sqlite3_step(stmt) == SQLITE_ROW {
                guard let idCString = sqlite3_column_text(stmt, 0),
                      let descCString = sqlite3_column_text(stmt, 2)
                else { continue }

                let idString = String(cString: idCString)
                let desc = String(cString: descCString)

                guard let id = UUID(uuidString: idString) else { continue }

                let date = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
                let amount = sqlite3_column_double(stmt, 3)
                let isIncome = sqlite3_column_int(stmt, 4) == 1

                results.append(Transaction(
                    id: id,
                    budgetId: budgetId,
                    date: date,
                    description: desc,
                    amount: amount,
                    isIncome: isIncome
                ))
            }
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Fetch transactions failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
        return results
    }

    func deleteTransaction(id: UUID) {
        let query = "DELETE FROM transactions WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Delete transaction failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func deleteTransactions(budgetId: UUID) {
        let query = "DELETE FROM transactions WHERE budgetId = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Delete transactions failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func updateTransaction(_ t: Transaction) {
        let query = """
        UPDATE transactions
        SET date = ?, description = ?, amount = ?, isIncome = ?
        WHERE id = ?;
        """
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_double(stmt, 1, t.date.timeIntervalSince1970)
            bindText(stmt, index: 2, t.description)
            sqlite3_bind_double(stmt, 3, t.amount)
            sqlite3_bind_int(stmt, 4, t.isIncome ? 1 : 0)
            bindText(stmt, index: 5, t.id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Update transaction failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    // MARK: - Recurring

    func insertRecurring(_ r: RecurringTransaction) {
        let query = """
        INSERT INTO recurring (id, budgetId, description, amount, isIncome, frequency, nextRunDate)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, r.id.uuidString)
            bindText(stmt, index: 2, r.budgetId.uuidString)
            bindText(stmt, index: 3, r.description)
            sqlite3_bind_double(stmt, 4, r.amount)
            sqlite3_bind_int(stmt, 5, r.isIncome ? 1 : 0)
            bindText(stmt, index: 6, r.frequency.rawValue)
            sqlite3_bind_double(stmt, 7, r.nextRunDate.timeIntervalSince1970)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Insert recurring failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func fetchRecurring(budgetId: UUID) -> [RecurringTransaction] {
        let query = """
        SELECT id, description, amount, isIncome, frequency, nextRunDate
        FROM recurring
        WHERE budgetId = ?;
        """
        var stmt: OpaquePointer?
        var results: [RecurringTransaction] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)

            while sqlite3_step(stmt) == SQLITE_ROW {
                guard let idCString = sqlite3_column_text(stmt, 0),
                      let descCString = sqlite3_column_text(stmt, 1),
                      let freqCString = sqlite3_column_text(stmt, 4)
                else { continue }

                let idString = String(cString: idCString)
                let desc = String(cString: descCString)
                let freqString = String(cString: freqCString)

                guard let id = UUID(uuidString: idString),
                      let freq = Frequency(rawValue: freqString)
                else { continue }

                let amount = sqlite3_column_double(stmt, 2)
                let isIncome = sqlite3_column_int(stmt, 3) == 1
                let nextRun = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))

                results.append(RecurringTransaction(
                    id: id,
                    budgetId: budgetId,
                    description: desc,
                    amount: amount,
                    isIncome: isIncome,
                    frequency: freq,
                    nextRunDate: nextRun
                ))
            }
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Fetch recurring failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
        return results
    }

    func deleteRecurring(id: UUID) {
        let query = "DELETE FROM recurring WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Delete recurring failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func deleteRecurring(budgetId: UUID) {
        let query = "DELETE FROM recurring WHERE budgetId = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Delete recurring by budget failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func updateRecurring(_ r: RecurringTransaction) {
        let sql = """
        UPDATE recurring
        SET description = ?, amount = ?, isIncome = ?, frequency = ?, nextRunDate = ?
        WHERE id = ?;
        """
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, r.description)
            sqlite3_bind_double(stmt, 2, r.amount)
            sqlite3_bind_int(stmt, 3, r.isIncome ? 1 : 0)
            bindText(stmt, index: 4, r.frequency.rawValue)
            sqlite3_bind_double(stmt, 5, r.nextRunDate.timeIntervalSince1970)
            bindText(stmt, index: 6, r.id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Update recurring failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }

    func updateRecurringDate(id: UUID, nextDate: Date) {
        let query = "UPDATE recurring SET nextRunDate = ? WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_double(stmt, 1, nextDate.timeIntervalSince1970)
            bindText(stmt, index: 2, id.uuidString)
            sqlite3_step(stmt)
        } else {
            let message = String(cString: sqlite3_errmsg(db))
            logger.error("Update recurring date failed: \(message, privacy: .public)")
        }

        sqlite3_finalize(stmt)
    }
}


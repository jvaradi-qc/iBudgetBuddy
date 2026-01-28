import Foundation
import SQLite3
import os

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class Database: DatabaseProtocol {
    static let shared = Database()
    
    private var db: OpaquePointer?
    private var dbPath: String = ""
    
    private let logger = Logger(subsystem: "com.vitalcode.iBudgetBuddy",
                                category: "database")
    
    private init() {
        openDatabase()
        createTablesIfNeeded()      // Creates missing tables only
        migrateSchemaIfNeeded()     // MUST run before creating tables
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
        
        execute("""
        CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            colorHex TEXT,
            iconName TEXT,
            isActive INTEGER NOT NULL DEFAULT 1
        );
        """)
    }
    
    // MARK: - Schema Migration
    
    // MARK: - Migration

    private func migrateSchemaIfNeeded() {
        execute("BEGIN TRANSACTION;")

        addColumnIfMissing(
            table: "transactions",
            column: "categoryId",
            type: "TEXT"
        )

        addColumnIfMissing(
            table: "recurring",
            column: "categoryId",
            type: "TEXT"
        )

        addColumnIfMissing(
            table: "categories",
            column: "isActive",
            type: "INTEGER NOT NULL DEFAULT 1"
        )

        addColumnIfMissing(
            table: "recurring",
            column: "isActive",
            type: "INTEGER NOT NULL DEFAULT 1"
        )

        addColumnIfMissing(
            table: "transactions",
            column: "isRecurringInstance",
            type: "INTEGER NOT NULL DEFAULT 0"
        )

        addColumnIfMissing(
            table: "transactions",
            column: "recurringRuleId",
            type: "TEXT"
        )

        execute("COMMIT;")
    }


    private func addColumnIfMissing(table: String, column: String, type: String) {
        // 1. Check if table exists
        let tableExistsQuery = """
        SELECT name FROM sqlite_master WHERE type='table' AND name='\(table)';
        """
        var tableStmt: OpaquePointer?
        var tableExists = false

        if sqlite3_prepare_v2(db, tableExistsQuery, -1, &tableStmt, nil) == SQLITE_OK {
            if sqlite3_step(tableStmt) == SQLITE_ROW {
                tableExists = true
            }
        }
        sqlite3_finalize(tableStmt)

        // If table does not exist, DO NOT run migrations on it
        guard tableExists else {
            logger.debug("Skipping migration for missing table \(table)")
            return
        }

        // 2. Check if column exists
        let pragmaQuery = "PRAGMA table_info(\(table));"
        var pragmaStmt: OpaquePointer?
        var columnExists = false

        if sqlite3_prepare_v2(db, pragmaQuery, -1, &pragmaStmt, nil) == SQLITE_OK {
            while sqlite3_step(pragmaStmt) == SQLITE_ROW {
                if let colNameC = sqlite3_column_text(pragmaStmt, 1) {
                    let colName = String(cString: colNameC)
                    if colName == column {
                        columnExists = true
                        break
                    }
                }
            }
        }
        sqlite3_finalize(pragmaStmt)

        // 3. Add column if missing
        if !columnExists {
            execute("ALTER TABLE \(table) ADD COLUMN \(column) \(type);")
            logger.debug("Added missing column \(column) to table \(table)")
        }
    }


    // MARK: - Materialization Engine

    func materializeRecurringForCurrentMonth(budgetId: UUID) {
        let calendar = Calendar.current
        let now = Date()
        
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return }
        
        let rules = fetchRecurring(budgetId: budgetId).filter { $0.isActive }
        
        for var rule in rules {
            let firstCandidate = max(rule.nextRunDate, monthStart)
            
            let dueDates = generateOccurrences(
                for: rule,
                from: firstCandidate,
                through: monthEnd,
                calendar: calendar
            )
            
            guard !dueDates.isEmpty else { continue }
            
            for date in dueDates {
                if !transactionExists(
                    budgetId: budgetId,
                    recurringRuleId: rule.id,
                    on: date
                ) {
                    insertMaterializedRecurringInstance(
                        budgetId: budgetId,
                        rule: rule,
                        date: date
                    )
                }
            }
            
            if let last = dueDates.last {
                var next = last
                repeat {
                    next = nextDate(for: rule.frequency, after: next, calendar: calendar)
                } while next <= monthEnd
                
                rule.nextRunDate = next
                updateRecurring(rule)
            }
        }
    }

    private func generateOccurrences(
        for rule: RecurringTransaction,
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> [Date] {
        var dates: [Date] = []
        var current = max(start, rule.nextRunDate)
        
        while current <= end {
            dates.append(current)
            current = nextDate(for: rule.frequency, after: current, calendar: calendar)
        }
        
        return dates
    }

    private func nextDate(for frequency: Frequency, after date: Date, calendar: Calendar) -> Date {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    private func transactionExists(
        budgetId: UUID,
        recurringRuleId: UUID,
        on date: Date
    ) -> Bool {
        let sql = """
        SELECT COUNT(*)
        FROM transactions
        WHERE budgetId = ?
          AND isRecurringInstance = 1
          AND recurringRuleId = ?
          AND date = ?;
        """
        
        var stmt: OpaquePointer?
        var exists = false
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            bindText(stmt, index: 2, recurringRuleId.uuidString)
            sqlite3_bind_double(stmt, 3, date.timeIntervalSince1970)
            
            if sqlite3_step(stmt) == SQLITE_ROW {
                exists = sqlite3_column_int(stmt, 0) > 0
            }
        }
        
        sqlite3_finalize(stmt)
        return exists
    }

    private func insertMaterializedRecurringInstance(
        budgetId: UUID,
        rule: RecurringTransaction,
        date: Date
    ) {
        let sql = """
        INSERT INTO transactions (
            id,
            budgetId,
            date,
            description,
            amount,
            isIncome,
            categoryId,
            isRecurringInstance,
            recurringRuleId
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let id = UUID()
            
            bindText(stmt, index: 1, id.uuidString)
            bindText(stmt, index: 2, budgetId.uuidString)
            sqlite3_bind_double(stmt, 3, date.timeIntervalSince1970)
            bindText(stmt, index: 4, rule.description)
            sqlite3_bind_double(stmt, 5, rule.amount)
            sqlite3_bind_int(stmt, 6, rule.isIncome ? 1 : 0)
            
            if let catId = rule.categoryId {
                bindText(stmt, index: 7, catId.uuidString)
            } else {
                bindText(stmt, index: 7, "")
            }
            
            sqlite3_bind_int(stmt, 8, 1)
            bindText(stmt, index: 9, rule.id.uuidString)
            
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
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
    
    // MARK: - Categories
    
    func insertCategory(_ c: Category) {
        let query = """
        INSERT INTO categories (id, name, type, colorHex, iconName, isActive)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, c.id.uuidString)
            bindText(stmt, index: 2, c.name)
            bindText(stmt, index: 3, c.type.rawValue)
            bindText(stmt, index: 4, c.colorHex ?? "")
            bindText(stmt, index: 5, c.iconName ?? "")
            sqlite3_bind_int(stmt, 6, c.isActive ? 1 : 0)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    /// Returns ALL categories (active + inactive) for management UI
    func fetchCategories() -> [Category] {
        let query = """
        SELECT id, name, type, colorHex, iconName, isActive
        FROM categories;
        """
        
        var stmt: OpaquePointer?
        var results: [Category] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard
                    let idCString = sqlite3_column_text(stmt, 0),
                    let nameCString = sqlite3_column_text(stmt, 1),
                    let typeCString = sqlite3_column_text(stmt, 2)
                else { continue }
                
                let id = UUID(uuidString: String(cString: idCString))!
                let name = String(cString: nameCString)
                let type = CategoryType(rawValue: String(cString: typeCString)) ?? .expense
                
                let colorHex = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) }
                let iconName = sqlite3_column_text(stmt, 4).flatMap { String(cString: $0) }
                let isActive = sqlite3_column_int(stmt, 5) == 1
                
                results.append(Category(
                    id: id,
                    name: name,
                    type: type,
                    colorHex: colorHex?.isEmpty == true ? nil : colorHex,
                    iconName: iconName?.isEmpty == true ? nil : iconName,
                    isActive: isActive
                ))
            }
        }
        
        sqlite3_finalize(stmt)
        return results
    }
    
    // MARK: - Fetch single category by ID
    func fetchCategory(id: UUID?) -> Category? {
        guard let id else { return nil }

        let query = """
            SELECT id, name, type, colorHex, iconName, isActive
            FROM categories
            WHERE id = ?;
        """

        var statement: OpaquePointer? = nil

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("❌ Error preparing fetchCategory")
            return nil
        }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

        var category: Category? = nil

        if sqlite3_step(statement) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(statement, 0))
            let name = String(cString: sqlite3_column_text(statement, 1))
            let typeString = String(cString: sqlite3_column_text(statement, 2))
            let colorHex = String(cString: sqlite3_column_text(statement, 3))
            let iconName = String(cString: sqlite3_column_text(statement, 4))
            let isActive = sqlite3_column_int(statement, 5) == 1

            if let uuid = UUID(uuidString: idString),
               let type = CategoryType(rawValue: typeString) {
                category = Category(
                    id: uuid,
                    name: name,
                    type: type,
                    colorHex: colorHex,
                    iconName: iconName,
                    isActive: isActive
                )
            }
        }

        sqlite3_finalize(statement)
        return category
    }

    
    /// Returns ONLY active categories (for pickers, transactions, etc.)
    func fetchActiveCategories() -> [Category] {
        let query = """
        SELECT id, name, type, colorHex, iconName, isActive
        FROM categories
        WHERE isActive = 1;
        """
        
        var stmt: OpaquePointer?
        var results: [Category] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard
                    let idCString = sqlite3_column_text(stmt, 0),
                    let nameCString = sqlite3_column_text(stmt, 1),
                    let typeCString = sqlite3_column_text(stmt, 2)
                else { continue }
                
                let id = UUID(uuidString: String(cString: idCString))!
                let name = String(cString: nameCString)
                let type = CategoryType(rawValue: String(cString: typeCString)) ?? .expense
                
                let colorHex = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) }
                let iconName = sqlite3_column_text(stmt, 4).flatMap { String(cString: $0) }
                let isActive = sqlite3_column_int(stmt, 5) == 1
                
                results.append(Category(
                    id: id,
                    name: name,
                    type: type,
                    colorHex: colorHex?.isEmpty == true ? nil : colorHex,
                    iconName: iconName?.isEmpty == true ? nil : iconName,
                    isActive: isActive
                ))
            }
        }
        
        sqlite3_finalize(stmt)
        return results
    }
    
    func updateCategory(_ c: Category) {
        let query = """
        UPDATE categories
        SET name = ?, type = ?, colorHex = ?, iconName = ?, isActive = ?
        WHERE id = ?;
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, c.name)
            bindText(stmt, index: 2, c.type.rawValue)
            bindText(stmt, index: 3, c.colorHex ?? "")
            bindText(stmt, index: 4, c.iconName ?? "")
            sqlite3_bind_int(stmt, 5, c.isActive ? 1 : 0)
            bindText(stmt, index: 6, c.id.uuidString)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    func deactivateCategory(id: UUID) {
        execute("UPDATE categories SET isActive = 0 WHERE id = '\(id.uuidString)';")
    }
    
    func reactivateCategory(id: UUID) {
        execute("UPDATE categories SET isActive = 1 WHERE id = '\(id.uuidString)';")
    }
    
    // MARK: - Budgets
    
    func insertBudget(_ b: Budget) {
        let query = "INSERT INTO budgets (id, name) VALUES (?, ?);"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, b.id.uuidString)
            bindText(stmt, index: 2, b.name)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    func fetchBudgets() -> [Budget] {
        let query = "SELECT id, name FROM budgets;"
        var stmt: OpaquePointer?
        var results: [Budget] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard
                    let idCString = sqlite3_column_text(stmt, 0),
                    let nameCString = sqlite3_column_text(stmt, 1)
                else { continue }
                
                let id = UUID(uuidString: String(cString: idCString))!
                let name = String(cString: nameCString)
                
                results.append(Budget(id: id, name: name))
            }
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
        }
        
        sqlite3_finalize(stmt)
    }
    
    // MARK: - Transactions
    
    func insert(transaction: Transaction) {
        let query = """
        INSERT INTO transactions (id, budgetId, date, description, amount, isIncome, categoryId)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, transaction.id.uuidString)
            bindText(stmt, index: 2, transaction.budgetId.uuidString)
            sqlite3_bind_double(stmt, 3, transaction.date.timeIntervalSince1970)
            bindText(stmt, index: 4, transaction.description)
            sqlite3_bind_double(stmt, 5, transaction.amount)
            sqlite3_bind_int(stmt, 6, transaction.isIncome ? 1 : 0)
            
            if let catId = transaction.categoryId {
                bindText(stmt, index: 7, catId.uuidString)
            } else {
                bindText(stmt, index: 7, "")
            }
            
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    func fetchTransactions(budgetId: UUID) -> [Transaction] {
        let query = """
        SELECT id, date, description, amount, isIncome, categoryId,
               isRecurringInstance, recurringRuleId
        FROM transactions
        WHERE budgetId = ?
        ORDER BY date DESC;
        """
        
        var stmt: OpaquePointer?
        var results: [Transaction] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard
                    let idCString = sqlite3_column_text(stmt, 0),
                    let descCString = sqlite3_column_text(stmt, 2)
                else { continue }
                
                let id = UUID(uuidString: String(cString: idCString))!
                let desc = String(cString: descCString)
                
                let date = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
                let amount = sqlite3_column_double(stmt, 3)
                let isIncome = sqlite3_column_int(stmt, 4) == 1
                
                let catIdString = sqlite3_column_text(stmt, 5).flatMap { String(cString: $0) }
                let catId = catIdString?.isEmpty == false ? UUID(uuidString: catIdString!) : nil
                
                let isRecurringInstance = sqlite3_column_int(stmt, 6) == 1
                
                let ruleIdString = sqlite3_column_text(stmt, 7).flatMap { String(cString: $0) }
                let recurringRuleId = ruleIdString?.isEmpty == false ? UUID(uuidString: ruleIdString!) : nil
                
                results.append(Transaction(
                    id: id,
                    budgetId: budgetId,
                    date: date,
                    description: desc,
                    amount: amount,
                    isIncome: isIncome,
                    categoryId: catId,
                    isRecurringInstance: isRecurringInstance,
                    recurringRuleId: recurringRuleId
                ))
            }
        }
        
        sqlite3_finalize(stmt)
        return results
    }

    
    func updateTransaction(_ t: Transaction) {
        let query = """
        UPDATE transactions
        SET date = ?, description = ?, amount = ?, isIncome = ?, categoryId = ?
        WHERE id = ?;
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_double(stmt, 1, t.date.timeIntervalSince1970)
            bindText(stmt, index: 2, t.description)
            sqlite3_bind_double(stmt, 3, t.amount)
            sqlite3_bind_int(stmt, 4, t.isIncome ? 1 : 0)
            
            if let catId = t.categoryId {
                bindText(stmt, index: 5, catId.uuidString)
            } else {
                bindText(stmt, index: 5, "")
            }
            
            bindText(stmt, index: 6, t.id.uuidString)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    func deleteTransaction(id: UUID) {
        let query = "DELETE FROM transactions WHERE id = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, id.uuidString)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    func deleteTransactions(budgetId: UUID) {
        let query = "DELETE FROM transactions WHERE budgetId = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    // MARK: - Recurring

    func insertRecurring(_ r: RecurringTransaction) {
        let query = """
        INSERT INTO recurring (
            id, budgetId, description, amount, isIncome, frequency, nextRunDate, categoryId, isActive
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
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

            if let catId = r.categoryId {
                bindText(stmt, index: 8, catId.uuidString)
            } else {
                bindText(stmt, index: 8, "")
            }

            sqlite3_bind_int(stmt, 9, r.isActive ? 1 : 0)   // NEW

            sqlite3_step(stmt)
        }

        sqlite3_finalize(stmt)
    }


    func fetchRecurring(budgetId: UUID) -> [RecurringTransaction] {
        let query = """
        SELECT id, description, amount, isIncome, frequency, nextRunDate, categoryId, isActive
        FROM recurring
        WHERE budgetId = ?;
        """

        var stmt: OpaquePointer?
        var results: [RecurringTransaction] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)

            while sqlite3_step(stmt) == SQLITE_ROW {
                guard
                    let idCString = sqlite3_column_text(stmt, 0),
                    let descCString = sqlite3_column_text(stmt, 1),
                    let freqCString = sqlite3_column_text(stmt, 4)
                else { continue }

                let id = UUID(uuidString: String(cString: idCString))!
                let desc = String(cString: descCString)
                let freq = Frequency(rawValue: String(cString: freqCString))!

                let amount = sqlite3_column_double(stmt, 2)
                let isIncome = sqlite3_column_int(stmt, 3) == 1
                let nextRun = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))

                let catIdString = sqlite3_column_text(stmt, 6).flatMap { String(cString: $0) }
                let catId = catIdString?.isEmpty == false ? UUID(uuidString: catIdString!) : nil

                let isActive = sqlite3_column_int(stmt, 7) == 1   // NEW

                results.append(RecurringTransaction(
                    id: id,
                    budgetId: budgetId,
                    description: desc,
                    amount: amount,
                    isIncome: isIncome,
                    frequency: freq,
                    nextRunDate: nextRun,
                    categoryId: catId,
                    isActive: isActive   // NEW
                ))
            }
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
        }

        sqlite3_finalize(stmt)
    }

    func deleteRecurring(budgetId: UUID) {
        let query = "DELETE FROM recurring WHERE budgetId = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, budgetId.uuidString)
            sqlite3_step(stmt)
        }

        sqlite3_finalize(stmt)
    }

    func updateRecurring(_ r: RecurringTransaction) {
        let sql = """
        UPDATE recurring
        SET description = ?, amount = ?, isIncome = ?, frequency = ?, nextRunDate = ?, categoryId = ?, isActive = ?
        WHERE id = ?;
        """

        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, index: 1, r.description)
            sqlite3_bind_double(stmt, 2, r.amount)
            sqlite3_bind_int(stmt, 3, r.isIncome ? 1 : 0)
            bindText(stmt, index: 4, r.frequency.rawValue)
            sqlite3_bind_double(stmt, 5, r.nextRunDate.timeIntervalSince1970)

            if let catId = r.categoryId {
                bindText(stmt, index: 6, catId.uuidString)
            } else {
                bindText(stmt, index: 6, "")
            }

            sqlite3_bind_int(stmt, 7, r.isActive ? 1 : 0)   // NEW

            bindText(stmt, index: 8, r.id.uuidString)
            sqlite3_step(stmt)
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


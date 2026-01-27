import XCTest
@testable import BudgetTrackerApp2

final class BudgetTrackerApp2Tests: XCTestCase {

    var vm: BudgetViewModel!
    var mockDB: MockDatabase!

    override func setUp() {
        super.setUp()
        mockDB = MockDatabase()
        vm = BudgetViewModel(database: mockDB)
    }

    override func tearDown() {
        vm = nil
        mockDB = nil
        super.tearDown()
    }

    func testAddBudget() {
        let initialCount = vm.budgets.count
        let budget = Budget(id: UUID(), name: "Groceries")
        vm.addBudget(budget)

        XCTAssertEqual(vm.budgets.count, initialCount + 1)
        XCTAssertEqual(vm.budgets.last?.name, "Groceries")
    }

    func testSelectBudgetLoadsTransactions() {
        let budget = Budget(id: UUID(), name: "Bills")
        vm.addBudget(budget)

        let tx = Transaction(
            id: UUID(),
            budgetId: budget.id,
            date: Date(),
            description: "Rent",
            amount: -1200,
            isIncome: false,
            categoryId: nil
        )
        mockDB.transactions[budget.id] = [tx]

        vm.selectBudget(budget.id)

        XCTAssertEqual(vm.transactions.count, 1)
        XCTAssertEqual(vm.transactions.first?.description, "Rent")
    }

    func testDeleteBudgetRemovesTransactions() {
        let budget = Budget(id: UUID(), name: "Temp")
        vm.addBudget(budget)

        let tx = Transaction(
            id: UUID(),
            budgetId: budget.id,
            date: Date(),
            description: "Coffee",
            amount: -5,
            isIncome: false,
            categoryId: nil
        )
        mockDB.transactions[budget.id] = [tx]

        vm.selectBudget(budget.id)
        vm.requestDeleteBudget(budget)
        vm.confirmDeleteBudget()

        XCTAssertFalse(vm.budgets.contains(where: { $0.id == budget.id }))
        XCTAssertTrue(vm.transactions.isEmpty)
    }

    func testAddTransaction() {
        let budget = Budget(id: UUID(), name: "Main")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        vm.addTransaction(
            date: Date(),
            description: "Tea",
            amount: -3,
            isIncome: false,
            categoryId: nil
        )

        XCTAssertEqual(vm.transactions.count, 1)
        XCTAssertEqual(vm.transactions.first?.description, "Tea")
    }

    func testDeleteTransaction() {
        let budget = Budget(id: UUID(), name: "Main")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        let tx = Transaction(
            id: UUID(),
            budgetId: budget.id,
            date: Date(),
            description: "Tea",
            amount: -3,
            isIncome: false,
            categoryId: nil
        )
        vm.transactions = [tx]

        vm.deleteTransactions(at: IndexSet(integer: 0))

        XCTAssertTrue(vm.transactions.isEmpty)
    }

    func testEditTransaction() {
        let budget = Budget(id: UUID(), name: "Main")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        let tx = Transaction(
            id: UUID(),
            budgetId: budget.id,
            date: Date(),
            description: "Tea",
            amount: -3,
            isIncome: false,
            categoryId: nil
        )

        // ✅ Seed the mock database instead of vm.transactions
        mockDB.transactions[budget.id] = [tx]
        vm.loadTransactions()

        let updated = Transaction(
            id: tx.id,
            budgetId: budget.id,
            date: Date(),
            description: "Latte",
            amount: -5,
            isIncome: false,
            categoryId: nil
        )

        vm.finishEditing(updatedTransaction: updated)

        XCTAssertEqual(vm.transactions.first?.description, "Latte")
    }



    func testAddRecurring() {
        let budget = Budget(id: UUID(), name: "Bills")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        let recurring = RecurringTransaction(
            id: UUID(),
            budgetId: budget.id,
            description: "Rent",
            amount: 1200,
            isIncome: true,
            frequency: .monthly,
            nextRunDate: Date(),
            categoryId: nil
        )

        vm.addRecurring(recurring)

        XCTAssertEqual(vm.recurring.count, 1)
        XCTAssertEqual(vm.recurring.first?.description, "Rent")
    }

    func testProcessDueRecurringCalculations() {
        let budget = Budget(id: UUID(), name: "Bills")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let recurring = RecurringTransaction(
            id: UUID(),
            budgetId: budget.id,
            description: "Rent",
            amount: 1200,
            isIncome: true,
            frequency: .monthly,
            nextRunDate: yesterday,
            categoryId: nil

        )

        mockDB.insertRecurring(recurring)
        vm.loadRecurring()
        vm.processDueRecurringTransactions()

        XCTAssertEqual(vm.transactions.count, 1)
        XCTAssertEqual(vm.transactions.first?.description, "Rent")
    }

    func testTotalsCalculation() {
        let budget = Budget(id: UUID(), name: "Main")
        vm.addBudget(budget)
        vm.selectBudget(budget.id)

        vm.transactions = [
            Transaction(
                id: UUID(),
                budgetId: budget.id,
                date: Date(),
                description: "Paycheck",
                amount: 1000,
                isIncome: true,
                categoryId: nil
            ),
            Transaction(
                id: UUID(),
                budgetId: budget.id,
                date: Date(),
                description: "Groceries",
                amount: -200,
                isIncome: false,
                categoryId: nil
            )
        ]

        XCTAssertEqual(vm.totalIncome, 1000)
        XCTAssertEqual(vm.totalExpense, 200)
        XCTAssertEqual(vm.net, 800)
    }
}


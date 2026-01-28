import XCTest
@testable import BudgetTrackerApp2

final class TransactionCategoryAssignmentTests: XCTestCase {

    var vm: BudgetViewModel!
    var mockDB: MockDatabase!
    var budgetId: UUID!

    override func setUp() {
        super.setUp()
        mockDB = MockDatabase()
        vm = BudgetViewModel(database: mockDB)

        budgetId = UUID()
        vm.addBudget(Budget(id: budgetId, name: "Test Budget"))
        vm.selectBudget(budgetId)
    }

    override func tearDown() {
        vm = nil
        mockDB = nil
        super.tearDown()
    }

    // 1. Assign category on creation
    func testAssignCategoryOnAddTransaction() {
        let categoryId = UUID()

        vm.addTransaction(
            date: Date(),
            description: "Groceries",
            amount: 50,
            isIncome: false,
            categoryId: categoryId
        )

        let tx = vm.transactions.first
        XCTAssertNotNil(tx)
        XCTAssertEqual(tx?.categoryId, categoryId)
    }

    // 2. Edit category on existing transaction
    func testEditTransactionCategory() {
        let originalCategory = UUID()
        let newCategory = UUID()

        let tx = Transaction(
            id: UUID(),
            budgetId: budgetId,
            date: Date(),
            description: "Coffee",
            amount: -5,
            isIncome: false,
            categoryId: originalCategory,
            isRecurringInstance: false,
            recurringRuleId: nil
        )

        mockDB.transactions[budgetId] = [tx]
        vm.loadTransactions()

        let updated = Transaction(
            id: tx.id,
            budgetId: budgetId,
            date: tx.date,
            description: tx.description,
            amount: tx.amount,
            isIncome: tx.isIncome,
            categoryId: newCategory,
            isRecurringInstance: tx.isRecurringInstance,
            recurringRuleId: tx.recurringRuleId
        )

        vm.finishEditing(updatedTransaction: updated)

        XCTAssertEqual(vm.transactions.first?.categoryId, newCategory)
    }

    // 3. Clear category
    func testClearTransactionCategory() {
        let categoryId = UUID()

        let tx = Transaction(
            id: UUID(),
            budgetId: budgetId,
            date: Date(),
            description: "Lunch",
            amount: -12,
            isIncome: false,
            categoryId: categoryId,
            isRecurringInstance: false,
            recurringRuleId: nil
        )

        mockDB.transactions[budgetId] = [tx]
        vm.loadTransactions()

        let updated = Transaction(
            id: tx.id,
            budgetId: budgetId,
            date: tx.date,
            description: tx.description,
            amount: tx.amount,
            isIncome: tx.isIncome,
            categoryId: nil,
            isRecurringInstance: tx.isRecurringInstance,
            recurringRuleId: tx.recurringRuleId
        )

        vm.finishEditing(updatedTransaction: updated)

        XCTAssertNil(vm.transactions.first?.categoryId)
    }

    // 4. Category persists through DB fetch
    func testCategoryPersistsThroughDatabase() {
        let categoryId = UUID()

        let tx = Transaction(
            id: UUID(),
            budgetId: budgetId,
            date: Date(),
            description: "Paycheck",
            amount: 2000,
            isIncome: true,
            categoryId: categoryId,
            isRecurringInstance: false,
            recurringRuleId: nil
        )

        mockDB.insert(transaction: tx)

        vm.loadTransactions()

        XCTAssertEqual(vm.transactions.first?.categoryId, categoryId)
    }

    // 5. Category type mismatch is accepted by ViewModel
    func testCategoryTypeMismatchIsAccepted() {
        let expenseCategory = Category(
            id: UUID(),
            name: "Food",
            type: .expense,
            colorHex: "#FF0000",
            iconName: nil,
            isActive: true
        )

        vm.addTransaction(
            date: Date(),
            description: "Paycheck",
            amount: 1000,
            isIncome: true,
            categoryId: expenseCategory.id
        )

        let tx = vm.transactions.first
        XCTAssertNotNil(tx)
        XCTAssertEqual(tx?.categoryId, expenseCategory.id)
    }
}

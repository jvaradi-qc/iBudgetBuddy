import XCTest
@testable import BudgetTrackerApp2

final class CategorySelectionViewModelTests: XCTestCase {

    func testFiltersIncomeCategories() {
        let categories = [
            Category(id: UUID(), name: "Paycheck", type: .income, colorHex: "#00FF00", iconName: nil, isActive: true),
            Category(id: UUID(), name: "Groceries", type: .expense, colorHex: "#FF0000", iconName: nil, isActive: true)
        ]

        let vm = CategorySelectionViewModel(categories: categories, isIncome: true)
        let result = vm.filteredCategories

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Paycheck")
    }

    func testFiltersExpenseCategories() {
        let categories = [
            Category(id: UUID(), name: "Paycheck", type: .income, colorHex: "#00FF00", iconName: nil, isActive: true),
            Category(id: UUID(), name: "Groceries", type: .expense, colorHex: "#FF0000", iconName: nil, isActive: true)
        ]

        let vm = CategorySelectionViewModel(categories: categories, isIncome: false)
        let result = vm.filteredCategories

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Groceries")
    }

    func testReturnsEmptyWhenNoMatchingCategories() {
        let categories = [
            Category(id: UUID(), name: "Paycheck", type: .income, colorHex: "#00FF00", iconName: nil, isActive: true)
        ]

        let vm = CategorySelectionViewModel(categories: categories, isIncome: false)
        let result = vm.filteredCategories

        XCTAssertTrue(result.isEmpty)
    }

    func testHandlesEmptyCategoryList() {
        let vm = CategorySelectionViewModel(categories: [], isIncome: true)
        XCTAssertTrue(vm.filteredCategories.isEmpty)
    }
}

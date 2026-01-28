import XCTest
@testable import BudgetTrackerApp2

final class CategoryTests: XCTestCase {

    func testCategoryInitialization() {
        let id = UUID()
        let category = Category(
            id: id,
            name: "Food",
            type: .expense,
            colorHex: "#FF0000",
            iconName: "fork.knife",
            isActive: true
        )

        XCTAssertEqual(category.id, id)
        XCTAssertEqual(category.name, "Food")
        XCTAssertEqual(category.type, .expense)
        XCTAssertEqual(category.colorHex, "#FF0000")
        XCTAssertEqual(category.iconName, "fork.knife")
        XCTAssertTrue(category.isActive)
    }

    func testCategoryColorConversion() {
        let category = Category(
            id: UUID(),
            name: "Utilities",
            type: .expense,
            colorHex: "#00FF00",
            iconName: nil,
            isActive: true
        )

        _ = category.color
    }

    func testCategoryFilteringByType() {
        let categories = [
            Category(id: UUID(), name: "Paycheck", type: .income, colorHex: "#00FF00", iconName: nil, isActive: true),
            Category(id: UUID(), name: "Groceries", type: .expense, colorHex: "#FF0000", iconName: nil, isActive: true)
        ]

        let income = categories.filter { $0.type == .income }
        let expense = categories.filter { $0.type == .expense }

        XCTAssertEqual(income.count, 1)
        XCTAssertEqual(expense.count, 1)
    }

    func testInactiveCategoriesAreIgnored() {
        let categories = [
            Category(id: UUID(), name: "Food", type: .expense, colorHex: "#FF0000", iconName: nil, isActive: true),
            Category(id: UUID(), name: "Old Category", type: .expense, colorHex: "#CCCCCC", iconName: nil, isActive: false)
        ]

        let active = categories.filter { $0.isActive }
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.name, "Food")
    }
}

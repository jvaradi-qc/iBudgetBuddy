//
//  CategoryTests.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/22/26.
//


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
            isActive: true
        )

        XCTAssertEqual(category.id, id)
        XCTAssertEqual(category.name, "Food")
        XCTAssertEqual(category.type, .expense)
        XCTAssertEqual(category.colorHex, "#FF0000")
        XCTAssertTrue(category.isActive)
    }

    func testCategoryColorConversion() {
        let category = Category(
            id: UUID(),
            name: "Utilities",
            type: .expense,
            colorHex: "#00FF00",
            isActive: true
        )

        let color = category.color
        XCTAssertNotNil(color)
    }

    func testCategoryFilteringByType() {
        let categories = [
            Category(id: UUID(), name: "Paycheck", type: .income, colorHex: "#00FF00", isActive: true),
            Category(id: UUID(), name: "Groceries", type: .expense, colorHex: "#FF0000", isActive: true)
        ]

        let income = categories.filter { $0.type == .income }
        let expense = categories.filter { $0.type == .expense }

        XCTAssertEqual(income.count, 1)
        XCTAssertEqual(expense.count, 1)
    }

    func testInactiveCategoriesAreIgnored() {
        let categories = [
            Category(id: UUID(), name: "Food", type: .expense, colorHex: "#FF0000", isActive: true),
            Category(id: UUID(), name: "Old Category", type: .expense, colorHex: "#CCCCCC", isActive: false)
        ]

        let active = categories.filter { $0.isActive }
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.name, "Food")
    }
}

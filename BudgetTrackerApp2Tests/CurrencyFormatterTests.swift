//
//  CurrencyFormatterTests.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/27/26.
//


// CurrencyFormatterTests.swift
import XCTest
@testable import BudgetTrackerApp2

final class CurrencyFormatterTests: XCTestCase {

    func testFormatsPositiveValue() {
        let result = CurrencyFormatter.string(from: 123.45)
        XCTAssertTrue(result.contains("123"))
    }

    func testFormatsNegativeValue() {
        let result = CurrencyFormatter.string(from: -67.89)
        XCTAssertTrue(result.contains("67"))
    }

    func testFormatsZero() {
        let result = CurrencyFormatter.string(from: 0)
        XCTAssertFalse(result.isEmpty)
    }
}

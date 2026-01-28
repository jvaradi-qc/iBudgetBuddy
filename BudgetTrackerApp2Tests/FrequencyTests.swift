//
//  FrequencyTests.swift
//  BudgetTrackerApp2
//
//  Created by JOHN VARADI on 1/27/26.
//


// FrequencyTests.swift
import XCTest
@testable import BudgetTrackerApp2

final class FrequencyTests: XCTestCase {

    func testNextDateDaily() {
        let now = Date()
        let next = Frequency.daily.nextDate(after: now)
        let diff = Calendar.current.dateComponents([.day], from: now, to: next).day
        XCTAssertEqual(diff, 1)
    }

    func testNextDateWeekly() {
        let now = Date()
        let next = Frequency.weekly.nextDate(after: now)
        let diff = Calendar.current.dateComponents([.day], from: now, to: next).day
        XCTAssertEqual(diff, 7)
    }

    func testNextDateBiweekly() {
        let now = Date()
        let next = Frequency.biweekly.nextDate(after: now)
        let diff = Calendar.current.dateComponents([.day], from: now, to: next).day
        XCTAssertEqual(diff, 14)
    }

    func testNextDateMonthly() {
        let now = Date()
        let next = Frequency.monthly.nextDate(after: now)
        let diff = Calendar.current.dateComponents([.month], from: now, to: next).month
        XCTAssertEqual(diff, 1)
    }

    func testNextDateYearly() {
        let now = Date()
        let next = Frequency.yearly.nextDate(after: now)
        let diff = Calendar.current.dateComponents([.year], from: now, to: next).year
        XCTAssertEqual(diff, 1)
    }

    func testDisplayNames() {
        XCTAssertEqual(Frequency.daily.displayName, "Daily")
        XCTAssertEqual(Frequency.weekly.displayName, "Weekly")
        XCTAssertEqual(Frequency.biweekly.displayName, "Bi-weekly")
        XCTAssertEqual(Frequency.monthly.displayName, "Monthly")
        XCTAssertEqual(Frequency.yearly.displayName, "Yearly")
    }
}

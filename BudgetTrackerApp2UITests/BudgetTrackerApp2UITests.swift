import XCTest

final class BudgetTrackerApp2UITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launch()
    }

    // MARK: - 1. App Launch Smoke Test
    func testAppLaunches() {
        XCTAssertTrue(app.waitForExistence(timeout: 3), "App did not launch")
    }

    // MARK: - 2. Navigation: Add Menu Opens
    func testAddMenuOpens() {
        let addMenuButton = app.images["addMenuButton"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))

        addMenuButton.tap()

        let addBudgetItem = app.buttons["addBudgetMenuItem"]
        XCTAssertTrue(addBudgetItem.waitForExistence(timeout: 3))
    }

    // MARK: - 3. Navigation: Add Budget Sheet Appears
    func testAddBudgetSheetAppears() {
        let addMenuButton = app.images["addMenuButton"]
        addMenuButton.tap()

        let addBudgetItem = app.buttons["addBudgetMenuItem"]
        addBudgetItem.tap()

        // Look for something inside AddBudgetView
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
    }

    // MARK: - 4. Navigation: Settings Opens
    func testSettingsOpens() {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))

        settingsButton.tap()

        // Look for something inside SettingsView
        let doneButton = app.buttons["Done"].firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
    }
}

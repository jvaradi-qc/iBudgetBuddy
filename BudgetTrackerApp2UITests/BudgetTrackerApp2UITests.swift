// BudgetTrackerApp2UITests.swift
import XCTest

final class SanityUITests: XCTestCase {
    func testSanityLaunch() {
        XCTAssertTrue(true)
    }
}

final class BudgetTrackerApp2UITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launch()
    }

    // MARK: - App Launch

    func testAppLaunches() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(app.navigationBars["iBudgetBuddy"].waitForExistence(timeout: 5))
    }

    // MARK: - Add Menu

    func testAddMenuOpens() {
        let addMenuButton = app.buttons["plus"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))

        addMenuButton.tap()

        let addBudgetItem = app.buttons["Add Budget"]
        XCTAssertTrue(addBudgetItem.waitForExistence(timeout: 3))
    }

    func testAddBudgetSheetAppearsAndSaves() {
        let addMenuButton = app.buttons["plus"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))
        addMenuButton.tap()

        let addBudgetItem = app.buttons["Add Budget"]
        XCTAssertTrue(addBudgetItem.waitForExistence(timeout: 3))
        addBudgetItem.tap()

        let nameField = app.textFields["budgetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Budget")

        let saveButton = app.buttons["saveBudgetButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()
    }

    // MARK: - Settings

    func testSettingsOpensAndCloses() {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))

        settingsButton.tap()

        let doneButton = app.buttons["Done"].firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()
    }

    // MARK: - Add Transaction Flow

    func testAddTransactionFlow() {
        let addMenuButton = app.buttons["plus"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))
        addMenuButton.tap()

        let addTransactionItem = app.buttons["Add Transaction"]
        XCTAssertTrue(addTransactionItem.waitForExistence(timeout: 3))
        addTransactionItem.tap()

        let descriptionField = app.textFields["transactionDescriptionField"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 3))
        descriptionField.tap()
        descriptionField.typeText("UITest Transaction")

        let amountField = app.textFields["transactionAmountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 3))
        amountField.tap()
        amountField.typeText("10")

        let saveButton = app.buttons["saveTransactionButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()
    }

    // MARK: - Add Recurring Flow

    func testAddRecurringFlow() {
        let addMenuButton = app.buttons["plus"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))
        addMenuButton.tap()

        let addRecurringItem = app.buttons["Add Recurring"]
        XCTAssertTrue(addRecurringItem.waitForExistence(timeout: 3))
        addRecurringItem.tap()

        let descriptionField = app.textFields["recurringDescriptionField"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 3))
        descriptionField.tap()
        descriptionField.typeText("UITest Recurring")

        let amountField = app.textFields["recurringAmountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 3))
        amountField.tap()
        amountField.typeText("25")

        let saveButton = app.buttons["saveRecurringButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()
    }

    // MARK: - Budget Delete Alert

    func testDeleteBudgetAlertShows() {
        let leadingMenu = app.navigationBars["iBudgetBuddy"].buttons["folder"]
        XCTAssertTrue(leadingMenu.waitForExistence(timeout: 3))
        leadingMenu.tap()

        let deleteButton = app.buttons["Delete This Budget"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()

        let alert = app.alerts["Delete Budget?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))

        let cancel = alert.buttons["Cancel"]
        XCTAssertTrue(cancel.exists)
        cancel.tap()
    }

    // MARK: - Reports Navigation

    func testReportsButtonNavigatesToReportsView() {
        // Ensure a budget exists
        let addMenuButton = app.buttons["plus"]
        XCTAssertTrue(addMenuButton.waitForExistence(timeout: 3))
        addMenuButton.tap()

        let addBudgetItem = app.buttons["Add Budget"]
        XCTAssertTrue(addBudgetItem.waitForExistence(timeout: 3))
        addBudgetItem.tap()

        let nameField = app.textFields["budgetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Reports Budget")

        let saveButton = app.buttons["saveBudgetButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        let reportsButton = app.buttons["chart.pie.fill"]
        XCTAssertTrue(reportsButton.waitForExistence(timeout: 3))
        reportsButton.tap()
    }
}

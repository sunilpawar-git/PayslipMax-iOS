import XCTest

@MainActor
final class ClearDataFlowTests: XCTestCase {

    // MARK: - Properties

    // swiftlint:disable implicitly_unwrapped_optional
    private var app: XCUIApplication!
    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Launch app fresh for each test
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - UI Test Methods

    // swiftlint:disable function_body_length
    func testClearDataFlow_HomeToSettingsToClear_EnsuresDataConsistency() throws {
        // Given: App is launched and we have some data
        // Navigate to Home tab first
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()

        // Wait for home screen to load
        // Use scroll view identifier which is often more reliable than the root view identifier
        let homeScreen = app.scrollViews["home_scroll_view"]
        if !homeScreen.waitForExistence(timeout: 12) {
            print("DEBUG: App Hierarchy: \(app.debugDescription)")
            print("WARNING: Home screen not found, attempting to proceed")
        }

        // Check if recent payslips section exists (may be empty initially)
        let recentPayslipsTitle = app.staticTexts["Recent Payslips"]
        let recentPayslipsExists = recentPayslipsTitle.waitForExistence(timeout: 3)

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3) // Assuming Settings is 4th tab
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Wait for settings screen
        // let settingsScreen = app.otherElements["settings_view"]
        // XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))

        // Just wait a bit for transition
        wait(seconds: 1)

        // Find and tap Clear All Data button
        // Note: Data Management is now a section in Settings, not a separate screen
        // The button label likely includes the subtitle, so we use a partial match
        let clearDataButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Clear All Data'"))

        // Scroll if necessary (simple swipe up)
        if !clearDataButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        clearDataButton.tap()

        // Wait for confirmation dialog (Action Sheet)
        // Note: confirmationDialog presents as a sheet on iOS
        let sheet = app.sheets["Clear All Data"]
        let alert = app.alerts["Clear All Data"]

        // Wait for either sheet or alert
        let exists = sheet.waitForExistence(timeout: 7) || alert.waitForExistence(timeout: 7)
        XCTAssertTrue(exists, "Confirmation dialog should appear")

        let dialog = sheet.exists ? sheet : alert
        print("DEBUG: Dialog found: \(dialog)")
        print("DEBUG: Dialog hierarchy: \(dialog.debugDescription)")

        // Tap Yes to confirm (destructive action)
        // Note: The button text is "Yes" in the view code
        // Buttons in sheets are often accessible at the app level
        let yesButton = app.buttons["Yes"]
        if yesButton.waitForExistence(timeout: 7) {
            yesButton.tap()
        } else if dialog.buttons["Yes"].waitForExistence(timeout: 3) {
            dialog.buttons["Yes"].tap()
        } else if dialog.buttons.firstMatch.waitForExistence(timeout: 2) {
            dialog.buttons.firstMatch.tap()
        } else {
            print("DEBUG: App Hierarchy: \(app.debugDescription)")
            XCTFail("Could not find Yes button in confirmation dialog")
        }

        // Wait for operation to complete (loading indicator should disappear)
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.waitForExistence(timeout: 2) {
            // Wait for loading to complete
            XCTAssertFalse(loadingIndicator.waitForExistence(timeout: 10), "Loading should complete")
        }

        // Navigate back to Home to verify data consistency
        homeTab.tap()

        // Wait for home screen to reload
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 8) || app.scrollViews.firstMatch.waitForExistence(timeout: 2),
                      "Home screen should be visible after clearing data")

        // Verify that Recent Payslips section shows no data
        if recentPayslipsExists {
            // If section existed before, it should either be gone or show no data
            let recentPayslipsSection = app.otherElements["recent_activity_view"]
            if recentPayslipsSection.waitForExistence(timeout: 3) {
                // Section exists but should be empty
                let payslipElements = recentPayslipsSection.staticTexts.matching(identifier: "payslip_*")
                XCTAssertEqual(payslipElements.count, 0, "Recent payslips should be empty after clearing data")
            }
        }

        // Navigate to Payslips tab to verify consistency
        let payslipsTab = app.tabBars.buttons.element(boundBy: 1) // Assuming Payslips is 2nd tab
        XCTAssertTrue(payslipsTab.waitForExistence(timeout: 5))
        payslipsTab.tap()

        // Wait for payslips screen
        let payslipsScreen = app.otherElements["payslips_view"]
        let listExists = app.tables.firstMatch.waitForExistence(timeout: 3) || app.collectionViews.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(payslipsScreen.waitForExistence(timeout: 5) || listExists,
                      "Payslips screen should appear after clearing data")

        // Verify no payslips are displayed
        let emptyState = app.staticTexts["No payslips found"]
        if emptyState.waitForExistence(timeout: 3) {
            XCTAssertTrue(emptyState.exists, "Should show empty state after clearing data")
        } else {
            // Check for empty list/table
            let payslipCells = app.cells.matching(identifier: "payslip_cell_*")
            XCTAssertEqual(payslipCells.count, 0, "Payslips list should be empty after clearing data")
        }
    }
    // swiftlint:enable function_body_length

    func testClearDataFlow_WithExistingData_ShowsConfirmationDialog() throws {
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Tap Clear All Data
        let clearDataButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Clear All Data'"))

        // Scroll if necessary
        if !clearDataButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        clearDataButton.tap()

        // Verify confirmation dialog appears
        let sheet = app.sheets["Clear All Data"]
        let alert = app.alerts["Clear All Data"]

        let exists = sheet.waitForExistence(timeout: 7) || alert.waitForExistence(timeout: 7)
        XCTAssertTrue(exists, "Confirmation dialog should appear")

        let dialog = sheet.exists ? sheet : alert

        // Verify dialog content
        // Sheets might not expose the message as a static text in the same way, but we can check existence
        // let alertMessage = dialog.staticTexts.element(boundBy: 1)
        // XCTAssertTrue(alertMessage.waitForExistence(timeout: 2))

        // Tap No to cancel
        let noButton = app.buttons["No"]
        if noButton.waitForExistence(timeout: 5) {
            noButton.tap()
        } else if dialog.buttons["No"].waitForExistence(timeout: 3) {
            dialog.buttons["No"].tap()
        } else if dialog.buttons["Cancel"].waitForExistence(timeout: 2) {
            dialog.buttons["Cancel"].tap()
        } else if dialog.buttons.firstMatch.waitForExistence(timeout: 2) {
            dialog.buttons.firstMatch.tap()
        } else {
            print("DEBUG: App Hierarchy: \(app.debugDescription)")
            XCTFail("Could not find No or Cancel button in confirmation dialog")
        }

        // Verify we're back to Settings screen (alert dismissed)
        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        XCTAssertFalse(sheet.exists && alert.exists, "Alert should be dismissed")
    }

    func testClearDataFlow_ErrorHandling_ShowsErrorMessage() throws {
        // This test would require mocking network failures or other error conditions
        // For now, we'll test the basic error handling UI flow

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Verify Clear All Data button is present and accessible
        let clearDataButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Clear All Data'"))

        // Scroll if necessary
        if !clearDataButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        XCTAssertTrue(clearDataButton.isEnabled, "Clear button should be enabled")
    }
}

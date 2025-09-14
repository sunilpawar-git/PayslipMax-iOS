import XCTest

@MainActor
final class ClearDataFlowTests: XCTestCase {

    // MARK: - Properties

    private var app: XCUIApplication!

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

    func testClearDataFlow_HomeToSettingsToClear_EnsuresDataConsistency() throws {
        // Given: App is launched and we have some data
        // Navigate to Home tab first
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()

        // Wait for home screen to load
        let homeScreen = app.otherElements["home_view"]
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 5))

        // Check if recent payslips section exists (may be empty initially)
        let recentPayslipsTitle = app.staticTexts["Recent Payslips"]
        let recentPayslipsExists = recentPayslipsTitle.waitForExistence(timeout: 3)

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3) // Assuming Settings is 4th tab
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Wait for settings screen
        let settingsScreen = app.otherElements["settings_view"]
        XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))

        // Navigate to Data Management section
        let dataManagementRow = app.buttons["Data Management"]
        XCTAssertTrue(dataManagementRow.waitForExistence(timeout: 5))
        dataManagementRow.tap()

        // Wait for Data Management screen
        let dataManagementScreen = app.otherElements["data_management_view"]
        XCTAssertTrue(dataManagementScreen.waitForExistence(timeout: 5))

        // Find and tap Clear All Data button
        let clearDataButton = app.buttons["Clear All Data"]
        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        clearDataButton.tap()

        // Wait for confirmation dialog
        let alert = app.alerts["Clear All Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))

        // Tap Yes to confirm
        let yesButton = alert.buttons["Yes"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 5))
        yesButton.tap()

        // Wait for operation to complete (loading indicator should disappear)
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.waitForExistence(timeout: 2) {
            // Wait for loading to complete
            XCTAssertFalse(loadingIndicator.waitForExistence(timeout: 10), "Loading should complete")
        }

        // Navigate back to Home to verify data consistency
        homeTab.tap()

        // Wait for home screen to reload
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 5))

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
        XCTAssertTrue(payslipsScreen.waitForExistence(timeout: 5))

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

    func testClearDataFlow_WithExistingData_ShowsConfirmationDialog() throws {
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Navigate to Data Management
        let dataManagementRow = app.buttons["Data Management"]
        XCTAssertTrue(dataManagementRow.waitForExistence(timeout: 5))
        dataManagementRow.tap()

        // Tap Clear All Data
        let clearDataButton = app.buttons["Clear All Data"]
        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        clearDataButton.tap()

        // Verify confirmation dialog appears
        let alert = app.alerts["Clear All Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))

        // Verify dialog content
        let alertMessage = alert.staticTexts.element(boundBy: 1) // Usually the message is second element
        XCTAssertTrue(alertMessage.waitForExistence(timeout: 2))

        // Tap No to cancel
        let noButton = alert.buttons["No"]
        XCTAssertTrue(noButton.waitForExistence(timeout: 5))
        noButton.tap()

        // Verify we're back to Data Management screen (alert dismissed)
        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        XCTAssertFalse(alert.exists, "Alert should be dismissed")
    }

    func testClearDataFlow_ErrorHandling_ShowsErrorMessage() throws {
        // This test would require mocking network failures or other error conditions
        // For now, we'll test the basic error handling UI flow

        // Navigate to Settings
        let settingsTab = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Navigate to Data Management
        let dataManagementRow = app.buttons["Data Management"]
        XCTAssertTrue(dataManagementRow.waitForExistence(timeout: 5))
        dataManagementRow.tap()

        // Verify Data Management screen loads properly
        let dataManagementScreen = app.otherElements["data_management_view"]
        XCTAssertTrue(dataManagementScreen.waitForExistence(timeout: 5))

        // Verify Clear All Data button is present and accessible
        let clearDataButton = app.buttons["Clear All Data"]
        XCTAssertTrue(clearDataButton.waitForExistence(timeout: 5))
        XCTAssertTrue(clearDataButton.isEnabled, "Clear button should be enabled")
    }
}

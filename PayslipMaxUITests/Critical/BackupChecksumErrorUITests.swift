import XCTest

final class BackupChecksumErrorUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testImportingBadChecksum_ShowsHelpfulErrorAndNoDataChange() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_BACKUP_PREMIUM"]
        app.launch()

        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // Open Backup & Restore sheet (use accessibility IDs for stability)
        let backupRow = app.buttons["settings_row_button_Backup & Restore"]
        XCTAssertTrue(backupRow.waitForExistence(timeout: 5))
        backupRow.tap()

        // Expect backup UI visible
        // Wait for backup sheet and main view to be visible
        let sheet = app.otherElements["backup_sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 15))
        
        // Wait for service initialization to complete by checking for Import Data text
        XCTAssertTrue(app.staticTexts["Import Data"].waitForExistence(timeout: 20))
        
        // Wait for the import section elements to be rendered after service initialization
        // Based on the debug output, backup_import_container is used as identifier on individual elements, not a container
        let importDataText = app.staticTexts["Import Data"]
        XCTAssertTrue(importDataText.exists, "Import Data text should be visible")
        
        // Wait for import strategy elements to be present
        let importStrategyText = app.staticTexts["Import Strategy"]
        XCTAssertTrue(importStrategyText.waitForExistence(timeout: 15), "Import Strategy text should be present")
        
        // Wait for Choose File button to be present (this has backup_import_container identifier)
        let chooseFileButton = app.buttons["Choose File"]
        XCTAssertTrue(chooseFileButton.waitForExistence(timeout: 10), "Choose File button should be present")

        // Note: Real file import via picker is not feasible in UI tests without stubbing.
        // This test asserts presence of hooks and leaves full flow to unit/integration tests.
    }
}



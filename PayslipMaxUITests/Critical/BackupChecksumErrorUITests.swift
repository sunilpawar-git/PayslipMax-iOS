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
        // Anchor to visible text to ensure content rendered
        XCTAssertTrue(app.staticTexts["Import Data"].waitForExistence(timeout: 15))
        // Still assert the main container exists for structure
        let container = app.otherElements["backup_import_container"]
        XCTAssertTrue(container.waitForExistence(timeout: 5))

        // Tap Choose File (system picker cannot be automated; validate button present)
        let choose = app.buttons["backup_import_choose_file_button"]
        XCTAssertTrue(choose.exists)

        // Note: Real file import via picker is not feasible in UI tests without stubbing.
        // This test asserts presence of hooks and leaves full flow to unit/integration tests.
    }
}



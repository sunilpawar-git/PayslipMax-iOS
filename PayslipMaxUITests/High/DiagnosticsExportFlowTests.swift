import XCTest

final class DiagnosticsExportFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExportDiagnosticsBundleFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        // Open Debug Menu (exposed in UI_TESTING mode even if not DEBUG)
        let openDebugMenuButton = app.buttons["Open Debug Menu"]
        XCTAssertTrue(openDebugMenuButton.waitForExistence(timeout: 10))
        openDebugMenuButton.tap()

        // Tap Diagnostics Export link
        let exportCell = app.staticTexts["Export Diagnostics Bundle"]
        XCTAssertTrue(exportCell.waitForExistence(timeout: 5))
        exportCell.tap()

        // Tap Export button in diagnostics view
        let exportButton = app.buttons["diagnostics_export_button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        exportButton.tap()

        // Verify status appears (either no diagnostics yet or export path)
        let status = app.staticTexts["diagnostics_export_status"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
    }
}



import XCTest

/// Comprehensive UI tests for payslip context menu actions (delete and share)
/// These tests address the critical gap where context menu functionality was not being tested
final class PayslipContextMenuTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launchEnvironment["ENABLE_TEST_DATA"] = "true" // Ensure we have test payslips
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Delete Action Tests

    func testPayslipContextMenu_DeleteAction_ShowsConfirmationDialog() throws {
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        XCTAssertTrue(payslipsTab.waitForExistence(timeout: 5.0), "Payslips tab should exist")
        payslipsTab.tap()

        // Wait for payslip list to load
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // Find the first payslip row
        let firstPayslipRow = findFirstPayslipRow()
        guard firstPayslipRow.exists else {
            throw XCTSkip("No payslips available for testing")
        }

        // Long press to trigger context menu
        firstPayslipRow.press(forDuration: 1.0)

        // Wait for context menu to appear
        let contextMenu = app.menus.firstMatch
        if !contextMenu.waitForExistence(timeout: 2.0) {
            // Fallback: try looking for delete button directly
            let deleteButton = app.buttons["Delete Payslip"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 2.0), "Delete button should appear in context menu")
        }

        // Tap Delete button
        let deleteButton = app.buttons["Delete Payslip"]
        XCTAssertTrue(deleteButton.exists, "Delete button should be visible")
        deleteButton.tap()

        // Verify confirmation dialog appears
        let confirmDialog = app.alerts.firstMatch
        if !confirmDialog.waitForExistence(timeout: 2.0) {
            // Try confirmationDialog instead
            let confirmationDialog = app.sheets.firstMatch
            XCTAssertTrue(confirmationDialog.waitForExistence(timeout: 2.0),
                         "Confirmation dialog should appear after tapping delete")

            // Verify dialog message
            let dialogText = confirmationDialog.staticTexts["Are you sure you want to delete this payslip?"]
            XCTAssertTrue(dialogText.exists, "Confirmation message should be displayed")
        } else {
            // Alert-style confirmation
            XCTAssertTrue(confirmDialog.exists, "Confirmation alert should appear")
        }
    }

    func testPayslipContextMenu_DeleteAction_CancelButton_DoesNotDelete() throws {
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()

        // Wait for payslip list
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // Count payslips before deletion attempt
        let initialPayslipCount = countPayslipRows()
        guard initialPayslipCount > 0 else {
            throw XCTSkip("No payslips available for testing")
        }

        // Find and long press first payslip
        let firstPayslipRow = findFirstPayslipRow()
        firstPayslipRow.press(forDuration: 1.0)

        // Tap Delete
        let deleteButton = app.buttons["Delete Payslip"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2.0), "Delete button should appear")
        deleteButton.tap()

        // Tap Cancel in confirmation dialog
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2.0), "Cancel button should exist")
        cancelButton.tap()

        // Wait a moment for UI to settle
        Thread.sleep(forTimeInterval: 1.0)

        // Verify payslip count remains the same
        let finalPayslipCount = countPayslipRows()
        XCTAssertEqual(finalPayslipCount, initialPayslipCount,
                      "Payslip count should not change when canceling delete")
    }

    func testPayslipContextMenu_DeleteAction_SuccessfullyDeletesPayslip() throws {
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()

        // Wait for payslip list
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // Count payslips before deletion
        let initialPayslipCount = countPayslipRows()
        guard initialPayslipCount > 0 else {
            throw XCTSkip("No payslips available for testing")
        }

        // Find and long press first payslip
        let firstPayslipRow = findFirstPayslipRow()
        firstPayslipRow.press(forDuration: 1.0)

        // Tap Delete
        let deleteButton = app.buttons["Delete Payslip"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2.0), "Delete button should appear")
        deleteButton.tap()

        // Confirm deletion
        let confirmDeleteButton = app.buttons["Delete"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 2.0), "Confirm delete button should exist")
        confirmDeleteButton.tap()

        // Wait for deletion to complete
        Thread.sleep(forTimeInterval: 1.5)

        // Verify payslip count decreased
        let finalPayslipCount = countPayslipRows()
        XCTAssertEqual(finalPayslipCount, initialPayslipCount - 1,
                      "Payslip count should decrease by 1 after successful deletion")

        // Verify no error alert appeared
        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        XCTAssertFalse(errorAlert.exists, "No error alert should appear after successful deletion")
    }

    // MARK: - Share Action Tests

    func testPayslipContextMenu_ShareAction_OpensShareSheet() throws {
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()

        // Wait for payslip list
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // Find first payslip
        let firstPayslipRow = findFirstPayslipRow()
        guard firstPayslipRow.exists else {
            throw XCTSkip("No payslips available for testing")
        }

        // Long press to trigger context menu
        firstPayslipRow.press(forDuration: 1.0)

        // Tap Share button
        let shareButton = app.buttons["Share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 2.0), "Share button should appear in context menu")
        shareButton.tap()

        // Verify share sheet appears
        // Share sheet can appear as different UI elements depending on iOS version and device
        let shareSheet = app.sheets.firstMatch
        let activityView = app.otherElements["ActivityListView"]

        let shareUIAppeared = shareSheet.waitForExistence(timeout: 3.0) ||
                             activityView.waitForExistence(timeout: 3.0)

        XCTAssertTrue(shareUIAppeared, "Share sheet or activity view should appear")

        // Verify no error alert appeared
        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        XCTAssertFalse(errorAlert.exists, "No error alert should appear when opening share sheet")
    }

    func testPayslipContextMenu_ShareAction_Cancellation_NoError() throws {
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()

        // Wait for payslip list
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // Find first payslip
        let firstPayslipRow = findFirstPayslipRow()
        guard firstPayslipRow.exists else {
            throw XCTSkip("No payslips available for testing")
        }

        // Long press to trigger context menu
        firstPayslipRow.press(forDuration: 1.0)

        // Tap Share button
        let shareButton = app.buttons["Share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 2.0), "Share button should appear")
        shareButton.tap()

        // Wait for share sheet
        let shareSheet = app.sheets.firstMatch
        if shareSheet.waitForExistence(timeout: 3.0) {
            // Dismiss the share sheet by tapping outside or close button
            // Try to find close/cancel button
            let closeButton = shareSheet.buttons["Close"]
            let cancelButton = shareSheet.buttons["Cancel"]

            if closeButton.exists {
                closeButton.tap()
            } else if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Tap outside the sheet to dismiss (coordinate-based)
                let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
                coordinate.tap()
            }
        }

        // Wait for sheet to dismiss
        Thread.sleep(forTimeInterval: 1.0)

        // Verify no error appeared after cancellation
        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        XCTAssertFalse(errorAlert.exists, "No error should appear after canceling share")

        // Verify we're back on payslips list
        XCTAssertTrue(scrollView.exists, "Should return to payslips list")
    }

    func testPayslipContextMenu_ShareAction_ErrorHandling() throws {
        // This test verifies that if share fails, a proper error message is shown
        // Note: This might require mocking or special test conditions

        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()

        // Wait for payslip list
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Payslip list should load")

        // This test validates that if an error occurs during share,
        // it shows a user-friendly message (not "error 15")
        // The actual triggering of the error condition may require specific test setup

        // For now, we verify that error alerts use proper messaging
        // by checking that errors are displayed with readable text

        // Find first payslip
        let firstPayslipRow = findFirstPayslipRow()
        guard firstPayslipRow.exists else {
            throw XCTSkip("No payslips available for testing")
        }

        // Long press and tap share
        firstPayslipRow.press(forDuration: 1.0)
        let shareButton = app.buttons["Share"]
        if shareButton.waitForExistence(timeout: 2.0) {
            shareButton.tap()

            // If an error appears, verify it has proper message
            let errorAlert = app.alerts.firstMatch
            if errorAlert.waitForExistence(timeout: 2.0) {
                // Verify the error message is readable (not just "error 15")
                let errorMessage = errorAlert.staticTexts.element(boundBy: 1).label
                XCTAssertFalse(errorMessage.contains("error 15"),
                              "Error message should be user-friendly, not 'error 15'")
                XCTAssertTrue(errorMessage.count > 10,
                             "Error message should be descriptive")
            }
        }
    }

    // MARK: - Helper Methods

    /// Finds the first payslip row in the list
    private func findFirstPayslipRow() -> XCUIElement {
        // Try multiple strategies to find payslip rows

        // Strategy 1: Look for cells in scroll view
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            let cells = scrollView.otherElements.allElementsBoundByIndex
            for cell in cells {
                // Check if cell contains payslip-like content (currency symbols, dates, etc.)
                if cell.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '₹' OR label CONTAINS[c] 'L'")).firstMatch.exists {
                    return cell
                }
            }
        }

        // Strategy 2: Look for buttons with payslip identifiers
        let payslipButton = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'payslip_'")).firstMatch
        if payslipButton.exists {
            return payslipButton
        }

        // Strategy 3: Look for any tappable element with currency
        let currencyElement = app.otherElements.containing(NSPredicate(format: "label CONTAINS[c] '₹'")).firstMatch
        if currencyElement.exists {
            return currencyElement
        }

        // Fallback: Return first match that might be a payslip
        return scrollView.otherElements.firstMatch
    }

    /// Counts the number of payslip rows currently visible
    private func countPayslipRows() -> Int {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return 0 }

        var count = 0
        let elements = scrollView.otherElements.allElementsBoundByIndex

        for element in elements {
            // Count elements that look like payslip rows (have currency or date info)
            if element.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '₹' OR label CONTAINS[c] 'L'")).count > 0 {
                count += 1
            }
        }

        return count
    }
}


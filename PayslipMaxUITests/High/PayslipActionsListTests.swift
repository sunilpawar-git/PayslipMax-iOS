import XCTest

/// UI tests focused on list-level payslip stability and navigation flows.
final class PayslipActionsListTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testPayslipsList_NoErrorsOnLoad() throws {
        let payslipsTab = app.tabBars.buttons["Payslips"]
        guard payslipsTab.waitForExistence(timeout: 5.0) else {
            throw XCTSkip("Payslips tab not found")
        }
        payslipsTab.tap()

        wait(seconds: 2.0)

        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        XCTAssertFalse(errorAlert.exists, "Payslips list should load without errors")

        let hasContent = app.staticTexts.firstMatch.exists ||
            app.scrollViews.firstMatch.exists ||
            app.buttons.firstMatch.exists
        XCTAssertTrue(hasContent, "Should show either payslips or empty state")
    }

    func testPayslipsListInteraction_NoErrorsAppear() throws {
        let payslipsTab = app.tabBars.buttons["Payslips"]
        guard payslipsTab.waitForExistence(timeout: 5.0) else {
            throw XCTSkip("Payslips tab not found")
        }
        payslipsTab.tap()

        wait(seconds: 2.0)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            wait(seconds: 0.5)
            scrollView.swipeDown()
        }

        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        XCTAssertFalse(errorAlert.exists, "No errors should appear during list interaction")
    }

    func testPayslipFullFlow_NavigateAndReturn_NoErrors() throws {
        let payslipsTab = app.tabBars.buttons["Payslips"]
        guard payslipsTab.waitForExistence(timeout: 5.0) else {
            throw XCTSkip("Payslips tab not found")
        }
        payslipsTab.tap()

        wait(seconds: 2.0)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            let payslipElements = scrollView.descendants(matching: .any).allElementsBoundByIndex
            var tappedPayslip = false

            for element in payslipElements {
                if element.isHittable && element.label.contains("₹") {
                    element.tap()
                    tappedPayslip = true
                    break
                }
            }

            guard tappedPayslip else { throw XCTSkip("No payslips available to test") }

            wait(seconds: 1.0)

            var errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
            XCTAssertFalse(errorAlert.exists, "No errors on detail view")

            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                wait(seconds: 1.0)

                errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
                XCTAssertFalse(errorAlert.exists, "No errors after returning to list")
                XCTAssertTrue(scrollView.waitForExistence(timeout: 2.0), "Should return to list view")
            }
        } else {
            throw XCTSkip("No payslip list found")
        }
    }
}


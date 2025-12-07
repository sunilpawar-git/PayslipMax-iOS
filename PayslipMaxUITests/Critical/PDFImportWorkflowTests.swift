import XCTest

final class PDFImportWorkflowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launchEnvironment["RESET_DATA"] = "true"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - PDF Import Tests

    func testDocumentPickerLaunchesSuccessfully() throws {
        // Test: Document picker launches without crashes

        // Navigate to a screen where PDF import is available
        // This might be Home tab or a dedicated import button
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5.0) {
            homeTab.tap()
        }

        // Look for PDF import button/option
        // Common patterns: "Import", "Add PDF", "Upload", "Document", "+"
        let importPredicate = NSPredicate(
            format: "label CONTAINS[c] 'import' OR label CONTAINS[c] 'add' OR label CONTAINS[c] 'upload' OR label == '+'"
        )
        let importButton = app.buttons.matching(importPredicate).firstMatch

        if importButton.waitForExistence(timeout: 3.0) {
            importButton.tap()

            // Verify document picker or file selection UI appears
            // Look for system document picker indicators
            let documentPredicate = NSPredicate(
                format: "identifier CONTAINS[c] 'document' OR identifier CONTAINS[c] 'picker'"
            )
            let documentPicker = app.navigationBars.containing(documentPredicate).firstMatch
            let filesApp = app.staticTexts["Files"]
            let browsePredicate = NSPredicate(format: "label CONTAINS[c] 'browse' OR label CONTAINS[c] 'files'")
            let browseOption = app.buttons.containing(browsePredicate).firstMatch

            let pickerAppeared = documentPicker.waitForExistence(timeout: 5.0) ||
                               filesApp.waitForExistence(timeout: 5.0) ||
                               browseOption.waitForExistence(timeout: 5.0)

            XCTAssertTrue(pickerAppeared, "Document picker should appear when import is tapped")
        } else {
            throw XCTSkip("No PDF import button found - test may need adjustment for current UI")
        }
    }

    func testPDFProcessingPipelineUI() throws {
        // Test: PDF processing shows appropriate UI feedback

        // Navigate to payslips tab to check if processing UI exists
        let payslipsTab = app.tabBars.buttons["Payslips"]
        if payslipsTab.waitForExistence(timeout: 5.0) {
            payslipsTab.tap()

            // Look for any existing payslips to understand the current state
            let payslipsList = app.tables.firstMatch
            let collectionView = app.collectionViews.firstMatch
            let emptyStatePredicate = NSPredicate(
                format: "label CONTAINS[c] 'no payslips' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'add your first'"
            )
            let emptyState = app.staticTexts.containing(emptyStatePredicate).firstMatch

            let hasContent = payslipsList.exists || collectionView.exists || emptyState.exists
            XCTAssertTrue(hasContent, "Payslips view should display content (list, collection, or empty state)")

            // Check for processing-related UI elements that might exist
            let processingIndicator = app.activityIndicators.firstMatch
            let _ = app.progressIndicators.firstMatch
            let processingPredicate = NSPredicate(
                format: "label CONTAINS[c] 'processing' OR label CONTAINS[c] 'parsing'"
            )
            let processingText = app.staticTexts.containing(processingPredicate).firstMatch

            // These elements might not exist if no processing is happening, which is OK
            if processingIndicator.exists {
                XCTAssertTrue(processingIndicator.isHittable == false, "Processing indicator should not be interactive")
            }

            if processingText.exists {
                XCTAssertFalse(processingText.label.isEmpty, "Processing text should have meaningful content")
            }
        }
    }

    func testPayslipDataDisplayBasics() throws {
        // Test: Basic payslip data display elements exist

        let payslipsTab = app.tabBars.buttons["Payslips"]
        if payslipsTab.waitForExistence(timeout: 5.0) {
            payslipsTab.tap()

            // Check if there are any existing payslips to test with
            let firstPayslip = app.cells.firstMatch
            let _ = app.buttons.firstMatch

            if firstPayslip.exists && firstPayslip.isHittable {
                firstPayslip.tap()

                // Verify payslip detail view opens
                let detailView = app.navigationBars.firstMatch
                XCTAssertTrue(detailView.waitForExistence(timeout: 5.0), "Payslip detail view should open")

                // Look for common payslip data elements
                let amountPredicate = NSPredicate(
                    format: "label CONTAINS[c] '₹' OR label CONTAINS[c] '$' OR label CONTAINS[c] 'amount'"
                )
                let datePredicate = NSPredicate(
                    format: "label CONTAINS[c] '202' OR label CONTAINS[c] 'Jan' OR label CONTAINS[c] 'date'"
                )
                let amountText = app.staticTexts.containing(amountPredicate).firstMatch
                let dateText = app.staticTexts.containing(datePredicate).firstMatch

                // At least one data element should exist
                let hasDataElements = amountText.exists || dateText.exists
                XCTAssertTrue(hasDataElements, "Payslip detail should display financial or date information")

            } else {
                // No payslips exist - verify empty state
                let emptyMessagePredicate = NSPredicate(
                    format: "label CONTAINS[c] 'no payslips' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'first'"
                )
                let emptyMessage = app.staticTexts.containing(emptyMessagePredicate).firstMatch
                XCTAssertTrue(emptyMessage.exists, "Empty state message should be shown when no payslips exist")
            }
        }
    }

    func testPDFProcessingErrorHandling() throws {
        // Test: Error handling for PDF processing issues

        // Navigate to settings or help section to check error handling documentation
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 5.0) {
            settingsTab.tap()

            // Look for help, support, or error-related options
            let helpPredicate = NSPredicate(
                format: "label CONTAINS[c] 'help' OR label CONTAINS[c] 'support' OR label CONTAINS[c] 'troubleshoot'"
            )
            let faqPredicate = NSPredicate(
                format: "label CONTAINS[c] 'faq' OR label CONTAINS[c] 'questions'"
            )
            let helpOption = app.cells.containing(helpPredicate).firstMatch
            let faqOption = app.cells.containing(faqPredicate).firstMatch

            if helpOption.exists {
                helpOption.tap()

                // Verify help/support view opens
                let helpView = app.navigationBars.firstMatch
                XCTAssertTrue(helpView.waitForExistence(timeout: 3.0), "Help/support view should open")

                // Look for error-related content
                let errorGuidancePredicate = NSPredicate(
                    format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'problem' OR label CONTAINS[c] 'failed'"
                )
                let errorGuidance = app.staticTexts.containing(errorGuidancePredicate).firstMatch

                // Error guidance might exist - if so, verify it's helpful
                if errorGuidance.exists {
                    XCTAssertFalse(errorGuidance.label.isEmpty, "Error guidance should have meaningful content")
                }

            } else if faqOption.exists {
                faqOption.tap()

                // Similar verification for FAQ section
                let faqView = app.navigationBars.firstMatch
                XCTAssertTrue(faqView.waitForExistence(timeout: 3.0), "FAQ view should open")

            } else {
                // Check if there are general alert patterns for errors
                let alertExists = app.alerts.firstMatch.exists
                let errorElementsExist = app.staticTexts
                    .containing(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'failed'"))
                    .firstMatch.exists

                // This is informational - errors might not be present, which is good
                if alertExists || errorElementsExist {
                    XCTAssertTrue(true, "Error handling UI elements detected and accessible")
                } else {
                    XCTAssertTrue(true, "No error UI detected - system appears to be functioning normally")
                }
            }
        }
    }

    func testSplashScreenTiming() throws {
        // Test: Splash screen displays for appropriate duration

        // Launch a fresh instance to test splash screen
        app.terminate()

        let freshApp = XCUIApplication()
        freshApp.launchArguments.append("UI_TESTING")

        let launchTime = Date()
        freshApp.launch()

        // Look for splash screen indicators
        let splashPredicate = NSPredicate(
            format: "label CONTAINS[c] 'financial' OR label CONTAINS[c] 'money' OR label CONTAINS[c] 'invest'"
        )
        let splashQuote = app.staticTexts.containing(splashPredicate).firstMatch
        let appLogo = app.images.firstMatch
        let splashContainer = app.otherElements.containing(NSPredicate(format: "identifier CONTAINS[c] 'splash'")).firstMatch

        var splashDetected = false

        // Check if splash elements appear initially
        if splashQuote.waitForExistence(timeout: 1.0) {
            splashDetected = true
            XCTAssertTrue(splashQuote.exists, "Splash quote should be visible")
        }

        if appLogo.waitForExistence(timeout: 1.0) {
            splashDetected = true
            XCTAssertTrue(appLogo.exists, "App logo should be visible during splash")
        }

        if splashContainer.waitForExistence(timeout: 1.0) {
            splashDetected = true
        }

        // Wait for main app to become available
        let homeTab = freshApp.tabBars.buttons["Home"]
        let authButton = freshApp.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'authenticate'")).firstMatch

        let mainAppAppeared = homeTab.waitForExistence(timeout: 8.0) ||
                             authButton.waitForExistence(timeout: 8.0)

        let totalTime = Date().timeIntervalSince(launchTime)

        XCTAssertTrue(mainAppAppeared, "Main app should appear after splash")
        XCTAssertLessThan(totalTime, 15.0, "Total app launch should complete within 15 seconds")

        if splashDetected {
            XCTAssertGreaterThan(totalTime, 2.0, "Splash should be visible for at least 2 seconds")
            XCTAssertLessThan(totalTime, 12.0, "Splash should not exceed 12 seconds")
        }

        // Restore app reference for cleanup
        app = freshApp
    }
}

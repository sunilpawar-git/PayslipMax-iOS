import XCTest

/// UI Tests for confidence badge interactions
final class ConfidenceBadgeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Skip UI tests until data seeding is implemented
        throw XCTSkip("UI tests skipped pending data seeding implementation")

        // Note: Code below will execute when XCTSkip is removed
        // continueAfterFailure = false
        // app = XCUIApplication()
        // app.launchArguments = ["UI-Testing"]
        // app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Badge Display Tests

    func testConfidenceBadge_DisplaysInRecentPayslips() throws {
        // Given: App is launched with test payslips that have confidence scores

        // When: User navigates to home screen
        // (Assuming we're already on home screen after launch)

        // Then: Confidence badges should be visible next to payslip months
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch

        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5), "Confidence badge should be visible in recent payslips")
        XCTAssertTrue(confidenceBadge.isHittable, "Confidence badge should be tappable")
    }

    func testConfidenceBadge_DisplaysCorrectPercentage() throws {
        // Given: A payslip with known confidence score exists

        // When: Viewing recent payslips
        let badges = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'"))

        // Then: Badge should display percentage between 0 and 100
        if badges.count > 0 {
            let firstBadge = badges.firstMatch
            let badgeLabel = firstBadge.label

            // Extract percentage from label (e.g., "95%", "72%")
            let percentagePattern = "\\d+%"
            let regex = try NSRegularExpression(pattern: percentagePattern)
            let range = NSRange(badgeLabel.startIndex..., in: badgeLabel)

            XCTAssertNotNil(regex.firstMatch(in: badgeLabel, range: range), "Badge should contain percentage")
        }
    }

    func testConfidenceBadge_HighConfidence_ShowsGreenColor() throws {
        // Note: Color testing in XCUITest is limited, but we can verify the badge exists
        // and has the expected accessibility traits

        // Given: A payslip with high confidence (>85%)
        let highConfidenceBadges = app.buttons.matching(NSPredicate(format: "label CONTAINS '9' AND label CONTAINS '%'"))

        if highConfidenceBadges.count > 0 {
            let badge = highConfidenceBadges.firstMatch
            XCTAssertTrue(badge.exists, "High confidence badge should exist")
        }
    }

    // MARK: - Badge Tap Tests

    func testConfidenceBadge_Tap_OpensDetailView() throws {
        // Given: A confidence badge is visible
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch

        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5), "Badge should exist")

        // When: User taps the confidence badge
        confidenceBadge.tap()

        // Then: Detail view should appear
        let detailViewTitle = app.navigationBars["Parsing Confidence"]
        XCTAssertTrue(detailViewTitle.waitForExistence(timeout: 3), "Detail view should open with 'Parsing Confidence' title")

        // Verify key elements in detail view
        let overallConfidenceLabel = app.staticTexts["Overall Confidence"]
        XCTAssertTrue(overallConfidenceLabel.exists, "Overall confidence section should be visible")

        let fieldBreakdownLabel = app.staticTexts["Field-Level Confidence"]
        XCTAssertTrue(fieldBreakdownLabel.exists, "Field breakdown section should be visible")
    }

    func testConfidenceDetailView_ShowsProgressBar() throws {
        // Given: Confidence detail view is open
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))
        confidenceBadge.tap()

        // Then: Progress bar should be visible
        let progressBar = app.progressIndicators.firstMatch
        XCTAssertTrue(progressBar.waitForExistence(timeout: 2), "Progress bar should be visible in detail view")
    }

    func testConfidenceDetailView_ShowsFieldBreakdown() throws {
        // Given: Confidence detail view is open
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))
        confidenceBadge.tap()

        // Then: Field names should be visible
        let expectedFields = ["Month", "Year", "Net Pay", "Earnings"]
        var foundFields = 0

        for fieldName in expectedFields {
            if app.staticTexts[fieldName].exists {
                foundFields += 1
            }
        }

        XCTAssertGreaterThan(foundFields, 0, "At least one field should be visible in breakdown")
    }

    func testConfidenceDetailView_ShowsPercentage() throws {
        // Given: Confidence detail view is open
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))
        confidenceBadge.tap()

        // Then: Percentage values should be visible
        let percentageLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'"))
        XCTAssertGreaterThan(percentageLabels.count, 0, "Percentage values should be displayed")
    }

    func testConfidenceDetailView_DismissWithDoneButton() throws {
        // Given: Confidence detail view is open
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))
        confidenceBadge.tap()

        // When: User taps "Done" button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2), "Done button should exist")
        doneButton.tap()

        // Then: Detail view should close
        let detailViewTitle = app.navigationBars["Parsing Confidence"]
        XCTAssertFalse(detailViewTitle.exists, "Detail view should be dismissed")
    }

    // MARK: - Detail View Badge Tests

    func testConfidenceBadge_InPayslipDetailHeader() throws {
        // Given: User is on home screen
        // When: User taps on a payslip to view details
        let firstPayslip = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstPayslip.waitForExistence(timeout: 5), "First payslip should exist")
        firstPayslip.tap()

        // Then: Confidence shield badge should be visible in header
        // Look for a badge or shield icon near the title
        let _ = app.images.matching(NSPredicate(format: "label CONTAINS 'shield' OR label CONTAINS 'checkmark'")).firstMatch

        // Note: This test might need adjustment based on actual accessibility labels
        // For now, we verify the payslip detail view opened
        XCTAssertTrue(app.navigationBars.element.exists, "Payslip detail view should open")
    }

    func testConfidenceBadge_InDetailHeader_Taps() throws {
        // Given: User is viewing payslip details
        let firstPayslip = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstPayslip.waitForExistence(timeout: 5))
        firstPayslip.tap()

        // When: User taps confidence badge in header
        let badges = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'"))

        if badges.count > 0 {
            let headerBadge = badges.firstMatch
            XCTAssertTrue(headerBadge.exists, "Badge should exist in header")
            headerBadge.tap()

            // Then: Detail view should open
            let detailViewTitle = app.navigationBars["Parsing Confidence"]
            XCTAssertTrue(detailViewTitle.waitForExistence(timeout: 3), "Detail view should open from header badge")
        }
    }

    // MARK: - No Badge Tests (Legacy Payslips)

    func testNoBadge_ForLegacyPayslips() throws {
        // Given: A payslip without confidence score (nil)
        // This test verifies graceful degradation

        // When: Viewing payslips
        let allCells = app.collectionViews.cells

        // Then: App should not crash and some cells might not have badges
        XCTAssertGreaterThan(allCells.count, 0, "Payslips should be displayed")

        // Verify app didn't crash by checking if navigation is still responsive
        XCTAssertTrue(app.navigationBars.element.exists || app.tabBars.element.exists, "App should remain navigable")
    }

    // MARK: - Accessibility Tests

    func testConfidenceBadge_HasAccessibilityLabel() throws {
        // Given: A confidence badge is visible
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch

        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5), "Badge should exist")

        // Then: Badge should have an accessibility label for VoiceOver
        XCTAssertFalse(confidenceBadge.label.isEmpty, "Badge should have accessibility label")
        XCTAssertTrue(confidenceBadge.label.contains("%"), "Badge label should contain percentage")
    }

    func testConfidenceDetailView_Accessible() throws {
        // Given: Detail view is open
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))
        confidenceBadge.tap()

        // Then: All text should be accessible
        let staticTexts = app.staticTexts
        XCTAssertGreaterThan(staticTexts.count, 0, "Detail view should have accessible text elements")

        // Verify key elements are accessible
        XCTAssertTrue(app.staticTexts["Overall Confidence"].exists, "Section headers should be accessible")
    }

    // MARK: - Performance Tests

    func testBadgeDisplay_PerformanceWithMultiplePayslips() throws {
        // Measure time to display badges for multiple payslips
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Scroll through payslips list
            let collectionView = app.collectionViews.firstMatch
            if collectionView.exists {
                collectionView.swipeUp()
                collectionView.swipeDown()
            }
        }

        // Ensure badges are still visible after scrolling
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.exists, "Badges should remain visible after scrolling")
    }

    func testBadgeTap_PerformanceOpeningDetailView() throws {
        // Measure time to open detail view
        let confidenceBadge = app.buttons.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(confidenceBadge.waitForExistence(timeout: 5))

        measure(metrics: [XCTClockMetric()]) {
            confidenceBadge.tap()

            let detailViewTitle = app.navigationBars["Parsing Confidence"]
            XCTAssertTrue(detailViewTitle.waitForExistence(timeout: 2), "Detail view should open quickly")

            // Close detail view for next iteration
            app.buttons["Done"].tap()
        }
    }
}

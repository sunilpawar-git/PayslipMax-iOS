import XCTest

class HomeViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    func testAppLaunchesSuccessfully() {
        // Just check if the app is running
        XCTAssertTrue(app.state == .runningForeground, "App should be running in the foreground")
    }
    
    func testHomeViewBasicElements() {
        // Check for header elements
        let headerElements = app.otherElements.matching(identifier: "home_header")
        XCTAssertEqual(headerElements.count, 3, "Home header should have 3 elements (logo, text, container)")
        
        let headerText = app.staticTexts["home_header"]
        XCTAssertTrue(headerText.exists, "Home header text should exist")
        XCTAssertEqual(headerText.label, "Payslip Max", "Header text should be 'Payslip Max'")
        
        // Check for action buttons
        let actionButtons = app.buttons.matching(identifier: "action_buttons")
        XCTAssertEqual(actionButtons.count, 3, "There should be 3 action buttons")
        
        // Check for countdown view
        let countdownView = app.otherElements["countdown_view"]
        XCTAssertTrue(countdownView.exists, "Countdown view should exist")
        
        // Check for empty state view (when no payslips)
        let emptyStateView = app.otherElements["empty_state_view"]
        XCTAssertTrue(emptyStateView.exists, "Empty state view should exist when no payslips")
        
        // Check for tips view
        let tipsView = app.otherElements["tips_view"]
        XCTAssertTrue(tipsView.exists, "Tips view should exist")
        
        // Check for scroll view
        let scrollView = app.scrollViews["home_scroll_view"]
        XCTAssertTrue(scrollView.exists, "Home scroll view should exist")
    }
    
    func testActionButtonInteractions() {
        // Test Upload button
        let uploadButton = app.buttons.matching(identifier: "action_buttons").element(boundBy: 0)
        XCTAssertTrue(uploadButton.exists, "Upload button should exist")
        uploadButton.tap()
        
        // Verify document picker sheet appears
        let documentPicker = app.sheets["Document Picker"]
        XCTAssertTrue(documentPicker.exists, "Document picker should appear after tapping upload")
        
        // Dismiss document picker
        app.buttons["Cancel"].tap()
        
        // Test Scan button
        let scanButton = app.buttons.matching(identifier: "action_buttons").element(boundBy: 1)
        XCTAssertTrue(scanButton.exists, "Scan button should exist")
        scanButton.tap()
        
        // Verify scanner sheet appears
        let scannerView = app.sheets["Scanner"]
        XCTAssertTrue(scannerView.exists, "Scanner should appear after tapping scan")
        
        // Dismiss scanner
        app.buttons["Cancel"].tap()
        
        // Test Manual button
        let manualButton = app.buttons.matching(identifier: "action_buttons").element(boundBy: 2)
        XCTAssertTrue(manualButton.exists, "Manual button should exist")
        manualButton.tap()
        
        // Verify manual entry sheet appears
        let manualEntryView = app.sheets["Manual Entry"]
        XCTAssertTrue(manualEntryView.exists, "Manual entry should appear after tapping manual")
        
        // Dismiss manual entry
        app.buttons["Cancel"].tap()
    }
    
    func testTabBarNavigation() {
        // Test navigation between tabs
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected initially")
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        XCTAssertTrue(payslipsTab.exists, "Payslips tab should exist")
        payslipsTab.tap()
        XCTAssertTrue(payslipsTab.isSelected, "Payslips tab should be selected after tapping")
        
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.exists, "Insights tab should exist")
        insightsTab.tap()
        XCTAssertTrue(insightsTab.isSelected, "Insights tab should be selected after tapping")
        
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected after tapping")
        
        // Navigate back to Home
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected after returning")
    }
    
    func testScrollingAndContentVisibility() {
        let scrollView = app.scrollViews["home_scroll_view"]
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Scroll down to see tips
        scrollView.swipeUp()
        
        // Check if tips are visible after scrolling
        let tipsView = app.otherElements["tips_view"]
        XCTAssertTrue(tipsView.exists, "Tips view should be visible after scrolling")
        
        // Scroll back up
        scrollView.swipeDown()
        
        // Check if header is visible after scrolling back
        let headerElements = app.otherElements.matching(identifier: "home_header")
        XCTAssertTrue(headerElements.firstMatch.exists, "Header should be visible after scrolling back")
    }
    
    func testLoadingState() {
        // Simulate loading state by adding a payslip
        let uploadButton = app.buttons.matching(identifier: "action_buttons").element(boundBy: 0)
        uploadButton.tap()
        
        // Verify loading overlay appears
        let loadingOverlay = app.otherElements["loading_overlay"]
        XCTAssertTrue(loadingOverlay.exists, "Loading overlay should appear during processing")
        
        // Dismiss document picker
        app.buttons["Cancel"].tap()
        
        // Verify loading overlay disappears
        XCTAssertFalse(loadingOverlay.exists, "Loading overlay should disappear after processing")
    }
    
    func testErrorHandling() {
        // Simulate error state by adding an invalid PDF
        let uploadButton = app.buttons.matching(identifier: "action_buttons").element(boundBy: 0)
        uploadButton.tap()
        
        // Verify error alert appears
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.exists, "Error alert should appear when processing fails")
        
        // Dismiss error alert
        app.buttons["OK"].tap()
        
        // Verify error alert is dismissed
        XCTAssertFalse(errorAlert.exists, "Error alert should be dismissed after tapping OK")
    }
} 
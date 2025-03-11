import XCTest

final class HomeViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic UI Tests
    
    func testHomeViewBasicElements() throws {
        // Test header elements
        XCTAssertTrue(app.images["home_logo"].exists)
        XCTAssertTrue(app.staticTexts["home_title"].exists)
        
        // Test action buttons
        XCTAssertTrue(app.buttons["upload_button"].exists)
        XCTAssertTrue(app.buttons["scan_button"].exists)
        XCTAssertTrue(app.buttons["manual_button"].exists)
        
        // Test countdown view
        XCTAssertTrue(app.otherElements["countdown_view"].exists)
        
        // Test tips view
        XCTAssertTrue(app.otherElements["tips_view"].exists)
        
        // Verify action buttons are enabled
        XCTAssertTrue(app.buttons["upload_button"].isEnabled)
        XCTAssertTrue(app.buttons["scan_button"].isEnabled)
        XCTAssertTrue(app.buttons["manual_button"].isEnabled)
    }
    
    // MARK: - Navigation Tests
    
    func testHomeViewNavigation() throws {
        // Test navigation to payslips view
        app.tabBars.buttons["Payslips"].tap()
        XCTAssertTrue(app.navigationBars["Payslips"].exists)
        
        // Test navigation to insights view
        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["Financial Insights"].exists)
        
        // Test navigation to settings view
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Test navigation back to home
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.images["home_logo"].exists)
    }
    
    // MARK: - Action Tests
    
    func testHomeViewActions() throws {
        // Test upload button action
        app.buttons["upload_button"].tap()
        XCTAssertTrue(app.sheets.element.exists)
        app.sheets.element.buttons["Cancel"].tap()
        
        // Test scan button action
        app.buttons["scan_button"].tap()
        XCTAssertTrue(app.sheets.element.exists)
        app.sheets.element.buttons["Cancel"].tap()
        
        // Test manual button action
        app.buttons["manual_button"].tap()
        XCTAssertTrue(app.navigationBars["Manual Entry"].exists)
        app.navigationBars["Manual Entry"].buttons["Cancel"].tap()
    }
    
    // MARK: - Recent Payslips Tests
    
    func testRecentPayslipsSection() throws {
        // Test recent payslips section exists (if we have test data)
        if app.otherElements["recent_activity_view"].exists {
            XCTAssertTrue(app.staticTexts["recent_payslips_title"].exists)
            
            // Test navigation to payslip detail
            let firstPayslip = app.otherElements["recent_activity_view"].cells.firstMatch
            if firstPayslip.exists {
                firstPayslip.tap()
                // Verify we're on the detail view
                XCTAssertTrue(app.navigationBars.element.exists)
                // Navigate back
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Charts Tests
    
    func testChartsSection() throws {
        // Test charts section exists (if we have test data)
        if app.otherElements["charts_view"].exists {
            // Verify chart controls exist
            XCTAssertTrue(app.segmentedControls.firstMatch.exists)
            
            // Test chart type switching
            let chartSegments = app.segmentedControls.firstMatch.buttons
            XCTAssertTrue(chartSegments.count > 0)
            
            // Switch through different chart types
            for segment in chartSegments.allElementsBoundByIndex {
                segment.tap()
                // Add small delay to let chart update
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertTrue(app.otherElements["charts_view"].exists)
            }
        } else {
            // If no data, verify empty state
            XCTAssertTrue(app.otherElements["empty_state_view"].exists)
        }
    }
    
    // MARK: - Tips Section Tests
    
    func testTipsSection() throws {
        XCTAssertTrue(app.otherElements["tips_view"].exists)
        
        // Verify tips content
        let tipsView = app.otherElements["tips_view"]
        XCTAssertTrue(tipsView.staticTexts["Tips & Tricks"].exists)
        
        // Verify at least one tip exists
        XCTAssertTrue(tipsView.images["lightbulb.fill"].firstMatch.exists)
    }
    
    // MARK: - Scroll Tests
    
    func testHomeViewScrolling() throws {
        // Get the main scroll view
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        
        // Test scrolling to bottom
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Verify tips section is visible after scrolling
        XCTAssertTrue(app.otherElements["tips_view"].isHittable)
        
        // Test scrolling back to top
        end.press(forDuration: 0.1, thenDragTo: start)
        
        // Verify header is visible after scrolling back
        XCTAssertTrue(app.otherElements["home_header"].isHittable)
    }
    
    // MARK: - State Change Tests
    
    func testHomeViewStateChanges() throws {
        // Test app state changes
        app.terminate()
        app.launch()
        
        // Verify all elements are restored
        XCTAssertTrue(app.images["home_logo"].exists)
        XCTAssertTrue(app.buttons["upload_button"].exists)
        
        // Test background/foreground transition
        app.terminate()
        app.activate()
        
        // Verify view state is preserved
        XCTAssertTrue(app.images["home_logo"].exists)
        XCTAssertTrue(app.buttons["upload_button"].exists)
    }
    
    // MARK: - Error Scenarios Tests
    
    func testHomeViewErrorScenarios() throws {
        // Test invalid PDF upload
        app.buttons["upload_button"].tap()
        
        // Select an invalid file (if possible in UI test)
        if let invalidFileButton = app.sheets.element.buttons["invalid_file"] {
            invalidFileButton.tap()
            
            // Verify error alert appears
            XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.alerts.element.staticTexts["Invalid PDF format"].exists)
            
            // Dismiss error
            app.alerts.element.buttons["OK"].tap()
        }
        app.sheets.element.buttons["Cancel"].tap()
        
        // Test scanner error
        app.buttons["scan_button"].tap()
        if app.sheets.element.exists {
            // Simulate scanner error (if possible)
            if let errorButton = app.sheets.element.buttons["simulate_error"] {
                errorButton.tap()
                
                // Verify error alert appears
                XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 2))
                XCTAssertTrue(app.alerts.element.staticTexts["Scanner unavailable"].exists)
                
                // Dismiss error
                app.alerts.element.buttons["OK"].tap()
            }
            app.sheets.element.buttons["Cancel"].tap()
        }
        
        // Test manual entry validation
        app.buttons["manual_button"].tap()
        
        // Try to save without required fields
        if let saveButton = app.buttons["save_button"] {
            saveButton.tap()
            
            // Verify validation error appears
            XCTAssertTrue(app.staticTexts["Required fields missing"].exists)
        }
        
        // Test invalid input values
        let nameField = app.textFields["name_field"]
        let creditsField = app.textFields["credits_field"]
        
        // Test empty name
        nameField.tap()
        nameField.typeText("")
        
        // Test invalid credits (negative value)
        creditsField.tap()
        creditsField.typeText("-1000")
        
        // Try to save
        if let saveButton = app.buttons["save_button"] {
            saveButton.tap()
            
            // Verify validation errors
            XCTAssertTrue(app.staticTexts["Name is required"].exists)
            XCTAssertTrue(app.staticTexts["Credits must be positive"].exists)
        }
        
        // Dismiss manual entry
        app.navigationBars["Manual Entry"].buttons["Cancel"].tap()
    }
    
    // MARK: - Edge Case Tests
    
    func testHomeViewEdgeCases() throws {
        // Test rapid button tapping
        for _ in 1...5 {
            app.buttons["upload_button"].tap()
            app.sheets.element.buttons["Cancel"].tap()
        }
        
        // Test multiple concurrent actions
        app.buttons["upload_button"].tap()
        app.buttons["scan_button"].tap()
        app.buttons["manual_button"].tap()
        
        // Only the first sheet should be visible
        XCTAssertEqual(app.sheets.count, 1)
        
        // Dismiss all sheets
        while app.sheets.firstMatch.exists {
            app.sheets.firstMatch.buttons["Cancel"].tap()
        }
        
        // Test offline mode behavior
        // Note: This requires the app to handle offline mode properly
        if let networkSwitch = app.switches["network_switch"] {
            networkSwitch.tap() // Turn off network
            
            // Verify offline indicators
            XCTAssertTrue(app.staticTexts["Offline Mode"].exists)
            XCTAssertTrue(app.staticTexts["Some features may be limited"].exists)
            
            // Test sync functionality is disabled
            if let syncButton = app.buttons["sync_button"] {
                XCTAssertFalse(syncButton.isEnabled)
            }
            
            networkSwitch.tap() // Turn network back on
        }
        
        // Test memory warning handling
        // Simulate low memory condition by creating many payslips
        for _ in 1...20 {
            app.buttons["manual_button"].tap()
            
            // Fill minimum required fields
            app.textFields["name_field"].tap()
            app.textFields["name_field"].typeText("Test")
            
            app.textFields["month_field"].tap()
            app.textFields["month_field"].typeText("January")
            
            app.textFields["credits_field"].tap()
            app.textFields["credits_field"].typeText("1000")
            
            // Save
            app.buttons["save_button"].tap()
        }
        
        // Verify app still functions
        XCTAssertTrue(app.images["home_logo"].exists)
        XCTAssertTrue(app.buttons["upload_button"].isEnabled)
        
        // Test large data handling
        // Verify scrolling performance with many items
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        
        // Measure scroll performance
        measure {
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        
        // Test date edge cases
        app.buttons["manual_button"].tap()
        
        // Test future date
        app.textFields["month_field"].tap()
        app.textFields["month_field"].typeText("December")
        
        app.textFields["year_field"].tap()
        app.textFields["year_field"].typeText("2025")
        
        // Verify future date warning
        XCTAssertTrue(app.staticTexts["Future date not allowed"].exists)
        
        // Test very old date
        app.textFields["year_field"].tap()
        app.textFields["year_field"].typeText("1900")
        
        // Verify old date warning
        XCTAssertTrue(app.staticTexts["Date too old"].exists)
        
        // Dismiss manual entry
        app.navigationBars["Manual Entry"].buttons["Cancel"].tap()
    }
    
    // MARK: - Security Edge Cases
    
    func testHomeViewSecurityEdgeCases() throws {
        // Test biometric authentication timeout
        if app.buttons["secure_action_button"].exists {
            app.buttons["secure_action_button"].tap()
            
            // Wait for timeout
            Thread.sleep(forTimeInterval: 31) // Just over 30 seconds
            
            // Verify re-authentication is required
            XCTAssertTrue(app.alerts["Authentication Required"].exists)
            app.alerts["Authentication Required"].buttons["Cancel"].tap()
        }
        
        // Test multiple failed authentications
        for _ in 1...5 {
            if app.buttons["secure_action_button"].exists {
                app.buttons["secure_action_button"].tap()
                
                if app.alerts["Authentication Failed"].exists {
                    app.alerts["Authentication Failed"].buttons["Cancel"].tap()
                }
            }
        }
        
        // Verify lockout message
        XCTAssertTrue(app.staticTexts["Too many attempts. Try again later."].exists)
        
        // Test sensitive data handling
        app.buttons["manual_button"].tap()
        
        // Test PAN number masking
        let panField = app.textFields["pan_field"]
        panField.tap()
        panField.typeText("ABCDE1234F")
        
        // Verify PAN is masked
        XCTAssertTrue(panField.value as! String != "ABCDE1234F")
        
        // Test account number masking
        let accountField = app.textFields["account_field"]
        accountField.tap()
        accountField.typeText("1234567890")
        
        // Verify account number is masked
        XCTAssertTrue(accountField.value as! String != "1234567890")
        
        // Dismiss manual entry
        app.navigationBars["Manual Entry"].buttons["Cancel"].tap()
    }
} 
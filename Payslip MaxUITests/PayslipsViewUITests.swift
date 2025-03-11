import XCTest

final class PayslipsViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Navigate to Payslips tab
        app.tabBars.buttons["Payslips"].tap()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic UI Tests
    
    func testPayslipsViewBasicElements() throws {
        // Test navigation title
        XCTAssertTrue(app.navigationBars["Payslips"].exists)
        
        // Test filter button
        XCTAssertTrue(app.buttons["filter_button"].exists)
        
        // Test either list view or empty state is shown
        let hasPayslips = app.otherElements["payslips_list"].exists
        let hasEmptyState = app.otherElements["payslips_empty_state"].exists
        XCTAssertTrue(hasPayslips || hasEmptyState)
        
        // Test list items if they exist
        if hasPayslips {
            let firstPayslip = app.otherElements["payslips_list"].cells.firstMatch
            XCTAssertTrue(firstPayslip.exists)
            XCTAssertTrue(firstPayslip.staticTexts.firstMatch.exists)
        }
    }
    
    // MARK: - Filter Tests
    
    func testPayslipsViewFiltering() throws {
        // Open filter sheet
        app.buttons["filter_button"].tap()
        XCTAssertTrue(app.sheets.element.exists)
        
        // Test search functionality if available
        if app.searchFields.firstMatch.exists {
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            
            // Test searching by month
            searchField.typeText("January")
            // Wait for search results
            Thread.sleep(forTimeInterval: 1)
            
            // Clear search
            searchField.buttons["Clear text"].tap()
            
            // Test searching by year
            searchField.typeText("2024")
            // Wait for search results
            Thread.sleep(forTimeInterval: 1)
            
            // Clear search
            searchField.buttons["Clear text"].tap()
        }
        
        // Test sort options if available
        if let sortButton = app.buttons["sort_button"] {
            sortButton.tap()
            
            // Test different sort options
            for option in ["Date", "Amount", "Name"] {
                if let sortOption = app.buttons[option] {
                    sortOption.tap()
                    // Wait for sort to apply
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
    }
    
    // MARK: - Navigation Tests
    
    func testPayslipsViewNavigation() throws {
        if app.otherElements["payslips_list"].exists {
            // Get the first payslip
            let firstPayslip = app.cells.firstMatch
            XCTAssertTrue(firstPayslip.exists)
            
            // Tap to view details
            firstPayslip.tap()
            
            // Verify detail view elements
            XCTAssertTrue(app.navigationBars.element.exists)
            
            // Test share button if available
            if let shareButton = app.buttons["share_button"] {
                shareButton.tap()
                // Verify share sheet appears
                XCTAssertTrue(app.sheets.element.exists)
                // Dismiss share sheet
                app.sheets.element.buttons["Cancel"].tap()
            }
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Scroll and Load Tests
    
    func testPayslipsViewScrolling() throws {
        if app.otherElements["payslips_list"].exists {
            let list = app.otherElements["payslips_list"]
            
            // Test scrolling to bottom
            let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            start.press(forDuration: 0.1, thenDragTo: end)
            
            // Test pull to refresh
            end.press(forDuration: 0.1, thenDragTo: start)
            
            // Verify loading indicator appears
            XCTAssertTrue(app.otherElements["payslips_loading"].waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - Empty State Tests
    
    func testPayslipsViewEmptyState() throws {
        // Force empty state by applying a filter that returns no results
        app.buttons["filter_button"].tap()
        
        if let searchField = app.searchFields.firstMatch {
            searchField.tap()
            searchField.typeText("NonexistentPayslip")
            
            // Verify empty state appears
            XCTAssertTrue(app.otherElements["payslips_empty_state"].exists)
            
            // Clear filter
            searchField.buttons["Clear text"].tap()
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
    }
    
    // MARK: - Selection and Action Tests
    
    func testPayslipsViewSelectionAndActions() throws {
        if app.otherElements["payslips_list"].exists {
            // Test single selection
            let firstPayslip = app.cells.firstMatch
            firstPayslip.press(forDuration: 1.0)
            
            // Verify selection menu appears
            XCTAssertTrue(app.menuItems.firstMatch.exists)
            
            // Test available actions (share, delete, etc.)
            for action in ["Share", "Delete"] {
                if let menuItem = app.menuItems[action] {
                    menuItem.tap()
                    
                    if action == "Share" {
                        // Verify share sheet appears
                        XCTAssertTrue(app.sheets.element.exists)
                        app.sheets.element.buttons["Cancel"].tap()
                    } else if action == "Delete" {
                        // Verify delete confirmation appears
                        XCTAssertTrue(app.alerts.element.exists)
                        app.alerts.element.buttons["Cancel"].tap()
                    }
                    
                    // Return to selection mode
                    firstPayslip.press(forDuration: 1.0)
                }
            }
            
            // Dismiss selection menu
            app.tap()
        }
    }
    
    // MARK: - State Change Tests
    
    func testPayslipsViewStatePreservation() throws {
        if app.otherElements["payslips_list"].exists {
            // Apply a filter
            app.buttons["filter_button"].tap()
            if let searchField = app.searchFields.firstMatch {
                searchField.tap()
                searchField.typeText("2024")
            }
            app.sheets.element.buttons["Done"].tap()
            
            // Switch to another tab and back
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["Payslips"].tap()
            
            // Verify filter state is preserved
            app.buttons["filter_button"].tap()
            if let searchField = app.searchFields.firstMatch {
                XCTAssertEqual(searchField.value as? String, "2024")
            }
            app.sheets.element.buttons["Done"].tap()
        }
    }
    
    // MARK: - Error Scenarios Tests
    
    func testPayslipsViewErrorScenarios() throws {
        // Test data loading error
        if let reloadButton = app.buttons["reload_button"] {
            // Force error state
            app.switches["force_error"].tap()
            reloadButton.tap()
            
            // Verify error alert appears
            XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.alerts.element.staticTexts["Failed to load payslips"].exists)
            
            // Test retry functionality
            app.alerts.element.buttons["Retry"].tap()
            
            // Verify error alert appears again
            XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 2))
            
            // Dismiss error
            app.alerts.element.buttons["OK"].tap()
            
            // Reset error state
            app.switches["force_error"].tap()
        }
        
        // Test filter with invalid input
        app.buttons["filter_button"].tap()
        
        if let searchField = app.searchFields.firstMatch {
            // Test with special characters
            searchField.tap()
            searchField.typeText("!@#$%^")
            
            // Verify warning message
            XCTAssertTrue(app.staticTexts["Invalid search characters"].exists)
            
            // Clear search
            searchField.buttons["Clear text"].tap()
            
            // Test with very long input
            let longString = String(repeating: "a", count: 1000)
            searchField.typeText(longString)
            
            // Verify input is truncated
            let searchValue = searchField.value as! String
            XCTAssertLessThan(searchValue.count, 1000)
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
        
        // Test delete with network error
        if app.otherElements["payslips_list"].exists {
            // Force network error
            app.switches["force_network_error"].tap()
            
            // Try to delete payslip
            let firstPayslip = app.cells.firstMatch
            firstPayslip.press(forDuration: 1.0)
            
            if let deleteButton = app.menuItems["Delete"] {
                deleteButton.tap()
                
                // Confirm deletion
                app.alerts.element.buttons["Delete"].tap()
                
                // Verify error alert
                XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 2))
                XCTAssertTrue(app.alerts.element.staticTexts["Failed to delete payslip"].exists)
                
                // Dismiss error
                app.alerts.element.buttons["OK"].tap()
            }
            
            // Reset network error state
            app.switches["force_network_error"].tap()
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testPayslipsViewEdgeCases() throws {
        // Test rapid filter changes
        app.buttons["filter_button"].tap()
        
        if let searchField = app.searchFields.firstMatch {
            searchField.tap()
            
            // Rapidly type and clear
            for char in ["a", "b", "c", "d", "e"] {
                searchField.typeText(char)
                searchField.buttons["Clear text"].tap()
            }
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
        
        // Test rapid tab switching
        for _ in 1...5 {
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["Payslips"].tap()
        }
        
        // Test multiple selection edge cases
        if app.otherElements["payslips_list"].exists {
            // Select all items rapidly
            let cells = app.cells.allElementsBoundByIndex
            for cell in cells {
                cell.press(forDuration: 0.1)
            }
            
            // Verify selection state
            if let selectionCount = app.staticTexts["selection_count"].first {
                XCTAssertEqual(selectionCount.label, "\(cells.count) selected")
            }
            
            // Deselect all
            app.tap()
        }
        
        // Test sorting with identical values
        app.buttons["filter_button"].tap()
        
        if let sortButton = app.buttons["sort_button"] {
            sortButton.tap()
            
            // Sort by amount (assuming some payslips have same amount)
            if let amountSort = app.buttons["Amount"] {
                amountSort.tap()
                
                // Verify items with same amount maintain secondary sort order
                // This would require specific test data setup
            }
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
        
        // Test large data scroll performance
        if app.otherElements["payslips_list"].exists {
            let list = app.otherElements["payslips_list"]
            let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            
            // Measure scroll performance
            measure {
                start.press(forDuration: 0.1, thenDragTo: end)
            }
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testPayslipsViewDataConsistency() throws {
        // Test data persistence across app restart
        if app.otherElements["payslips_list"].exists {
            // Remember initial state
            let initialCount = app.cells.count
            
            // Terminate and relaunch app
            app.terminate()
            app.launch()
            
            // Navigate back to Payslips
            app.tabBars.buttons["Payslips"].tap()
            
            // Verify data is restored
            XCTAssertEqual(app.cells.count, initialCount)
        }
        
        // Test filter state preservation
        app.buttons["filter_button"].tap()
        
        if let searchField = app.searchFields.firstMatch {
            searchField.tap()
            searchField.typeText("2024")
            
            // Apply filter
            app.sheets.element.buttons["Done"].tap()
            
            // Switch tabs
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["Payslips"].tap()
            
            // Verify filter is preserved
            app.buttons["filter_button"].tap()
            XCTAssertEqual(searchField.value as? String, "2024")
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
        
        // Test sort order preservation
        app.buttons["filter_button"].tap()
        
        if let sortButton = app.buttons["sort_button"] {
            sortButton.tap()
            
            // Set sort order
            if let dateSort = app.buttons["Date"] {
                dateSort.tap()
                
                // Switch tabs
                app.tabBars.buttons["Home"].tap()
                app.tabBars.buttons["Payslips"].tap()
                
                // Verify sort order is preserved
                app.buttons["filter_button"].tap()
                sortButton.tap()
                XCTAssertTrue(dateSort.isSelected)
            }
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
    }
} 
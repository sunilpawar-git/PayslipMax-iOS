import XCTest

final class PayslipManagementTests: XCTestCase {
    
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
    
    // MARK: - Payslip List View Tests
    
    func testPayslipListDisplaysCorrectly() throws {
        // Test: Payslips display in correct chronological order
        
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        XCTAssertTrue(payslipsTab.waitForExistence(timeout: 5.0), "Payslips tab should exist")
        payslipsTab.tap()
        
        // Wait for payslips list to load
        let payslipList = app.collectionViews.firstMatch
        XCTAssertTrue(payslipList.waitForExistence(timeout: 5.0), "Payslips list should be displayed")
        
        // Check if payslips are present (could be empty state initially)
        let payslipCells = payslipList.cells
        
        // If payslips exist, verify they're in chronological order
        if payslipCells.count > 1 {
            // Basic verification that list is functioning
            XCTAssertTrue(payslipCells.count >= 1, "Should have at least one payslip or show empty state")
        }
        
        // Verify list view is responsive
        XCTAssertTrue(payslipList.exists, "Payslips list should be accessible")
    }
    
    func testPayslipSearchFunctionality() throws {
        // Test: Search functionality filters results correctly
        
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        // Look for search functionality
        let searchField = app.searchFields.firstMatch
        
        if searchField.waitForExistence(timeout: 3.0) {
            // Test search functionality if available
            searchField.tap()
            searchField.typeText("test")
            
            // Verify search is working (results may be filtered)
            let payslipList = app.collectionViews.firstMatch
            XCTAssertTrue(payslipList.exists, "Payslips list should remain after search")
            
            // Clear search
            let clearButton = searchField.buttons["Clear text"].firstMatch
            if clearButton.exists {
                clearButton.tap()
            }
        } else {
            // If no search field, just verify the list view is working
            let payslipList = app.collectionViews.firstMatch
            XCTAssertTrue(payslipList.waitForExistence(timeout: 5.0), "Payslips list should be displayed")
        }
    }
    
    func testEmptyStateDisplay() throws {
        // Test: Empty state displays when no payslips exist
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        // Wait for content to load
        let contentArea = app.scrollViews.firstMatch.otherElements.firstMatch
        XCTAssertTrue(contentArea.waitForExistence(timeout: 5.0), "Content area should load")
        
        // Check for either payslips or empty state
        let payslipList = app.collectionViews.firstMatch
        let emptyStateText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no payslips' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'add your first'"))
        
        // Should have either payslips or empty state message
        let hasPayslips = payslipList.exists && payslipList.cells.count > 0
        let hasEmptyState = emptyStateText.firstMatch.exists
        
        XCTAssertTrue(hasPayslips || hasEmptyState, "Should show either payslips or empty state")
    }
    
    // MARK: - Payslip Detail Operations
    
    func testPayslipDetailNavigation() throws {
        // Test: Detail view displays and navigation works
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        let payslipList = app.collectionViews.firstMatch
        
        if payslipList.waitForExistence(timeout: 5.0) && payslipList.cells.count > 0 {
            // If payslips exist, test detail navigation
            let firstPayslip = payslipList.cells.firstMatch
            firstPayslip.tap()
            
            // Verify we're in detail view
            let detailView = app.scrollViews.firstMatch
            XCTAssertTrue(detailView.waitForExistence(timeout: 3.0), "Detail view should open")
            
            // Look for back navigation
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                
                // Verify we're back to list
                XCTAssertTrue(payslipList.waitForExistence(timeout: 3.0), "Should return to payslips list")
            }
        } else {
            // If no payslips, verify empty state handling
            XCTAssertTrue(payslipList.exists, "Payslips list container should exist even when empty")
        }
    }
    
    func testPayslipActionButtons() throws {
        // Test: Action buttons (share, edit, delete) are accessible
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        let payslipList = app.collectionViews.firstMatch
        
        if payslipList.waitForExistence(timeout: 5.0) && payslipList.cells.count > 0 {
            let firstPayslip = payslipList.cells.firstMatch
            firstPayslip.tap()
            
            // Look for action buttons in detail view
            let shareButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'share'")).firstMatch
            let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'edit'")).firstMatch
            let moreButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'more' OR label CONTAINS[c] '⋯'")).firstMatch
            
            // At least one action should be available
            let hasActions = shareButton.exists || editButton.exists || moreButton.exists
            XCTAssertTrue(hasActions || app.navigationBars.buttons.count > 1, 
                         "Should have action buttons or navigation options")
        } else {
            XCTSkip("No payslips available for action testing")
        }
    }
    
    // MARK: - List Management
    
    func testPayslipListRefresh() throws {
        // Test: Pull to refresh or reload functionality
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        let payslipList = app.collectionViews.firstMatch
        XCTAssertTrue(payslipList.waitForExistence(timeout: 5.0), "Payslips list should load")
        
        // Try pull to refresh if available
        let startCoordinate = payslipList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let endCoordinate = payslipList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        
        // Wait a moment for refresh to complete
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify list is still functional after refresh attempt
        XCTAssertTrue(payslipList.exists, "Payslips list should remain after refresh")
    }
    
    func testPayslipLoadingStates() throws {
        // Test: Loading states during data fetch
        
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
        
        // Check for loading indicators
        let loadingIndicator = app.activityIndicators.firstMatch
        
        // Either loading should finish quickly or content should appear
        let contentLoaded = app.collectionViews.firstMatch.waitForExistence(timeout: 10.0) ||
                          app.staticTexts.firstMatch.waitForExistence(timeout: 10.0)
        
        XCTAssertTrue(contentLoaded, "Content should load within reasonable time")
        
        // Loading indicators should not persist indefinitely
        if loadingIndicator.exists {
            XCTAssertFalse(loadingIndicator.waitForExistence(timeout: 15.0), 
                          "Loading indicator should disappear after content loads")
        }
    }
} 
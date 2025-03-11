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
    
    func testPayslipsViewBasicElements() throws {
        // Test navigation title
        XCTAssertTrue(app.navigationBars["Payslips"].exists)
        
        // Test filter button
        XCTAssertTrue(app.buttons["filter_button"].exists)
        
        // Test either list view or empty state is shown
        let hasPayslips = app.otherElements["payslips_list"].exists
        let hasEmptyState = app.otherElements["payslips_empty_state"].exists
        XCTAssertTrue(hasPayslips || hasEmptyState)
    }
    
    func testPayslipsViewFiltering() throws {
        // Open filter sheet
        app.buttons["filter_button"].tap()
        
        // Verify filter sheet is shown
        XCTAssertTrue(app.sheets.element.exists)
        
        // Test search functionality if available
        if app.searchFields.firstMatch.exists {
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("January")
            
            // Verify search results update
            // Note: This might need adjustment based on test data
        }
        
        // Dismiss filter sheet
        app.sheets.element.buttons["Done"].tap()
    }
    
    func testPayslipsViewNavigation() throws {
        // Test navigation to first payslip if available
        if app.otherElements["payslips_list"].exists {
            // Tap first payslip in list
            app.cells.firstMatch.tap()
            
            // Verify navigation to detail view
            // Note: Need to add accessibility identifier for detail view
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    func testPayslipsViewRefresh() throws {
        // Test pull to refresh if implemented
        let firstCell = app.cells.firstMatch
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: finish)
        
        // Verify loading indicator appears
        XCTAssertTrue(app.otherElements["payslips_loading"].waitForExistence(timeout: 2))
    }
} 
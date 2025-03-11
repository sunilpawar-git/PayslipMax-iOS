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
    }
    
    func testHomeViewNavigation() throws {
        // Test navigation to payslips view
        app.tabBars.buttons["Payslips"].tap()
        XCTAssertTrue(app.navigationBars["Payslips"].exists)
        
        // Test navigation back to home
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.images["home_logo"].exists)
    }
    
    func testHomeViewActions() throws {
        // Test upload button action
        app.buttons["upload_button"].tap()
        // Verify document picker is shown
        XCTAssertTrue(app.sheets.element.exists)
        app.sheets.element.buttons["Cancel"].tap()
        
        // Test scan button action
        app.buttons["scan_button"].tap()
        // Verify scanner view is shown
        XCTAssertTrue(app.sheets.element.exists)
        app.sheets.element.buttons["Cancel"].tap()
        
        // Test manual button action
        app.buttons["manual_button"].tap()
        // Verify manual entry form is shown
        XCTAssertTrue(app.navigationBars["Manual Entry"].exists)
        app.navigationBars["Manual Entry"].buttons["Cancel"].tap()
    }
} 
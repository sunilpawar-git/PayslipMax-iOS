import XCTest

class PayslipsViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        XCTAssertTrue(payslipsTab.exists, "Payslips tab should exist")
        payslipsTab.tap()
    }
    
    func testPayslipsViewBasicElements() {
        // Check navigation bar
        let navBar = app.navigationBars["Payslips"]
        XCTAssertTrue(navBar.exists, "Payslips navigation bar should exist")
        
        // Check filter button
        let filterButton = app.buttons["filter_button"]
        XCTAssertTrue(filterButton.exists, "Filter button should exist")
        
        // In empty state, check for empty state elements
        let emptyStateImage = app.images["payslips_empty_state"]
        XCTAssertTrue(emptyStateImage.exists, "Empty state image should exist")
        
        let emptyStateTexts = app.staticTexts.matching(identifier: "payslips_empty_state")
        XCTAssertTrue(emptyStateTexts.count >= 2, "Empty state should have at least 2 text elements")
        
        // Verify one of the texts contains "No payslips yet"
        let noPayslipsText = emptyStateTexts.element(boundBy: 0)
        XCTAssertTrue(noPayslipsText.label.contains("No payslips yet"), "Empty state should show 'No payslips yet'")
    }
    
    func testFilterButtonInteraction() {
        let filterButton = app.buttons["filter_button"]
        if filterButton.exists {
            filterButton.tap()
            // Add assertions for filter menu if applicable
        } else {
            XCTFail("Filter button not found")
        }
    }
    
    func testPayslipsViewDebug() {
        // Check if app is running
        XCTAssertTrue(app.state == .runningForeground, "App should be running in the foreground")
        
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        XCTAssertTrue(payslipsTab.exists, "Payslips tab should exist")
        payslipsTab.tap()
        
        // Print all elements for debugging
        print("All elements in Payslips view:")
        print(app.debugDescription)
    }
    
    // Additional test cases can be added as needed
    func testTabBarNavigation() {
        // Test navigation between tabs
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        homeTab.tap()
        
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.exists, "Insights tab should exist")
        insightsTab.tap()
        
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()
        
        // Navigate back to Payslips
        let payslipsTab = app.tabBars.buttons["Payslips"]
        payslipsTab.tap()
    }
} 
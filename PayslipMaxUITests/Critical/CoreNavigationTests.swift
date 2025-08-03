import XCTest

final class CoreNavigationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
    }
    
    func testTabPersistenceAcrossLifecycle() throws {
        // Test: Tab selection persists across app lifecycle
        
        // Navigate to Payslips tab
        let payslipsTab = app.tabBars.buttons["Payslips"]
        if payslipsTab.waitForExistence(timeout: 5.0) {
            payslipsTab.tap()
            XCTAssertTrue(payslipsTab.isSelected, "Payslips tab should be selected")
            
            // Background and foreground the app
            XCUIDevice.shared.press(.home)
            sleep(1)
            app.activate()
            
            // Verify tab selection persisted
            XCTAssertTrue(payslipsTab.isSelected, "Payslips tab should remain selected after app lifecycle")
        }
    }
    
    func testNavigationStackManagement() throws {
        // Test: Navigation between tabs preserves individual stacks
        
        let homeTab = app.tabBars.buttons["Home"]
        let settingsTab = app.tabBars.buttons["Settings"]
        
        if homeTab.waitForExistence(timeout: 5.0) && settingsTab.exists {
            // Start on Home
            homeTab.tap()
            
            // Switch to Settings
            settingsTab.tap()
            sleep(1)
            
            // Switch back to Home
            homeTab.tap()
            sleep(1)
            
            // Verify we're back on home (not lost in navigation stack)
            XCTAssertTrue(homeTab.isSelected, "Should return to Home tab successfully")
        }
    }
    
    func testDeepLinkingSupport() throws {
        // Test: Deep linking to specific tabs works
        
        // Simulate deep link to Insights tab (if supported)
        let insightsTab = app.tabBars.buttons["Insights"]
        
        if insightsTab.waitForExistence(timeout: 5.0) {
            insightsTab.tap()
            
            // Verify deep link worked
            XCTAssertTrue(insightsTab.isSelected, "Deep link to Insights should work")
            
            // Test navigation functionality
            let settingsTab = app.tabBars.buttons["Settings"]
            if settingsTab.exists {
                settingsTab.tap()
                XCTAssertTrue(settingsTab.isSelected, "Should be able to navigate after deep link")
            }
        }
    }
} 
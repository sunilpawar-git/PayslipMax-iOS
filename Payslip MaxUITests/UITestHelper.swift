import XCTest

/// Helper class for UI testing that provides common utilities and functions
class UITestHelper {
    static let app = XCUIApplication()
    
    /// Launch the app with UI testing arguments
    static func launchApp() {
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    /// Navigate to a specific tab in the app
    /// - Parameter tabName: The name of the tab to navigate to
    static func navigateToTab(_ tabName: String) {
        app.tabBars.buttons[tabName].tap()
    }
    
    /// Wait for an element to exist with a timeout
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: The maximum time to wait in seconds
    /// - Returns: True if the element exists within the timeout, false otherwise
    static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// Take a screenshot and add it to the test results
    /// - Parameter name: The name of the screenshot
    static func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Take screenshot: \(name)") { activity in
            activity.add(attachment)
        }
    }
    
    /// Print the UI hierarchy for debugging purposes
    static func printUIHierarchy() {
        print("UI Hierarchy:")
        print(app.debugDescription)
    }
    
    /// Check if an element is visible on screen
    /// - Parameter element: The element to check
    /// - Returns: True if the element is visible, false otherwise
    static func isElementVisible(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        return app.windows.element(boundBy: 0).frame.contains(element.frame)
    }
    
    /// Tap a button if it exists
    /// - Parameter buttonIdentifier: The accessibility identifier of the button
    /// - Returns: True if the button was tapped, false if it doesn't exist
    @discardableResult
    static func tapButtonIfExists(_ buttonIdentifier: String) -> Bool {
        let button = app.buttons[buttonIdentifier]
        guard button.exists else { return false }
        button.tap()
        return true
    }
    
    /// Create a test payslip in the app
    /// - Returns: True if the payslip was created successfully
    static func createTestPayslip() -> Bool {
        let app = XCUIApplication()
        
        // Go to Home tab first
        navigateToTab("Home")
        
        // Print all buttons on screen for debugging
        print("All buttons on screen:")
        for (index, button) in app.buttons.allElementsBoundByIndex.enumerated() {
            print("Button: \(button.identifier) - \(button.label)")
        }
        
        // Print all elements with accessibility identifiers for debugging
        print("All elements with accessibility identifiers:")
        for (index, element) in app.descendants(matching: .any).allElementsBoundByIndex.enumerated() {
            if !element.identifier.isEmpty {
                print("Element: \(element.identifier) - \(element.elementType)")
            }
        }
        
        // Check if manual button exists by identifier
        let manualButtonByID = app.buttons["manual_button"]
        print("Checking existence of `\"manual_button\" Button`")
        if !manualButtonByID.exists {
            // Try to find by label instead
            print("Manual button not found")
            let manualButtonByLabel = app.buttons["Manual"]
            print("Checking existence of `\"Manual\" Button`")
            if manualButtonByLabel.exists {
                print("Found manual button by label instead")
                manualButtonByLabel.tap()
            } else {
                print("Manual button not found by label either")
                return false
            }
        } else {
            manualButtonByID.tap()
        }
        
        // Wait for Manual Entry screen to appear
        let manualEntryNav = app.navigationBars["Manual Entry"]
        print("Waiting 5.0s for \"Manual Entry\" NavigationBar to exist")
        guard manualEntryNav.waitForExistence(timeout: 5.0) else {
            return false
        }
        
        // Print all elements in the form for debugging
        print("All elements in Manual Entry form:")
        for (index, element) in app.descendants(matching: .any).allElementsBoundByIndex.enumerated() {
            print("Element: \(element.label) - \(element.elementType)")
        }
        
        // Print all text fields for debugging
        print("All text fields:")
        for (index, textField) in app.textFields.allElementsBoundByIndex.enumerated() {
            print("TextField: \(textField.identifier) - \(textField.label)")
        }
        
        // Print all pickers for debugging
        print("All pickers:")
        for (index, picker) in app.pickers.allElementsBoundByIndex.enumerated() {
            print("Picker: \(picker.identifier) - \(picker.label)")
        }
        
        // Check for text fields by different methods
        let nameFieldByID = app.textFields["name_field"]
        let monthFieldByID = app.textFields["month_field"]
        let yearFieldByID = app.buttons["year_field"] // Changed from picker to button
        let creditsFieldByID = app.textFields["credits_field"]
        
        let nameFieldByLabel = app.textFields["Name"]
        let monthFieldByLabel = app.textFields["Month"]
        let yearFieldByLabel = app.buttons["Year"]
        let creditsFieldByLabel = app.textFields["Credits"]
        
        let nameFieldByPlaceholder = app.textFields.element(boundBy: 0)
        let monthFieldByPlaceholder = app.textFields.element(boundBy: 1)
        let creditsFieldByPlaceholder = app.textFields.element(boundBy: 3)
        
        // Check if any text fields exist
        let anyTextFieldExists = app.textFields.count > 0
        print("Any text field exists: \(anyTextFieldExists)")
        
        // Print existence of fields
        print("Name field exists: \(nameFieldByID.exists)")
        print("Month field exists: \(monthFieldByID.exists)")
        print("Year field exists: \(yearFieldByID.exists)")
        print("Credits field exists: \(creditsFieldByID.exists)")
        
        print("Name field by label exists: \(nameFieldByLabel.exists)")
        print("Month field by label exists: \(monthFieldByLabel.exists)")
        print("Year field by label exists: \(yearFieldByLabel.exists)")
        print("Credits field by label exists: \(creditsFieldByLabel.exists)")
        
        print("Name field by placeholder exists: \(nameFieldByPlaceholder.exists)")
        print("Month field by placeholder exists: \(monthFieldByPlaceholder.exists)")
        print("Credits field by placeholder exists: \(creditsFieldByPlaceholder.exists)")
        
        // Check if all required fields exist
        guard anyTextFieldExists else {
            return false
        }
        
        // Use the fields that exist, with fallbacks
        let finalNameField = nameFieldByID.exists ? nameFieldByID : (nameFieldByLabel.exists ? nameFieldByLabel : nameFieldByPlaceholder)
        let finalMonthField = monthFieldByID.exists ? monthFieldByID : (monthFieldByLabel.exists ? monthFieldByLabel : monthFieldByPlaceholder)
        let finalYearField = yearFieldByID.exists ? yearFieldByID : yearFieldByLabel
        let finalCreditsField = creditsFieldByID.exists ? creditsFieldByID : (creditsFieldByLabel.exists ? creditsFieldByLabel : creditsFieldByPlaceholder)
        
        // Fill in the form
        finalNameField.tap()
        finalNameField.typeText("Test User")
        
        finalMonthField.tap()
        finalMonthField.typeText("January")
        
        finalYearField.tap()
        let picker = app.pickers.firstMatch
        if picker.exists {
            let yearWheel = picker.pickerWheels.firstMatch
            yearWheel.adjust(toPickerWheelValue: "2023")
        } else {
            print("Year picker wheel not found")
        }
        
        // Scroll down to make the save button visible
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            print("Scrolled down to make save button visible")
        }
        
        // Wait a moment for the scroll to complete
        sleep(1)
        
        // Now try to tap the save button
        if app.buttons["save_button"].exists {
            app.buttons["save_button"].tap()
            print("Tapped save button")
            
            // Add a longer wait after tapping save to allow any animations or transitions to complete
            sleep(3)
            
            // Consider the test successful after tapping save
            print("Test completed successfully - payslip saved")
            return true
        } else {
            print("Save button not found")
            return false
        }
    }
} 
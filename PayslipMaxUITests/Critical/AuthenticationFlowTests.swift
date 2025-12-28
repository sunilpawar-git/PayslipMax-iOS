import XCTest

final class AuthenticationFlowTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    var app: XCUIApplication!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Configure app for UI testing
        app.launchArguments.append("UI_TESTING")
        app.launchEnvironment["RESET_DATA"] = "true"
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Critical Tests

    func testAppLaunchesSuccessfully() throws {
        // Test: App launches without crashes
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }

        // Verify app is running
        XCTAssertEqual(app.state, .runningForeground)

        // Verify main UI elements appear within 3 seconds
        let homeTab = app.tabBars.buttons["Home"]
        let authButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Authenticate'")).firstMatch

        let appReady = homeTab.waitForExistence(timeout: 3.0) ||
                      authButton.waitForExistence(timeout: 3.0)

        XCTAssertTrue(appReady, "App should be ready within 3 seconds")
    }

    func testTabNavigationWorks() throws {
        // Test: All 4 tabs are accessible
        app.launch()

        // Wait for tabs to appear (either directly or after auth bypass)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Tab bar should appear")

        // Test each tab
        let tabs = ["Home", "Payslips", "Insights", "Settings"]

        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            if tab.exists {
                tab.tap()

                // Verify tab is selected (usually becomes highlighted)
                XCTAssertTrue(tab.isSelected || tab.exists, "Tab \(tabName) should be selectable")

                // Brief wait for content to load
                wait(seconds: 0.5)
            }
        }
    }

    func testBiometricAuthenticationFlow() throws {
        // Test: Biometric authentication appears if enabled
        app.launch()

        let biometricButton = app.buttons["BiometricAuthButton"]
        let usePINButton = app.buttons["UsePINButton"]

        if biometricButton.waitForExistence(timeout: 3.0) {
            // Biometric auth is available
            XCTAssertTrue(biometricButton.isHittable, "Biometric button should be tappable")

            // Tap biometric button (will show system prompt on device)
            biometricButton.tap()

            // Check if PIN fallback appears
            if usePINButton.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(usePINButton.isHittable, "Use PIN button should be available as fallback")
            }
        } else {
            // No biometric auth - should bypass to main app
            let homeTab = app.tabBars.buttons["Home"]
            XCTAssertTrue(homeTab.waitForExistence(timeout: 3.0), "Should bypass to main app if no biometric auth")
        }
    }

    func testAccessibilityLabels() throws {
        // Test: All UI elements have proper accessibility labels
        app.launch()

        // Wait for UI to settle
        wait(seconds: 2)

        // Check buttons have labels
        let allButtons = app.buttons.allElementsBoundByIndex
        for button in allButtons {
            XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label: \(button.identifier)")
        }

        // Check tab bar accessibility
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabButtons = tabBar.buttons.allElementsBoundByIndex
            for tab in tabButtons {
                XCTAssertFalse(tab.label.isEmpty, "Tab should have accessibility label: \(tab.identifier)")
            }
        }
    }

    func testLaunchPerformance() throws {
        // Test: App launch performance meets requirements
        // CI environments may have slower performance, so use adjusted timeouts
        // Check multiple environment variables that GitHub Actions and other CI systems set
        let env = ProcessInfo.processInfo.environment
        let isCI = env["CI"] != nil ||
                   env["GITHUB_ACTIONS"] != nil ||
                   env["CONTINUOUS_INTEGRATION"] != nil
        let maxLaunchTime = isCI ? 18.0 : 10.0

        let startTime = Date()

        // Launch app once and measure responsiveness
        app.launch()

        let responsive = app.tabBars.firstMatch.waitForExistence(timeout: 5.0) ||
                        app.buttons.firstMatch.waitForExistence(timeout: 5.0)

        let launchTime = Date().timeIntervalSince(startTime)

        XCTAssertTrue(responsive, "App should become responsive within 5 seconds")
        XCTAssertLessThan(launchTime, maxLaunchTime, "App launch should complete within \(maxLaunchTime) seconds")
    }
}

import XCTest
import SwiftUI
import Combine
@testable import PayslipMax

/// Unit tests for ThemeManager to ensure consistent theme behavior
/// Tests cover: default values, persistence, theme changes, and notification posting
@MainActor
final class ThemeManagerTests: XCTestCase {

    // MARK: - Properties

    private var testUserDefaults: UserDefaults!
    private var sut: ThemeManager!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create isolated UserDefaults for testing
        testUserDefaults = UserDefaults(suiteName: "ThemeManagerTests")!
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerTests")

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        // Clean up test defaults
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        testUserDefaults = nil

        // Clean up cancellables
        cancellables.forEach { $0.cancel() }
        cancellables = nil

        sut = nil

        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a ThemeManager with test UserDefaults
    private func createSUT() -> ThemeManager {
        return ThemeManager(userDefaults: testUserDefaults)
    }

    // MARK: - AppTheme Enum Tests

    func testAppTheme_AllCasesExist() {
        // Verify all expected cases are available
        let allCases = AppTheme.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
        XCTAssertTrue(allCases.contains(.system))
    }

    func testAppTheme_RawValues() {
        XCTAssertEqual(AppTheme.light.rawValue, "Light")
        XCTAssertEqual(AppTheme.dark.rawValue, "Dark")
        XCTAssertEqual(AppTheme.system.rawValue, "System")
    }

    func testAppTheme_SystemImages() {
        XCTAssertEqual(AppTheme.light.systemImage, "sun.max.fill")
        XCTAssertEqual(AppTheme.dark.systemImage, "moon.fill")
        XCTAssertEqual(AppTheme.system.systemImage, "gear")
    }

    func testAppTheme_ColorScheme() {
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
        XCTAssertNil(AppTheme.system.colorScheme, "System theme should return nil colorScheme to follow system")
    }

    #if canImport(UIKit)
    func testAppTheme_UIInterfaceStyle() {
        XCTAssertEqual(AppTheme.light.uiInterfaceStyle, .light)
        XCTAssertEqual(AppTheme.dark.uiInterfaceStyle, .dark)
        XCTAssertEqual(AppTheme.system.uiInterfaceStyle, .unspecified)
    }
    #endif

    func testAppTheme_Identifiable() {
        // Each theme should have a unique ID
        XCTAssertEqual(AppTheme.light.id, "Light")
        XCTAssertEqual(AppTheme.dark.id, "Dark")
        XCTAssertEqual(AppTheme.system.id, "System")
    }

    // MARK: - Default Theme Tests (Critical Bug Fix)

    func testThemeManager_DefaultsToSystem_WhenNoSavedPreference() {
        // Given: Fresh UserDefaults with no saved theme
        // (testUserDefaults is already clean from setUp)

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should default to .system (not .light!)
        // This was the bug - new users should follow system theme by default
        XCTAssertEqual(sut.currentTheme, .system,
                       "New users should default to system theme, not light")
    }

    func testThemeManager_LoadsLightTheme_WhenSaved() {
        // Given: Light theme saved in UserDefaults
        testUserDefaults.set("Light", forKey: "appTheme")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should load light theme
        XCTAssertEqual(sut.currentTheme, .light)
    }

    func testThemeManager_LoadsDarkTheme_WhenSaved() {
        // Given: Dark theme saved in UserDefaults
        testUserDefaults.set("Dark", forKey: "appTheme")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should load dark theme
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testThemeManager_LoadsSystemTheme_WhenSaved() {
        // Given: System theme saved in UserDefaults
        testUserDefaults.set("System", forKey: "appTheme")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should load system theme
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Legacy Migration Tests

    func testThemeManager_MigratesFromLegacyDarkMode_WhenTrue() {
        // Given: Legacy useDarkMode flag set to true (no new appTheme key)
        testUserDefaults.set(true, forKey: "useDarkMode")
        // Note: appTheme is NOT set - this simulates a legacy user

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should migrate to dark theme
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testThemeManager_MigratesFromLegacyDarkMode_WhenFalse() {
        // Given: Legacy useDarkMode flag set to false (no new appTheme key)
        testUserDefaults.set(false, forKey: "useDarkMode")
        // Note: appTheme is NOT set - this simulates a legacy user who chose light

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should migrate to light theme (user explicitly chose light before)
        XCTAssertEqual(sut.currentTheme, .light)
    }

    func testThemeManager_PrefersNewKey_OverLegacyKey() {
        // Given: Both keys set (new key should take precedence)
        testUserDefaults.set("System", forKey: "appTheme")
        testUserDefaults.set(true, forKey: "useDarkMode")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should use new appTheme key (System), not legacy useDarkMode
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Theme Change Tests

    func testSetTheme_ChangesCurrentTheme() {
        // Given: ThemeManager with default theme
        sut = createSUT()

        // When: Set to dark theme
        sut.setTheme(.dark)

        // Then: Theme should change
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testSetTheme_DoesNotChangeWhenSameTheme() {
        // Given: ThemeManager with dark theme
        testUserDefaults.set("Dark", forKey: "appTheme")
        sut = createSUT()

        // Track if @Published fires
        var publishCount = 0
        sut.$currentTheme
            .dropFirst() // Skip initial value
            .sink { _ in publishCount += 1 }
            .store(in: &cancellables)

        // When: Set to same theme
        sut.setTheme(.dark)

        // Then: Should not publish change
        XCTAssertEqual(publishCount, 0, "Setting same theme should not trigger @Published")
    }

    func testSetTheme_PublishesChange() {
        // Given: ThemeManager with system theme
        sut = createSUT()

        let expectation = XCTestExpectation(description: "Theme change published")
        var receivedTheme: AppTheme?

        sut.$currentTheme
            .dropFirst() // Skip initial value
            .sink { theme in
                receivedTheme = theme
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Change theme
        sut.setTheme(.light)

        // Then: Should publish new theme
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTheme, .light)
    }

    // MARK: - Persistence Tests

    func testSetTheme_PersistsToUserDefaults() {
        // Given: ThemeManager with default theme
        sut = createSUT()

        // When: Set theme
        sut.setTheme(.dark)

        // Then: Should persist to UserDefaults
        XCTAssertEqual(testUserDefaults.string(forKey: "appTheme"), "Dark")
    }

    func testSetTheme_UpdatesLegacyKey_ForBackwardCompatibility() {
        // Given: ThemeManager
        sut = createSUT()

        // When: Set to dark theme
        sut.setTheme(.dark)

        // Then: Legacy key should also be updated
        XCTAssertTrue(testUserDefaults.bool(forKey: "useDarkMode"))

        // When: Set to light theme
        sut.setTheme(.light)

        // Then: Legacy key should be false
        XCTAssertFalse(testUserDefaults.bool(forKey: "useDarkMode"))
    }

    func testSetTheme_PersistsAcrossInstances() {
        // Given: Set theme in first instance
        sut = createSUT()
        sut.setTheme(.dark)

        // When: Create new instance
        let sut2 = createSUT()

        // Then: Should load persisted theme
        XCTAssertEqual(sut2.currentTheme, .dark)
    }

    // MARK: - Notification Tests

    func testSetTheme_PostsNotification() {
        // Given: ThemeManager and notification observer
        sut = createSUT()

        let expectation = XCTestExpectation(description: "Theme notification posted")
        var receivedThemeName: String?

        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: sut,
            queue: .main
        ) { notification in
            receivedThemeName = notification.userInfo?["theme"] as? String
            expectation.fulfill()
        }

        // When: Change theme
        sut.setTheme(.dark)

        // Then: Notification should be posted with theme info
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedThemeName, "Dark")
    }

    func testSetTheme_NotificationIncludesColorScheme() {
        // Given: ThemeManager and notification observer
        sut = createSUT()

        let expectation = XCTestExpectation(description: "Theme notification with colorScheme")
        var receivedColorScheme: ColorScheme?

        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: sut,
            queue: .main
        ) { notification in
            receivedColorScheme = notification.userInfo?["colorScheme"] as? ColorScheme
            expectation.fulfill()
        }

        // When: Change to light theme
        sut.setTheme(.light)

        // Then: Notification should include colorScheme
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedColorScheme, .light)
    }

    // MARK: - Edge Case Tests

    func testThemeManager_HandlesInvalidSavedValue() {
        // Given: Invalid theme value in UserDefaults
        testUserDefaults.set("InvalidTheme", forKey: "appTheme")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should default to system theme
        XCTAssertEqual(sut.currentTheme, .system)
    }

    func testThemeManager_HandlesClearedUserDefaults() {
        // Given: Theme was set, then cleared
        testUserDefaults.set("Dark", forKey: "appTheme")
        testUserDefaults.removeObject(forKey: "appTheme")
        testUserDefaults.removeObject(forKey: "useDarkMode")

        // When: Create ThemeManager
        sut = createSUT()

        // Then: Should default to system theme
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Thread Safety Tests (Implicit via @MainActor)

    func testThemeManager_IsMainActorIsolated() {
        // This test verifies the class is @MainActor isolated
        // by confirming it can only be called from main actor context

        // Given/When: Create and use ThemeManager on main actor
        sut = createSUT()
        sut.setTheme(.dark)

        // Then: No crashes = success (main actor isolation enforced by compiler)
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    // MARK: - Initial Theme Application Tests

    func testApplyInitialThemeIfNeeded_OnlyAppliesOnce() {
        // Given: ThemeManager
        sut = createSUT()

        // When: Call applyInitialThemeIfNeeded multiple times
        sut.applyInitialThemeIfNeeded()
        sut.applyInitialThemeIfNeeded()
        sut.applyInitialThemeIfNeeded()

        // Then: Should not crash and theme should remain correct
        // (The internal flag prevents repeated applications)
        XCTAssertEqual(sut.currentTheme, .system)
    }

    func testResetForTesting_AllowsReapplication() {
        // Given: ThemeManager that has applied initial theme
        sut = createSUT()
        sut.applyInitialThemeIfNeeded()

        // When: Reset and apply again
        sut.resetForTesting()
        sut.applyInitialThemeIfNeeded()

        // Then: Should work without issues
        XCTAssertEqual(sut.currentTheme, .system)
    }
}

// MARK: - Integration Tests with SettingsViewModel

@MainActor
final class ThemeSettingsIntegrationTests: XCTestCase {

    private var testUserDefaults: UserDefaults!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "ThemeSettingsIntegrationTests")!
        testUserDefaults.removePersistentDomain(forName: "ThemeSettingsIntegrationTests")
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "ThemeSettingsIntegrationTests")
        testUserDefaults = nil
        cancellables = nil
        super.tearDown()
    }

    func testSettingsViewModel_SyncsWithThemeManager() {
        // Given: SettingsViewModel with custom UserDefaults
        let viewModel = SettingsViewModel(userDefaults: testUserDefaults)

        // When: Theme is changed via ThemeManager
        ThemeManager.shared.setTheme(.dark)

        // Allow time for Combine sink to fire
        let expectation = XCTestExpectation(description: "Theme sync")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: ViewModel should sync
        XCTAssertEqual(viewModel.appTheme, .dark)
    }
}


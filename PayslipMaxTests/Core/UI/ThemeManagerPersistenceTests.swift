import XCTest
import SwiftUI
import Combine
@testable import PayslipMax

/// Tests for ThemeManager persistence and notification behavior
@MainActor
final class ThemeManagerPersistenceTests: XCTestCase {

    private var testUserDefaults: UserDefaults!
    private var sut: ThemeManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "ThemeManagerPersistenceTests")!
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerPersistenceTests")
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerPersistenceTests")
        testUserDefaults = nil
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    private func createSUT() -> ThemeManager {
        return ThemeManager(userDefaults: testUserDefaults)
    }

    // MARK: - Persistence Tests

    func testSetTheme_PersistsToUserDefaults() {
        sut = createSUT()
        sut.setTheme(.dark)
        XCTAssertEqual(testUserDefaults.string(forKey: "appTheme"), "Dark")
    }

    func testSetTheme_UpdatesLegacyKey_ForBackwardCompatibility() {
        sut = createSUT()

        sut.setTheme(.dark)
        XCTAssertTrue(testUserDefaults.bool(forKey: "useDarkMode"))

        sut.setTheme(.light)
        XCTAssertFalse(testUserDefaults.bool(forKey: "useDarkMode"))
    }

    func testSetTheme_PersistsAcrossInstances() {
        sut = createSUT()
        sut.setTheme(.dark)

        let sut2 = createSUT()
        XCTAssertEqual(sut2.currentTheme, .dark)
    }

    // MARK: - Notification Tests

    func testSetTheme_PostsNotification() {
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

        sut.setTheme(.dark)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedThemeName, "Dark")
    }

    func testSetTheme_NotificationIncludesColorScheme() {
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

        sut.setTheme(.light)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedColorScheme, .light)
    }

    // MARK: - Edge Case Tests

    func testThemeManager_HandlesInvalidSavedValue() {
        testUserDefaults.set("InvalidTheme", forKey: "appTheme")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    func testThemeManager_HandlesClearedUserDefaults() {
        testUserDefaults.set("Dark", forKey: "appTheme")
        testUserDefaults.removeObject(forKey: "appTheme")
        testUserDefaults.removeObject(forKey: "useDarkMode")

        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Thread Safety Tests

    func testThemeManager_IsMainActorIsolated() {
        sut = createSUT()
        sut.setTheme(.dark)
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    // MARK: - Initial Theme Application Tests

    func testApplyInitialThemeIfNeeded_OnlyAppliesOnce() {
        sut = createSUT()
        sut.applyInitialThemeIfNeeded()
        sut.applyInitialThemeIfNeeded()
        sut.applyInitialThemeIfNeeded()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    func testResetForTesting_AllowsReapplication() {
        sut = createSUT()
        sut.applyInitialThemeIfNeeded()
        sut.resetForTesting()
        sut.applyInitialThemeIfNeeded()
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
        let viewModel = SettingsViewModel(userDefaults: testUserDefaults)
        ThemeManager.shared.setTheme(.dark)

        let expectation = XCTestExpectation(description: "Theme sync")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.appTheme, .dark)
    }
}


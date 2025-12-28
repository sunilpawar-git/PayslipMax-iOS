import XCTest
import SwiftUI
import Combine
@testable import PayslipMax

/// Unit tests for ThemeManager to ensure consistent theme behavior
/// Tests cover: default values, persistence, theme changes, and notification posting
@MainActor
final class ThemeManagerTests: XCTestCase {

    private var testUserDefaults: UserDefaults!
    private var sut: ThemeManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "ThemeManagerTests")!
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        testUserDefaults = nil
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    private func createSUT() -> ThemeManager {
        return ThemeManager(userDefaults: testUserDefaults)
    }

    // MARK: - AppTheme Enum Tests

    func testAppTheme_AllCasesExist() {
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
        XCTAssertNil(AppTheme.system.colorScheme)
    }

    #if canImport(UIKit)
    func testAppTheme_UIInterfaceStyle() {
        XCTAssertEqual(AppTheme.light.uiInterfaceStyle, .light)
        XCTAssertEqual(AppTheme.dark.uiInterfaceStyle, .dark)
        XCTAssertEqual(AppTheme.system.uiInterfaceStyle, .unspecified)
    }
    #endif

    func testAppTheme_Identifiable() {
        XCTAssertEqual(AppTheme.light.id, "Light")
        XCTAssertEqual(AppTheme.dark.id, "Dark")
        XCTAssertEqual(AppTheme.system.id, "System")
    }

    // MARK: - Default Theme Tests

    func testThemeManager_DefaultsToSystem_WhenNoSavedPreference() {
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    func testThemeManager_LoadsLightTheme_WhenSaved() {
        testUserDefaults.set("Light", forKey: "appTheme")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .light)
    }

    func testThemeManager_LoadsDarkTheme_WhenSaved() {
        testUserDefaults.set("Dark", forKey: "appTheme")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testThemeManager_LoadsSystemTheme_WhenSaved() {
        testUserDefaults.set("System", forKey: "appTheme")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Legacy Migration Tests

    func testThemeManager_MigratesFromLegacyDarkMode_WhenTrue() {
        testUserDefaults.set(true, forKey: "useDarkMode")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testThemeManager_MigratesFromLegacyDarkMode_WhenFalse() {
        testUserDefaults.set(false, forKey: "useDarkMode")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .light)
    }

    func testThemeManager_PrefersNewKey_OverLegacyKey() {
        testUserDefaults.set("System", forKey: "appTheme")
        testUserDefaults.set(true, forKey: "useDarkMode")
        sut = createSUT()
        XCTAssertEqual(sut.currentTheme, .system)
    }

    // MARK: - Theme Change Tests

    func testSetTheme_ChangesCurrentTheme() {
        sut = createSUT()
        sut.setTheme(.dark)
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testSetTheme_DoesNotChangeWhenSameTheme() {
        testUserDefaults.set("Dark", forKey: "appTheme")
        sut = createSUT()

        var publishCount = 0
        sut.$currentTheme
            .dropFirst()
            .sink { _ in publishCount += 1 }
            .store(in: &cancellables)

        sut.setTheme(.dark)
        XCTAssertEqual(publishCount, 0)
    }

    func testSetTheme_PublishesChange() {
        sut = createSUT()

        let expectation = XCTestExpectation(description: "Theme change published")
        var receivedTheme: AppTheme?

        sut.$currentTheme
            .dropFirst()
            .sink { theme in
                receivedTheme = theme
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.setTheme(.light)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTheme, .light)
    }
}

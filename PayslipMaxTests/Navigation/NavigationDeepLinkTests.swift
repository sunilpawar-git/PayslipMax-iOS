import XCTest
@testable import PayslipMax

/// Tests for NavigationCoordinator deep link handling
@MainActor
final class NavigationDeepLinkTests: XCTestCase {

    private var sut: NavigationCoordinator!

    override func setUp() {
        super.setUp()
        sut = NavigationCoordinator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Deep Link Tests

    func test_handleDeepLink_HomeScheme_SwitchesToHomeTab() {
        sut.switchTab(to: 2)
        let url = URL(string: "payslipmax://home")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 0)
    }

    func test_handleDeepLink_PayslipsScheme_SwitchesToPayslipsTab() {
        let url = URL(string: "payslipmax://payslips")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
    }

    func test_handleDeepLink_InsightsScheme_SwitchesToInsightsTab() {
        let url = URL(string: "payslipmax://insights")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 2)
    }

    func test_handleDeepLink_SettingsScheme_SwitchesToSettingsTab() {
        let url = URL(string: "payslipmax://settings")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 3)
    }

    func test_handleDeepLink_PayslipWithId_NavigatesToDetail() {
        let payslipId = UUID()
        let url = URL(string: "payslipmax://payslip?id=\(payslipId.uuidString)")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_handleDeepLink_PayslipWithInvalidId_ReturnsFalse() {
        let url = URL(string: "payslipmax://payslip?id=invalid-uuid")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_PrivacyScheme_PresentsSheet() {
        let url = URL(string: "payslipmax://privacy")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertNotNil(sut.sheet)
        if case .privacyPolicy = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .privacyPolicy sheet")
        }
    }

    func test_handleDeepLink_TermsScheme_PresentsSheet() {
        let url = URL(string: "payslipmax://terms")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertNotNil(sut.sheet)
        if case .termsOfService = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .termsOfService sheet")
        }
    }

    func test_handleDeepLink_WebUploadsScheme_NavigatesToWebUploads() {
        let url = URL(string: "payslipmax://web-uploads")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 3)
        XCTAssertFalse(sut.settingsStack.isEmpty)
    }

    func test_handleDeepLink_UnknownScheme_ReturnsFalse() {
        let url = URL(string: "payslipmax://unknown-path")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_WrongScheme_ReturnsFalse() {
        let url = URL(string: "https://example.com")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_UploadScheme_SwitchesToPayslipsTab() {
        let url = URL(string: "payslipmax://upload")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
    }
}


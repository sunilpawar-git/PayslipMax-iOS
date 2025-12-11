import XCTest
@testable import PayslipMax

/// Tests for NavigationCoordinator functionality including tab switching, deep links, and sheet presentation
@MainActor
final class NavigationCoordinatorTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: NavigationCoordinator!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = NavigationCoordinator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tab Switching Tests

    func test_switchTab_ChangesSelectedTab() {
        // Given
        XCTAssertEqual(sut.selectedTab, 0)

        // When
        sut.switchTab(to: 2)

        // Then
        XCTAssertEqual(sut.selectedTab, 2)
    }

    func test_switchTab_WithInvalidIndex_DoesNothing() {
        // Given
        sut.switchTab(to: 1)
        XCTAssertEqual(sut.selectedTab, 1)

        // When
        sut.switchTab(to: -1)
        sut.switchTab(to: 5)

        // Then
        XCTAssertEqual(sut.selectedTab, 1, "Invalid indexes should not change tab")
    }

    func test_switchTab_WithDestination_NavigatesToDestination() {
        // Given
        let destination = AppNavigationDestination.webUploads

        // When
        sut.switchTab(to: 3, destination: destination)

        // Then
        XCTAssertEqual(sut.selectedTab, 3)
        XCTAssertFalse(sut.settingsStack.isEmpty)
    }

    // MARK: - Navigation Stack Tests

    func test_navigate_AddsToCurrentStack() {
        // Given
        sut.switchTab(to: 1) // Payslips tab
        XCTAssertTrue(sut.payslipsStack.isEmpty)

        // When
        sut.navigate(to: .payslipDetail(id: UUID()))

        // Then
        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_navigateBack_RemovesFromStack() {
        // Given
        sut.navigate(to: .webUploads)
        XCTAssertFalse(sut.homeStack.isEmpty)

        // When
        sut.navigateBack()

        // Then
        XCTAssertTrue(sut.homeStack.isEmpty)
    }

    func test_navigateBack_WhenStackEmpty_DoesNothing() {
        // Given
        XCTAssertTrue(sut.homeStack.isEmpty)

        // When
        sut.navigateBack()

        // Then
        XCTAssertTrue(sut.homeStack.isEmpty) // No crash, no change
    }

    func test_navigateToRoot_ClearsEntireStack() {
        // Given
        sut.navigate(to: .webUploads)
        sut.navigate(to: .webUploads)
        sut.navigate(to: .webUploads)

        // When
        sut.navigateToRoot()

        // Then
        XCTAssertTrue(sut.homeStack.isEmpty)
    }

    // MARK: - Sheet Presentation Tests

    func test_presentSheet_SetsSheetProperty() {
        // Given
        XCTAssertNil(sut.sheet)

        // When
        sut.presentSheet(.addPayslip)

        // Then
        XCTAssertNotNil(sut.sheet)
        if case .addPayslip = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .addPayslip sheet")
        }
    }

    func test_dismissSheet_ClearsSheetProperty() {
        // Given
        sut.presentSheet(.addPayslip)
        XCTAssertNotNil(sut.sheet)

        // When
        sut.dismissSheet()

        // Then
        XCTAssertNil(sut.sheet)
    }

    // MARK: - Full Screen Cover Tests

    func test_presentFullScreen_SetsFullScreenProperty() {
        // Given
        XCTAssertNil(sut.fullScreenCover)

        // When
        sut.presentFullScreen(.scanner)

        // Then
        XCTAssertNotNil(sut.fullScreenCover)
        if case .scanner = sut.fullScreenCover {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .scanner full screen cover")
        }
    }

    func test_dismissFullScreen_ClearsFullScreenProperty() {
        // Given
        sut.presentFullScreen(.scanner)
        XCTAssertNotNil(sut.fullScreenCover)

        // When
        sut.dismissFullScreen()

        // Then
        XCTAssertNil(sut.fullScreenCover)
    }

    // MARK: - Convenience Method Tests

    func test_showPayslipDetail_NavigatesToDetailView() {
        // Given
        sut.switchTab(to: 1) // Payslips tab
        let payslipId = UUID()

        // When
        sut.showPayslipDetail(id: payslipId)

        // Then
        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_showAddPayslip_PresentsSheet() {
        // Given
        XCTAssertNil(sut.sheet)

        // When
        sut.showAddPayslip()

        // Then
        XCTAssertNotNil(sut.sheet)
        if case .addPayslip = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .addPayslip sheet")
        }
    }

    func test_showScanner_PresentsFullScreen() {
        // Given
        XCTAssertNil(sut.fullScreenCover)

        // When
        sut.showScanner()

        // Then
        XCTAssertNotNil(sut.fullScreenCover)
        if case .scanner = sut.fullScreenCover {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .scanner full screen cover")
        }
    }

    func test_showPinSetup_PresentsSheet() {
        // Given
        XCTAssertNil(sut.sheet)

        // When
        sut.showPinSetup()

        // Then
        XCTAssertNotNil(sut.sheet)
        if case .pinSetup = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .pinSetup sheet")
        }
    }

    // MARK: - Deep Link Tests

    func test_handleDeepLink_HomeScheme_SwitchesToHomeTab() {
        // Given
        sut.switchTab(to: 2)
        let url = URL(string: "payslipmax://home")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 0)
    }

    func test_handleDeepLink_PayslipsScheme_SwitchesToPayslipsTab() {
        // Given
        let url = URL(string: "payslipmax://payslips")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
    }

    func test_handleDeepLink_InsightsScheme_SwitchesToInsightsTab() {
        // Given
        let url = URL(string: "payslipmax://insights")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 2)
    }

    func test_handleDeepLink_SettingsScheme_SwitchesToSettingsTab() {
        // Given
        let url = URL(string: "payslipmax://settings")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 3)
    }

    func test_handleDeepLink_PayslipWithId_NavigatesToDetail() {
        // Given
        let payslipId = UUID()
        let url = URL(string: "payslipmax://payslip?id=\(payslipId.uuidString)")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_handleDeepLink_PayslipWithInvalidId_ReturnsFalse() {
        // Given
        let url = URL(string: "payslipmax://payslip?id=invalid-uuid")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_PrivacyScheme_PresentsSheet() {
        // Given
        let url = URL(string: "payslipmax://privacy")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertNotNil(sut.sheet)
        if case .privacyPolicy = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .privacyPolicy sheet")
        }
    }

    func test_handleDeepLink_TermsScheme_PresentsSheet() {
        // Given
        let url = URL(string: "payslipmax://terms")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertNotNil(sut.sheet)
        if case .termsOfService = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .termsOfService sheet")
        }
    }

    func test_handleDeepLink_WebUploadsScheme_NavigatesToWebUploads() {
        // Given
        let url = URL(string: "payslipmax://web-uploads")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 3)
        XCTAssertFalse(sut.settingsStack.isEmpty)
    }

    func test_handleDeepLink_UnknownScheme_ReturnsFalse() {
        // Given
        let url = URL(string: "payslipmax://unknown-path")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_WrongScheme_ReturnsFalse() {
        // Given
        let url = URL(string: "https://example.com")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertFalse(handled)
    }

    func test_handleDeepLink_UploadScheme_SwitchesToPayslipsTab() {
        // Given
        let url = URL(string: "payslipmax://upload")!

        // When
        let handled = sut.handleDeepLink(url)

        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(sut.selectedTab, 1)
    }

    // MARK: - Tab Isolation Tests

    func test_tabStacks_AreIsolated() {
        // Given - Navigate in different tabs
        sut.switchTab(to: 0)
        sut.navigate(to: .webUploads)

        sut.switchTab(to: 1)
        sut.navigate(to: .payslipDetail(id: UUID()))
        sut.navigate(to: .payslipDetail(id: UUID()))

        sut.switchTab(to: 2)
        // No navigation

        // Then - Each tab has its own stack
        sut.switchTab(to: 0)
        XCTAssertEqual(sut.homeStack.count, 1)

        sut.switchTab(to: 1)
        XCTAssertEqual(sut.payslipsStack.count, 2)

        sut.switchTab(to: 2)
        XCTAssertEqual(sut.insightsStack.count, 0)
    }

    func test_navigateToRoot_OnlyAffectsCurrentTab() {
        // Given
        sut.switchTab(to: 0)
        sut.navigate(to: .webUploads)

        sut.switchTab(to: 1)
        sut.navigate(to: .payslipDetail(id: UUID()))

        // When - Clear tab 1
        sut.navigateToRoot()

        // Then - Tab 0 is unaffected
        XCTAssertTrue(sut.payslipsStack.isEmpty)
        XCTAssertEqual(sut.homeStack.count, 1) // Tab 0 still has navigation
    }
}

import XCTest
@testable import PayslipMax

/// Tests for NavigationCoordinator core functionality
@MainActor
final class NavigationCoordinatorTests: XCTestCase {

    private var sut: NavigationCoordinator!

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
        XCTAssertEqual(sut.selectedTab, 0)
        sut.switchTab(to: 2)
        XCTAssertEqual(sut.selectedTab, 2)
    }

    func test_switchTab_WithInvalidIndex_DoesNothing() {
        sut.switchTab(to: 1)
        XCTAssertEqual(sut.selectedTab, 1)

        sut.switchTab(to: -1)
        sut.switchTab(to: 5)

        XCTAssertEqual(sut.selectedTab, 1)
    }

    func test_switchTab_WithDestination_NavigatesToDestination() {
        let destination = AppNavigationDestination.webUploads
        sut.switchTab(to: 3, destination: destination)

        XCTAssertEqual(sut.selectedTab, 3)
        XCTAssertFalse(sut.settingsStack.isEmpty)
    }

    // MARK: - Navigation Stack Tests

    func test_navigate_AddsToCurrentStack() {
        sut.switchTab(to: 1)
        XCTAssertTrue(sut.payslipsStack.isEmpty)

        sut.navigate(to: .payslipDetail(id: UUID()))

        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_navigateBack_RemovesFromStack() {
        sut.navigate(to: .webUploads)
        XCTAssertFalse(sut.homeStack.isEmpty)

        sut.navigateBack()

        XCTAssertTrue(sut.homeStack.isEmpty)
    }

    func test_navigateBack_WhenStackEmpty_DoesNothing() {
        XCTAssertTrue(sut.homeStack.isEmpty)
        sut.navigateBack()
        XCTAssertTrue(sut.homeStack.isEmpty)
    }

    func test_navigateToRoot_ClearsEntireStack() {
        sut.navigate(to: .webUploads)
        sut.navigate(to: .webUploads)
        sut.navigate(to: .webUploads)

        sut.navigateToRoot()

        XCTAssertTrue(sut.homeStack.isEmpty)
    }

    // MARK: - Sheet Presentation Tests

    func test_presentSheet_SetsSheetProperty() {
        XCTAssertNil(sut.sheet)
        sut.presentSheet(.addPayslip)

        XCTAssertNotNil(sut.sheet)
        if case .addPayslip = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .addPayslip sheet")
        }
    }

    func test_dismissSheet_ClearsSheetProperty() {
        sut.presentSheet(.addPayslip)
        XCTAssertNotNil(sut.sheet)

        sut.dismissSheet()

        XCTAssertNil(sut.sheet)
    }

    // MARK: - Full Screen Cover Tests

    func test_presentFullScreen_SetsFullScreenProperty() {
        XCTAssertNil(sut.fullScreenCover)
        sut.presentFullScreen(.scanner)

        XCTAssertNotNil(sut.fullScreenCover)
        if case .scanner = sut.fullScreenCover {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .scanner full screen cover")
        }
    }

    func test_dismissFullScreen_ClearsFullScreenProperty() {
        sut.presentFullScreen(.scanner)
        XCTAssertNotNil(sut.fullScreenCover)

        sut.dismissFullScreen()

        XCTAssertNil(sut.fullScreenCover)
    }

    // MARK: - Convenience Method Tests

    func test_showPayslipDetail_NavigatesToDetailView() {
        sut.switchTab(to: 1)
        let payslipId = UUID()

        sut.showPayslipDetail(id: payslipId)

        XCTAssertFalse(sut.payslipsStack.isEmpty)
    }

    func test_showAddPayslip_PresentsSheet() {
        XCTAssertNil(sut.sheet)
        sut.showAddPayslip()

        XCTAssertNotNil(sut.sheet)
        if case .addPayslip = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .addPayslip sheet")
        }
    }

    func test_showScanner_PresentsFullScreen() {
        XCTAssertNil(sut.fullScreenCover)
        sut.showScanner()

        XCTAssertNotNil(sut.fullScreenCover)
        if case .scanner = sut.fullScreenCover {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .scanner full screen cover")
        }
    }

    func test_showPinSetup_PresentsSheet() {
        XCTAssertNil(sut.sheet)
        sut.showPinSetup()

        XCTAssertNotNil(sut.sheet)
        if case .pinSetup = sut.sheet {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .pinSetup sheet")
        }
    }

    // MARK: - Tab Isolation Tests

    func test_tabStacks_AreIsolated() {
        sut.switchTab(to: 0)
        sut.navigate(to: .webUploads)

        sut.switchTab(to: 1)
        sut.navigate(to: .payslipDetail(id: UUID()))
        sut.navigate(to: .payslipDetail(id: UUID()))

        sut.switchTab(to: 2)

        sut.switchTab(to: 0)
        XCTAssertEqual(sut.homeStack.count, 1)

        sut.switchTab(to: 1)
        XCTAssertEqual(sut.payslipsStack.count, 2)

        sut.switchTab(to: 2)
        XCTAssertEqual(sut.insightsStack.count, 0)
    }

    func test_navigateToRoot_OnlyAffectsCurrentTab() {
        sut.switchTab(to: 0)
        sut.navigate(to: .webUploads)

        sut.switchTab(to: 1)
        sut.navigate(to: .payslipDetail(id: UUID()))

        sut.navigateToRoot()

        XCTAssertTrue(sut.payslipsStack.isEmpty)
        XCTAssertEqual(sut.homeStack.count, 1)
    }
}

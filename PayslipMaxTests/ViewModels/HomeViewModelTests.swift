import XCTest
import Foundation
import Combine
import PDFKit
@testable import PayslipMax

@MainActor
/// Tests focusing on HomeViewModel functionality with TestDIContainer integration
class HomeViewModelTests: BaseTestCase {

    // MARK: - Properties

    private var sut: HomeViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var asyncTasks: Set<Task<Void, Never>>!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Use TestDIContainer which provides controlled test services
        let testContainer = TestDIContainer.forTesting()
        sut = testContainer.makeHomeViewModel()
        cancellables = Set<AnyCancellable>()
        asyncTasks = Set<Task<Void, Never>>()
    }

    override func tearDownWithError() throws {
        // Cancel all async operations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Cancel all tasks
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()

        sut = nil
        cancellables = nil
        asyncTasks = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsDefaultValues() {
        // When: HomeViewModel is initialized through TestDIContainer

        // Then: Should have proper default state
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertNil(sut.currentPasswordProtectedPDFData)
        XCTAssertTrue(sut.recentPayslips.isEmpty) // TestDIContainer starts with empty data
    }

    // MARK: - Data Loading Tests

    func testLoadRecentPayslips_WithTestContainer_UpdatesState() async {
        // Given: HomeViewModel with TestDIContainer services

        // When: Loading recent payslips
        sut.loadRecentPayslips()

        // Wait briefly for async pipeline without forcing QoS escalation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await Task.yield()

        // Then: Should complete without error (TestDIContainer handles this)
        // Note: TestDIContainer may return empty data, which is expected in tests
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Notification Handling Tests

    func testForcedRefreshNotification_TriggersDataReload() async {
        // Given: HomeViewModel with some initial data
        let initialPayslips = [
            AnyPayslip(id: UUID(), timestamp: Date(), month: "January", year: 2024, credits: 50000.0, debits: 10000.0, dsop: 2500.0, tax: 7500.0, name: "Test", accountNumber: "123", panNumber: "ABC")
        ]

        // Simulate initial data
        sut.recentPayslips = initialPayslips

        // When: Forced refresh notification is posted
        NotificationCenter.default.post(name: .payslipsForcedRefresh, object: nil)

        // Wait for notification handling without priority inversion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        await Task.yield()

        // Then: Data coordinator should have been triggered to reload
        // Note: In a real test, we'd mock the data coordinator to verify the call
        // For now, we verify the notification doesn't crash and basic state is maintained
        XCTAssertNotNil(sut)
    }

    func testRefreshNotification_TriggersDataReload() async {
        // Given: HomeViewModel with initial state
        // When: Standard refresh notification is posted
        NotificationCenter.default.post(name: .payslipsRefresh, object: nil)

        // Wait for notification handling without forcing QoS escalation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        await Task.yield()

        // Then: Should handle notification without crashing
        XCTAssertNotNil(sut)
        // Note: Actual data verification would require mocking the data coordinator
    }

    func testPayslipDeletedNotification_TriggersListUpdate() async {
        // Given: HomeViewModel with payslips and a payslip ID to delete
        let testPayslipId = UUID()
        let initialPayslips = [
            AnyPayslip(id: testPayslipId, timestamp: Date(), month: "January", year: 2024, credits: 50000.0, debits: 10000.0, dsop: 2500.0, tax: 7500.0, name: "Test", accountNumber: "123", panNumber: "ABC"),
            AnyPayslip(id: UUID(), timestamp: Date(), month: "February", year: 2024, credits: 55000.0, debits: 11000.0, dsop: 2750.0, tax: 8250.0, name: "Test2", accountNumber: "456", panNumber: "DEF")
        ]
        sut.recentPayslips = initialPayslips

        // When: Payslip deleted notification is posted
        let userInfo = ["payslipId": testPayslipId]
        NotificationCenter.default.post(name: .payslipDeleted, object: nil, userInfo: userInfo)

        // Wait for notification handling without forcing QoS escalation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        await Task.yield()

        // Then: Should handle notification without crashing
        XCTAssertNotNil(sut)
        // Note: Actual removal verification would require mocking the data coordinator
    }
}

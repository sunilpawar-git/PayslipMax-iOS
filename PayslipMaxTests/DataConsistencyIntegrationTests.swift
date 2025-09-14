import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import PayslipMax

@MainActor
final class DataConsistencyIntegrationTests: BaseTestCase {

    // MARK: - Properties

    private var modelContainer: ModelContainer!
    private var context: ModelContext!
    private var homeViewModel: HomeViewModel!
    private var payslipsViewModel: PayslipsViewModel!
    private var settingsViewModel: SettingsViewModel!
    private var testContainer: TestDIContainer!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create in-memory model container for testing
        modelContainer = try ModelContainer(
            for: PayslipItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = modelContainer.mainContext

        // Create ViewModels with TestDIContainer using the same ModelContext as the test
        testContainer = TestDIContainer.forIntegrationTesting(modelContext: context)
        homeViewModel = testContainer.makeHomeViewModel()
        payslipsViewModel = testContainer.makePayslipsViewModel()
        settingsViewModel = testContainer.makeSettingsViewModel()

        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        // Cancel and clear all subscriptions first
        cancellables?.forEach { $0.cancel() }
        cancellables?.removeAll()
        cancellables = nil

        // CRITICAL: Remove all NotificationCenter observers before releasing ViewModels
        if let homeViewModel = homeViewModel {
            NotificationCenter.default.removeObserver(homeViewModel)
        }
        if let payslipsViewModel = payslipsViewModel {
            NotificationCenter.default.removeObserver(payslipsViewModel)
        }
        if let settingsViewModel = settingsViewModel {
            NotificationCenter.default.removeObserver(settingsViewModel)
        }

        // Clear ViewModels to break any potential retain cycles
        homeViewModel = nil
        payslipsViewModel = nil
        settingsViewModel = nil

        // Cleanup test container to release any references and reset shared state
        testContainer?.cleanup()
        testContainer = nil

        // Clear data context and container
        context = nil
        modelContainer = nil

        // Force garbage collection to clean up any remaining references
        autoreleasepool {
            // Empty pool to force cleanup
        }

        try super.tearDownWithError()
    }

    // MARK: - Integration Tests

    func testClearAllData_EnsuresDataConsistencyBetweenScreens() async throws {
        // Given: Both screens have payslips data
        let testPayslips = createTestPayslips(count: 3)
        try await addPayslipsToContext(testPayslips)

        // Load data in both ViewModels
        await loadDataInBothViewModels()

        // Verify both ViewModels have data
        XCTAssertFalse(homeViewModel.recentPayslips.isEmpty, "Home should have payslips before clearing")
        XCTAssertFalse(payslipsViewModel.payslips.isEmpty, "Payslips screen should have payslips before clearing")

        // When: Clear all data through Settings
        settingsViewModel.clearAllData(context: context)

        // Wait for the operation to complete and notifications to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then: Both screens should show no data (consistent empty state)
        XCTAssertTrue(homeViewModel.recentPayslips.isEmpty, "Home should have no payslips after clearing")
        XCTAssertTrue(payslipsViewModel.payslips.isEmpty, "Payslips screen should have no payslips after clearing")
    }

    func testNotificationPropagation_UpdatesHomeViewModelAfterClearing() async throws {
        // Given: HomeViewModel has payslips data
        let testPayslips = createTestPayslips(count: 2)
        try await addPayslipsToContext(testPayslips)

        // Load data in HomeViewModel
        homeViewModel.loadRecentPayslips()
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Verify HomeViewModel has data
        XCTAssertFalse(homeViewModel.recentPayslips.isEmpty, "Home should have payslips initially")

        // When: Clear all data (this posts notification)
        settingsViewModel.clearAllData(context: context)

        // Wait for notification handling
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then: HomeViewModel should be updated via notification
        XCTAssertTrue(homeViewModel.recentPayslips.isEmpty, "Home should have no payslips after notification")
    }

    func testClearAllData_WithError_DoesNotPostNotification() async throws {
        // Given: Mock data service that will fail
        let mockDataService = MockDataService()
        mockDataService.shouldFail = true
        mockDataService.errorToReturn = MockError.clearAllDataFailed

        // Create SettingsViewModel with failing service and ensure mock security service
        let failingSettingsViewModel = SettingsViewModel(
            securityService: testContainer.securityService,
            dataService: mockDataService
        )

        // Set up notification observer that should NOT be called
        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .payslipsForcedRefresh,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        // When: Clear all data (should fail)
        failingSettingsViewModel.clearAllData(context: context)

        // Wait to ensure notification is not posted
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Clean up observer
        NotificationCenter.default.removeObserver(observer)

        // Then: Notification should NOT be posted due to error
        XCTAssertFalse(notificationReceived, "Notification should not be posted when clearAllData fails")
        XCTAssertNotNil(failingSettingsViewModel.error, "Error should be set when operation fails")
    }

    func testDataConsistency_WithMultiplePayslips() async throws {
        // Given: Large dataset
        let testPayslips = createTestPayslips(count: 10)
        try await addPayslipsToContext(testPayslips)

        // Ensure data service is initialized
        if let dataService = settingsViewModel.dataService as? DataServiceImpl, !dataService.isInitialized {
            try await settingsViewModel.dataService.initialize()
        }

        // Load data in both ViewModels
        await loadDataInBothViewModels()

        // Verify initial state
        XCTAssertEqual(homeViewModel.recentPayslips.count, 5, "Home should show 5 most recent payslips")
        XCTAssertEqual(payslipsViewModel.payslips.count, 10, "Payslips screen should show all payslips")

        // When: Clear all data
        settingsViewModel.clearAllData(context: context)

        // Wait for completion with longer timeout
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then: Both should be consistently empty
        XCTAssertTrue(homeViewModel.recentPayslips.isEmpty, "Home should be empty after clearing")
        XCTAssertTrue(payslipsViewModel.payslips.isEmpty, "Payslips screen should be empty after clearing")
    }

    // MARK: - Helper Methods

    private func createTestPayslips(count: Int) -> [PayslipItem] {
        var payslips: [PayslipItem] = []

        for i in 0..<count {
            let payslip = PayslipItem(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(-i * 86400)), // Each day apart
                month: "Month\(i)",
                year: 2024,
                credits: Double(50000 + i * 1000),
                debits: Double(10000 + i * 200),
                dsop: Double(2500 + i * 50),
                tax: Double(7500 + i * 150),
                name: "Test Employee \(i)",
                accountNumber: "ACC\(i)",
                panNumber: "PAN\(i)"
            )
            payslips.append(payslip)
        }

        return payslips
    }

    private func addPayslipsToContext(_ payslips: [PayslipItem]) async throws {
        for payslip in payslips {
            context.insert(payslip)
        }
        try context.save()
    }

    private func loadDataInBothViewModels() async {
        // Load data in HomeViewModel
        homeViewModel.loadRecentPayslips()

        // Load data in PayslipsViewModel
        await payslipsViewModel.loadPayslips()

        // Wait for loading to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
}

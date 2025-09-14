import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import PayslipMax

@MainActor
final class SettingsViewModelTests: BaseTestCase {

    // MARK: - Helper Classes

    /// Actor-isolated wrapper for test values to avoid Sendable warnings
    private actor ActorIsolated<T> {
        var value: T

        init(_ value: T) {
            self.value = value
        }

        func setValue(_ newValue: T) {
            self.value = newValue
        }

        func getValue() -> T {
            return value
        }
    }

    /// Simple notification observer for testing
    private class NotificationObserver {
        private var observer: NSObjectProtocol?
        private var receivedNotification: Notification?

        func observe(notificationName: Notification.Name) async -> Notification? {
            return await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    self.observer = NotificationCenter.default.addObserver(
                        forName: notificationName,
                        object: nil,
                        queue: .main
                    ) { notification in
                        self.receivedNotification = notification
                        continuation.resume(returning: notification)
                        if let observer = self.observer {
                            NotificationCenter.default.removeObserver(observer)
                        }
                    }
                }
            }
        }

        func cancel() {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
            observer = nil
        }

        deinit {
            cancel()
        }
    }

    // MARK: - Properties

    private var sut: SettingsViewModel!
    private var mockDataService: MockDataService!
    private var notificationExpectation: XCTestExpectation!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create mock data service
        mockDataService = MockDataService()

        // Create SettingsViewModel with mock services
        sut = SettingsViewModel(dataService: mockDataService)

        cancellables = Set<AnyCancellable>()
        notificationExpectation = nil
    }

    override func tearDownWithError() throws {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)

        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        sut = nil
        mockDataService = nil
        notificationExpectation = nil

        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsDefaultValues() {
        // Then: Should have proper default state
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.useBiometricAuth)
        XCTAssertFalse(sut.useDarkMode)
        XCTAssertTrue(sut.payslips.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Clear All Data Tests

    func testClearAllData_WithSuccessfulDeletion_PostsForcedRefreshNotification() async throws {
        // Given: Model context and notification observer
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // Add some test payslips to context
        let testPayslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 10000.0,
            dsop: 2500.0,
            tax: 7500.0,
            name: "Test Employee",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F"
        )
        context.insert(testPayslip)
        try context.save()

        // Set up async notification observer
        let observer = NotificationObserver()

        // Start observing before clearing data
        let observeTask = Task {
            return await observer.observe(notificationName: .payslipsForcedRefresh)
        }

        // Give observer time to set up
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When: Clear all data
        sut.clearAllData(context: context)

        // Wait for notification with timeout
        let notification = await observeTask.value

        // Then: Notification should be posted
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification?.name, .payslipsForcedRefresh)

        // Clean up
        await observer.cancel()
    }

    func testClearAllData_WithError_DoesNotPostNotification() async throws {
        // Given: Model context and mock that will fail
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // Configure mock to throw error
        mockDataService.shouldFail = true
        mockDataService.errorToReturn = MockError.clearAllDataFailed

        // Set up async notification observer
        let observer = NotificationObserver()

        // Start observing (should timeout since no notification will be posted)
        let observeTask = Task {
            return await observer.observe(notificationName: .payslipsForcedRefresh)
        }

        // When: Clear all data (should fail)
        sut.clearAllData(context: context)

        // Wait for a reasonable time (notification should NOT be posted)
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Cancel observation (this should make observeTask return nil)
        await observer.cancel()

        // Wait for task to complete
        let notification = await observeTask.value

        // Then: Notification should NOT be posted due to error
        XCTAssertNil(notification, "No notification should be posted when clearAllData fails")
        XCTAssertNotNil(sut.error, "Error should be set when operation fails")
    }

    func testClearAllData_UpdatesLocalPayslipsArray() async throws {
        // Given: Model context with payslips
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // Add payslips to context
        let testPayslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 10000.0,
            dsop: 2500.0,
            tax: 7500.0,
            name: "Test Employee",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F"
        )
        context.insert(testPayslip)
        try context.save()

        // When: Clear all data
        sut.clearAllData(context: context)

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then: Local payslips array should be empty
        XCTAssertTrue(sut.payslips.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func testClearAllData_SetsLoadingStateCorrectly() async throws {
        // Given: Model context
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // When: Clear all data
        sut.clearAllData(context: context)

        // Then: Should start with loading = true
        XCTAssertTrue(sut.isLoading)

        // Wait for completion
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then: Should end with loading = false
        XCTAssertFalse(sut.isLoading)
    }
}

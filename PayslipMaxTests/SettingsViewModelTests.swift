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

    /// Simple notification observer for testing (Swift 6 compatible)
    private class NotificationObserver: @unchecked Sendable {
        private var observer: NSObjectProtocol?
        private var receivedNotificationName: String?
        private var continuation: CheckedContinuation<String?, Never>?
        private let lock = NSLock()

        func observe(notificationName: Notification.Name) async -> String? {
            return await withCheckedContinuation { continuation in
                lock.lock()
                self.continuation = continuation
                lock.unlock()

                self.observer = NotificationCenter.default.addObserver(
                    forName: notificationName,
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    self?.handleNotification(notification)
                }
            }
        }

        private func handleNotification(_ notification: Notification) {
            lock.lock()
            receivedNotificationName = notification.name.rawValue
            if let continuation = continuation {
                continuation.resume(returning: notification.name.rawValue)
                self.continuation = nil
            }
            lock.unlock()
            cancel()
        }

        func cancel() {
            lock.lock()
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
            if let continuation = continuation {
                continuation.resume(returning: nil)
                self.continuation = nil
            }
            lock.unlock()
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

        // Reset ThemeManager to system theme (ensures useDarkMode defaults to false)
        ThemeManager.shared.setTheme(.system)

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
        let notificationName = await observeTask.value

        // Then: Notification should be posted
        XCTAssertNotNil(notificationName)
        XCTAssertEqual(notificationName, Notification.Name.payslipsForcedRefresh.rawValue)

        // Clean up
        observer.cancel()
    }

    func testClearAllData_WithError_DoesNotPostNotification() async throws {
        // Given: Mock data service configured to fail
        mockDataService.shouldFail = true
        mockDataService.errorToReturn = MockError.clearAllDataFailed

        // Create a minimal context (not used in new implementation but required by method signature)
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // Set up async notification observer
        let observer = NotificationObserver()

        // Start observing with a timeout task
        let observeTask = Task {
            return await observer.observe(notificationName: .payslipsForcedRefresh)
        }

        // When: Clear all data (should fail due to mock configuration)
        sut.clearAllData(context: context)

        // Wait for operation to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Cancel observation
        observer.cancel()

        // Wait for task to complete
        let notificationName = await observeTask.value

        // Then: Notification should NOT be posted due to error
        XCTAssertNil(notificationName, "No notification should be posted when clearAllData fails")
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

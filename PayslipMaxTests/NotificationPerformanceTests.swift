import XCTest
import Foundation
@testable import PayslipMax

@MainActor
final class NotificationPerformanceTests: XCTestCase {

    // MARK: - Properties

    private var notificationCenter: NotificationCenter!
    private var performanceMetrics: PerformanceMetrics!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        notificationCenter = NotificationCenter()
        // Create a simple coordinator for testing
        let coordinator = PerformanceCoordinator()
        performanceMetrics = PerformanceMetrics(coordinator: coordinator)
    }

    override func tearDownWithError() throws {
        // Clean up notification observers
        notificationCenter.removeObserver(self)

        performanceMetrics = nil
        notificationCenter = nil

        try super.tearDownWithError()
    }

    // MARK: - Performance Tests

    func testNotificationDeliveryPerformance_SingleObserver() {
        // Given: Single notification observer
        let observer = createObserver(for: .payslipsForcedRefresh)

        // Measure performance of notification delivery
        measure {
            // When: Post notification
            notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
        }

        // Clean up
        notificationCenter.removeObserver(observer)
    }

    func testNotificationDeliveryPerformance_MultipleObservers() {
        // Given: Multiple observers for same notification
        let observer1 = createObserver(for: .payslipsRefresh)
        let observer2 = createObserver(for: .payslipsRefresh)
        let observer3 = createObserver(for: .payslipsRefresh)

        // Measure performance with multiple observers
        measure {
            // When: Post notification to multiple observers
            notificationCenter.post(name: .payslipsRefresh, object: nil)
        }

        // Clean up
        notificationCenter.removeObserver(observer1)
        notificationCenter.removeObserver(observer2)
        notificationCenter.removeObserver(observer3)
    }

    func testNotificationDeliveryPerformance_DifferentNotificationTypes() {
        // Given: Observers for different notification types
        let refreshObserver = createObserver(for: .payslipsRefresh)
        let forcedRefreshObserver = createObserver(for: .payslipsForcedRefresh)
        let deletedObserver = createObserver(for: .payslipDeleted)
        let updatedObserver = createObserver(for: .payslipUpdated)

        // Measure performance of posting different notification types
        measure {
            notificationCenter.post(name: .payslipsRefresh, object: nil)
            notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
            notificationCenter.post(name: .payslipDeleted, object: nil, userInfo: ["payslipId": UUID()])
            notificationCenter.post(name: .payslipUpdated, object: nil, userInfo: ["payslipId": UUID()])
        }

        // Clean up
        notificationCenter.removeObserver(refreshObserver)
        notificationCenter.removeObserver(forcedRefreshObserver)
        notificationCenter.removeObserver(deletedObserver)
        notificationCenter.removeObserver(updatedObserver)
    }

    func testPayslipEventsNotificationPerformance() {
        // Given: Standard notification observers
        let refreshObserver = createObserver(for: .payslipsRefresh)
        let forcedRefreshObserver = createObserver(for: .payslipsForcedRefresh)

        // Measure performance of PayslipEvents methods
        measure {
            // Test different PayslipEvents methods
            PayslipEvents.notifyRefreshRequired()
            PayslipEvents.notifyForcedRefreshRequired()
            PayslipEvents.notifyPayslipDeleted(id: UUID())
            PayslipEvents.notifyPayslipUpdated(id: UUID())
        }

        // Clean up
        notificationCenter.removeObserver(refreshObserver)
        notificationCenter.removeObserver(forcedRefreshObserver)
    }

    func testNotificationDeliveryPerformance_WithUserInfo() {
        // Given: Observer expecting user info
        let observer = createObserver(for: .payslipDeleted)

        // Measure performance with user info payload
        measure {
            let testId = UUID()
            notificationCenter.post(
                name: .payslipDeleted,
                object: nil,
                userInfo: ["payslipId": testId]
            )
        }

        // Clean up
        notificationCenter.removeObserver(observer)
    }

    func testNotificationDeliveryPerformance_BulkOperations() {
        // Given: Multiple observers for bulk operations
        var observers: [NSObjectProtocol] = []
        for _ in 0..<10 {
            observers.append(createObserver(for: .payslipsRefresh))
        }

        // Measure performance of bulk notification delivery
        measure {
            // Post notification to all observers
            notificationCenter.post(name: .payslipsRefresh, object: nil)
        }

        // Clean up
        observers.forEach { notificationCenter.removeObserver($0) }
    }

    func testNotificationMemoryPerformance_LongRunning() {
        // Given: Long-running test with many notifications
        let observer = createObserver(for: .payslipsRefresh)

        // Measure memory performance over time
        measure(metrics: [XCTMemoryMetric()]) {
            // Post many notifications
            for _ in 0..<1000 {
                notificationCenter.post(name: .payslipsRefresh, object: nil)
            }
        }

        // Clean up
        notificationCenter.removeObserver(observer)
    }

    func testNotificationDeliveryPerformance_ConcurrentAccess() {
        // Given: Multiple observers
        let observer1 = createObserver(for: .payslipsRefresh)
        let observer2 = createObserver(for: .payslipsRefresh)

        // Measure concurrent notification delivery
        measure {
            // Simulate concurrent access
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                notificationCenter.post(name: .payslipsRefresh, object: nil)
            }
        }

        // Clean up
        notificationCenter.removeObserver(observer1)
        notificationCenter.removeObserver(observer2)
    }

    // MARK: - Helper Methods

    private func createObserver(for notificationName: Notification.Name) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { _ in
            // Simple observer that just receives notifications
            // In a real app, this would trigger UI updates or business logic
        }
    }

    private func measureNotificationDeliveryTime(
        notificationName: Notification.Name,
        observerCount: Int = 1,
        iterations: Int = 1
    ) -> TimeInterval {
        // Create observers
        var observers: [NSObjectProtocol] = []
        for _ in 0..<observerCount {
            observers.append(createObserver(for: notificationName))
        }

        // Measure time
        let startTime = Date()

        for _ in 0..<iterations {
            notificationCenter.post(name: notificationName, object: nil)
        }

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)

        // Clean up
        observers.forEach { notificationCenter.removeObserver($0) }

        return totalTime
    }
}

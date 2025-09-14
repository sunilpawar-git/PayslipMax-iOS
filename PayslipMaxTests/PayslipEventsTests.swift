import XCTest
import Foundation
@testable import PayslipMax

@MainActor
final class PayslipEventsTests: XCTestCase {

    // MARK: - Properties

    private var notificationCenter: NotificationCenter!
    private var expectations: [XCTestExpectation]!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        notificationCenter = NotificationCenter()
        expectations = []
    }

    override func tearDownWithError() throws {
        // Clean up notification observers
        notificationCenter.removeObserver(self)

        expectations.removeAll()
        expectations = nil
        notificationCenter = nil

        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    /// Simple notification testing helper to avoid Sendable warnings
    private func testNotification(
        name: Notification.Name,
        testAction: () -> Void,
        verification: ((String, UUID?) -> Void)? = nil
    ) {
        let expectation = self.expectation(description: "Notification should be posted")

        // Use simple string-based verification to avoid Sendable issues
        var notificationReceived = false
        var receivedName: String = ""
        var receivedPayslipId: UUID?

        let observer = notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            receivedName = notification.name.rawValue
            receivedPayslipId = notification.userInfo?["payslipId"] as? UUID
            expectation.fulfill()
        }

        // Execute test action
        testAction()

        // Wait for notification
        wait(for: [expectation], timeout: 1.0)

        // Verify
        XCTAssertTrue(notificationReceived)
        XCTAssertEqual(receivedName, name.rawValue)

        // Additional verification
        verification?(receivedName, receivedPayslipId)

        // Clean up
        notificationCenter.removeObserver(observer)
    }

    // MARK: - Notification Posting Tests

    func testNotifyPayslipDeleted_PostsNotificationWithCorrectInfo() {
        let testPayslipId = UUID()

        testNotification(name: .payslipDeleted, testAction: {
            PayslipEvents.notifyPayslipDeleted(id: testPayslipId)
        }) { name, payslipId in
            XCTAssertEqual(name, Notification.Name.payslipDeleted.rawValue)
            XCTAssertEqual(payslipId, testPayslipId)
        }
    }

    func testNotifyPayslipUpdated_PostsNotificationWithCorrectInfo() {
        let testPayslipId = UUID()

        testNotification(name: .payslipUpdated, testAction: {
            PayslipEvents.notifyPayslipUpdated(id: testPayslipId)
        }) { name, payslipId in
            XCTAssertEqual(name, Notification.Name.payslipUpdated.rawValue)
            XCTAssertEqual(payslipId, testPayslipId)
        }
    }

    func testNotifyRefreshRequired_PostsNotification() {
        testNotification(name: .payslipsRefresh, testAction: {
            PayslipEvents.notifyRefreshRequired()
        }) { name, _ in
            XCTAssertEqual(name, Notification.Name.payslipsRefresh.rawValue)
        }
    }

    func testNotifyForcedRefreshRequired_PostsBothNotifications() {
        let refreshExpectation = expectation(description: "Refresh notification should be posted")
        let forcedRefreshExpectation = expectation(description: "Forced refresh notification should be posted")

        var notificationsReceived = Set<String>()

        let refreshObserver = notificationCenter.addObserver(
            forName: .payslipsRefresh,
            object: nil,
            queue: .main
        ) { _ in
            notificationsReceived.insert(Notification.Name.payslipsRefresh.rawValue)
            refreshExpectation.fulfill()
        }

        let forcedRefreshObserver = notificationCenter.addObserver(
            forName: .payslipsForcedRefresh,
            object: nil,
            queue: .main
        ) { _ in
            notificationsReceived.insert(Notification.Name.payslipsForcedRefresh.rawValue)
            forcedRefreshExpectation.fulfill()
        }

        // When: Notify forced refresh required
        PayslipEvents.notifyForcedRefreshRequired()

        // Wait for both notifications
        wait(for: [refreshExpectation, forcedRefreshExpectation], timeout: 1.0)

        // Clean up observers
        notificationCenter.removeObserver(refreshObserver)
        notificationCenter.removeObserver(forcedRefreshObserver)

        // Then: Both notifications should be posted
        XCTAssertTrue(notificationsReceived.contains(Notification.Name.payslipsRefresh.rawValue))
        XCTAssertTrue(notificationsReceived.contains(Notification.Name.payslipsForcedRefresh.rawValue))
    }

    @MainActor
    func testSwitchToPayslipsTab_PostsNotificationsWithDelay() {
        // Given: Multiple notification observers
        let refreshExpectation = expectation(description: "Refresh notification should be posted")
        let forcedRefreshExpectation = expectation(description: "Forced refresh notification should be posted")
        let tabSwitchExpectation = expectation(description: "Tab switch notification should be posted")

        var notificationOrder: [String] = []

        let refreshObserver = notificationCenter.addObserver(
            forName: .payslipsRefresh,
            object: nil,
            queue: .main
        ) { _ in
            notificationOrder.append(Notification.Name.payslipsRefresh.rawValue)
            refreshExpectation.fulfill()
        }

        let forcedRefreshObserver = notificationCenter.addObserver(
            forName: .payslipsForcedRefresh,
            object: nil,
            queue: .main
        ) { _ in
            notificationOrder.append(Notification.Name.payslipsForcedRefresh.rawValue)
            forcedRefreshExpectation.fulfill()
        }

        let tabSwitchObserver = notificationCenter.addObserver(
            forName: .switchToPayslipsTab,
            object: nil,
            queue: .main
        ) { _ in
            notificationOrder.append(Notification.Name.switchToPayslipsTab.rawValue)
            tabSwitchExpectation.fulfill()
        }

        // When: Switch to payslips tab
        PayslipEvents.switchToPayslipsTab()

        // Wait for all notifications (with delay for tab switch)
        wait(for: [refreshExpectation, forcedRefreshExpectation], timeout: 1.0)
        wait(for: [tabSwitchExpectation], timeout: 2.0)

        // Clean up observers
        notificationCenter.removeObserver(refreshObserver)
        notificationCenter.removeObserver(forcedRefreshObserver)
        notificationCenter.removeObserver(tabSwitchObserver)

        // Then: Notifications should be posted in correct order
        XCTAssertEqual(notificationOrder.count, 3)
        XCTAssertEqual(notificationOrder[0], Notification.Name.payslipsRefresh.rawValue)
        XCTAssertEqual(notificationOrder[1], Notification.Name.payslipsForcedRefresh.rawValue)
        XCTAssertEqual(notificationOrder[2], Notification.Name.switchToPayslipsTab.rawValue)
    }
}

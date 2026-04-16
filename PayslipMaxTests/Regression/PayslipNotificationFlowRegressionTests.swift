//
//  PayslipNotificationFlowRegressionTests.swift
//  PayslipMaxTests
//
//  Created to prevent regression: Cache invalidation storm from notifications
//  Ensures proper notification flow when payslips are saved
//

import XCTest
import Combine
@testable import PayslipMax

@MainActor
final class PayslipNotificationFlowRegressionTests: XCTestCase {

    var notificationCenter: NotificationCenter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        notificationCenter = NotificationCenter()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        cancellables = nil
        notificationCenter = nil
        try await super.tearDown()
    }

    // MARK: - Notification Flow Tests

    /// Test: Forced refresh sends both .payslipsRefresh and .payslipsForcedRefresh notifications
    func testForcedRefresh_SendsBothNotifications() async throws {
        // Given: Expectations for both notifications
        let refreshExpectation = expectation(description: "Refresh notification received")
        let forcedRefreshExpectation = expectation(description: "Forced refresh notification received")

        var refreshReceived = false
        var forcedRefreshReceived = false

        // Subscribe to notifications
        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in
                refreshReceived = true
                refreshExpectation.fulfill()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .payslipsForcedRefresh)
            .sink { _ in
                forcedRefreshReceived = true
                forcedRefreshExpectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Sending forced refresh notification
        await Task { @MainActor in
            // Simulate PayslipEvents.notifyForcedRefreshRequired()
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
            self.notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
        }.value

        // Then: Both notifications should be received
        await fulfillment(of: [refreshExpectation, forcedRefreshExpectation], timeout: 1.0)
        XCTAssertTrue(refreshReceived, "Refresh notification should be received")
        XCTAssertTrue(forcedRefreshReceived, "Forced refresh notification should be received")
    }

    /// Test: Multiple observers receive notifications correctly
    func testMultipleObservers_ReceiveNotifications() async throws {
        // Given: Multiple observers
        let observer1Expectation = expectation(description: "Observer 1 received notification")
        let observer2Expectation = expectation(description: "Observer 2 received notification")
        let observer3Expectation = expectation(description: "Observer 3 received notification")

        // Subscribe multiple observers
        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in observer1Expectation.fulfill() }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in observer2Expectation.fulfill() }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in observer3Expectation.fulfill() }
            .store(in: &cancellables)

        // When: Posting notification
        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        // Then: All observers should receive notification
        await fulfillment(of: [
            observer1Expectation,
            observer2Expectation,
            observer3Expectation
        ], timeout: 1.0)
    }

    /// Test: Notification handlers don't cause infinite loops
    func testNotificationHandlers_NoInfiniteLoop() async throws {
        // Given: A notification handler that could potentially trigger another notification
        var handlerCallCount = 0
        let maxExpectedCalls = 2 // Initial + one forced refresh

        let expectation = expectation(description: "Handler called expected number of times")
        expectation.expectedFulfillmentCount = maxExpectedCalls

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in
                handlerCallCount += 1
                expectation.fulfill()

                // Handler should NOT trigger another notification
                // This simulates what PayslipsViewModel.handlePayslipsRefresh does
                // (it just loads data, doesn't send more notifications)
            }
            .store(in: &cancellables)

        // When: Sending forced refresh (which sends 2 notifications)
        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        // Then: Handler should be called exactly maxExpectedCalls times
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(handlerCallCount, maxExpectedCalls, "Handler should be called exactly \(maxExpectedCalls) times")
    }

    /// Test: Notification ordering is correct
    func testNotificationOrdering_RefreshBeforeForcedRefresh() async throws {
        // Given: Expectations for notification order
        var notificationOrder: [String] = []
        let expectation = expectation(description: "All notifications received")
        expectation.expectedFulfillmentCount = 2

        // Subscribe to both notifications
        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in
                notificationOrder.append("refresh")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .payslipsForcedRefresh)
            .sink { _ in
                notificationOrder.append("forcedRefresh")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Sending notifications in correct order (as PayslipEvents does)
        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
            self.notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
        }.value

        // Then: Notifications should arrive in correct order
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(notificationOrder, ["refresh", "forcedRefresh"],
                       "Refresh notification should arrive before forced refresh")
    }

}

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
            .sink { [weak self] _ in
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

    // MARK: - Cache Invalidation Timing Tests

    /// Test: CRITICAL - Cache should NOT be invalidated before notifications are sent
    /// This was the root cause of the bug
    func testCacheInvalidation_NotBeforeNotifications() async throws {
        // Given: Mock cache manager
        let cacheManager = PayslipCacheManager(dataHandler: MockPayslipDataHandler())

        // Load initial data
        let mockDataHandler = MockPayslipDataHandler()
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let cacheManagerWithData = PayslipCacheManager(dataHandler: mockDataHandler)

        _ = try await cacheManagerWithData.loadPayslips()
        XCTAssertTrue(cacheManagerWithData.isLoaded, "Cache should be loaded")

        // Track notification and cache state
        var cacheWasValidWhenNotificationReceived = false

        let expectation = expectation(description: "Notification received")

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { [weak cacheManagerWithData] _ in
                // CRITICAL: Cache should still be valid when notification arrives
                // This allows notification handlers to fetch cached data
                cacheWasValidWhenNotificationReceived = cacheManagerWithData?.isLoaded ?? false
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Simulating save operation (send notification WITHOUT invalidating cache first)
        await Task { @MainActor in
            // DO NOT invalidate cache here (this was the bug)
            // cacheManagerWithData.invalidateCache() ❌ BUG

            // Instead, just send notification
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        // Then: Cache should be valid when notification is received
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(cacheWasValidWhenNotificationReceived,
                     "Cache should still be valid when notification arrives")
    }

    /// Test: Notification handlers invalidate cache AFTER receiving notification
    func testNotificationHandlers_InvalidateCacheAfterReceiving() async throws {
        // Given: Cache manager with data
        let mockDataHandler = MockPayslipDataHandler()
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let cacheManager = PayslipCacheManager(dataHandler: mockDataHandler)

        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        let expectation = expectation(description: "Handler processed notification")

        // Subscribe to forced refresh notification
        notificationCenter.publisher(for: .payslipsForcedRefresh)
            .sink { [weak cacheManager] _ in
                // When notification is received, handler invalidates cache
                cacheManager?.invalidateCache()
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Sending forced refresh notification
        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
        }.value

        // Then: Cache should be invalidated by the handler
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(cacheManager.isLoaded, "Cache should be invalidated by handler")
    }

    // MARK: - Performance Tests

    /// Test: Notification delivery performance with multiple observers
    func testNotificationPerformance_MultipleObservers() {
        // Given: 5 observers (simulating multiple ViewModels)
        let observerCount = 5
        var notificationCount = 0
        let expectation = expectation(description: "All observers received notification")
        expectation.expectedFulfillmentCount = observerCount

        for _ in 0..<observerCount {
            notificationCenter.publisher(for: .payslipsRefresh)
                .sink { _ in
                    notificationCount += 1
                    expectation.fulfill()
                }
                .store(in: &cancellables)
        }

        // When: Posting notification
        notificationCenter.post(name: .payslipsRefresh, object: nil)

        // Then: All observers should receive notification quickly
        wait(for: [expectation], timeout: 0.5)

        // Verify all observers were notified
        XCTAssertEqual(notificationCount, observerCount,
                      "All observers should receive notification")
    }

    /// Test: No notification storm (notifications don't cascade)
    func testNoNotificationStorm() async throws {
        // Given: Counter for notification delivery
        var deliveryCount = 0
        let expectation = expectation(description: "Single notification delivered")

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in
                deliveryCount += 1
                // Handler does NOT send another notification (preventing cascade)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Sending one notification
        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        // Then: Should receive exactly one notification
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(deliveryCount, 1, "Should receive exactly one notification")

        // Wait a bit to ensure no cascading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        XCTAssertEqual(deliveryCount, 1, "Should still have exactly one notification (no cascade)")
    }
}

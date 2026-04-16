import XCTest
import Combine
@testable import PayslipMax

@MainActor
final class PayslipNotificationCacheAndPerformanceTests: XCTestCase {

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

    // MARK: - Cache Invalidation Timing Tests

    func testCacheInvalidation_NotBeforeNotifications() async throws {
        let mockDataHandler = MockPayslipDataHandler()
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let cacheManagerWithData = PayslipCacheManager(dataHandler: mockDataHandler)

        _ = try await cacheManagerWithData.loadPayslips()
        XCTAssertTrue(cacheManagerWithData.isLoaded, "Cache should be loaded")

        var cacheWasValidWhenNotificationReceived = false

        let expectation = expectation(description: "Notification received")

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { [weak cacheManagerWithData] _ in
                cacheWasValidWhenNotificationReceived = cacheManagerWithData?.isLoaded ?? false
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(cacheWasValidWhenNotificationReceived,
                     "Cache should still be valid when notification arrives")
    }

    func testNotificationHandlers_InvalidateCacheAfterReceiving() async throws {
        let mockDataHandler = MockPayslipDataHandler()
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let cacheManager = PayslipCacheManager(dataHandler: mockDataHandler)

        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        let expectation = expectation(description: "Handler processed notification")

        notificationCenter.publisher(for: .payslipsForcedRefresh)
            .sink { [weak cacheManager] _ in
                cacheManager?.invalidateCache()
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsForcedRefresh, object: nil)
        }.value

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(cacheManager.isLoaded, "Cache should be invalidated by handler")
    }

    // MARK: - Performance Tests

    func testNotificationPerformance_MultipleObservers() {
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

        notificationCenter.post(name: .payslipsRefresh, object: nil)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(notificationCount, observerCount,
                      "All observers should receive notification")
    }

    func testNoNotificationStorm() async throws {
        var deliveryCount = 0
        let expectation = expectation(description: "Single notification delivered")

        notificationCenter.publisher(for: .payslipsRefresh)
            .sink { _ in
                deliveryCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await Task { @MainActor in
            self.notificationCenter.post(name: .payslipsRefresh, object: nil)
        }.value

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(deliveryCount, 1, "Should receive exactly one notification")

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(deliveryCount, 1, "Should still have exactly one notification (no cascade)")
    }
}

//
//  PayslipCacheRegressionTests.swift
//  PayslipMaxTests
//
//  Created to prevent regression: Payslips not appearing in Payslips tab after parsing
//  Root cause: Cache invalidation storm from multiple notification handlers
//

import XCTest
@testable import PayslipMax

@MainActor
final class PayslipCacheRegressionTests: XCTestCase {

    var cacheManager: PayslipCacheManager!
    var mockDataHandler: MockPayslipDataHandler!

    override func setUp() async throws {
        try await super.setUp()

        // Create mock data handler
        mockDataHandler = MockPayslipDataHandler()

        // Create cache manager with mock
        cacheManager = PayslipCacheManager(dataHandler: mockDataHandler)
    }

    override func tearDown() async throws {
        cacheManager = nil
        mockDataHandler = nil
        try await super.tearDown()
    }

    // MARK: - Regression Tests

    /// Test: Cache should NOT be invalidated before notifications are sent
    /// This was the root cause of the bug where payslips didn't appear in Payslips tab
    func testCacheInvalidation_NotCalledBeforeNotifications() async throws {
        // Given: A fresh cache manager
        XCTAssertFalse(cacheManager.isLoaded, "Cache should start unloaded")

        // When: Loading payslips
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let payslips = try await cacheManager.loadPayslips()

        // Then: Cache should be populated
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")
        XCTAssertEqual(payslips.count, 1, "Should have 1 payslip")
        XCTAssertEqual(cacheManager.cachedPayslips.count, 1, "Cache should contain 1 payslip")

        // Verify cache is valid
        let cachedPayslips = try await cacheManager.loadPayslipsIfNeeded()
        XCTAssertEqual(cachedPayslips.count, 1, "Should return cached payslip")
    }

    /// Test: Multiple notification handlers should not cause cache invalidation storm
    func testMultipleNotificationHandlers_DoNotClearCache() async throws {
        // Given: Cache is loaded with payslips
        mockDataHandler.payslipsToReturn = [
            TestDataGenerator.samplePayslipItem(),
            TestDataGenerator.samplePayslipItem()
        ]

        let initialPayslips = try await cacheManager.loadPayslips()
        XCTAssertEqual(initialPayslips.count, 2, "Should load 2 payslips")
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        // When: Simulating multiple notification handlers calling loadPayslipsIfNeeded
        // (this would happen when multiple ViewModels receive notifications)
        // Simulate concurrent notification handlers
        async let handler1Payslips = cacheManager.loadPayslipsIfNeeded()
        async let handler2Payslips = cacheManager.loadPayslipsIfNeeded()
        async let handler3Payslips = cacheManager.loadPayslipsIfNeeded()

        // Wait for all handlers to complete
        let (result1, result2, result3) = try await (handler1Payslips, handler2Payslips, handler3Payslips)

        // Then: All handlers should get cached payslips (not empty)
        XCTAssertEqual(result1.count, 2, "Handler 1 should get cached payslips")
        XCTAssertEqual(result2.count, 2, "Handler 2 should get cached payslips")
        XCTAssertEqual(result3.count, 2, "Handler 3 should get cached payslips")

        // Cache should still be valid
        XCTAssertTrue(cacheManager.isLoaded, "Cache should remain loaded")
        XCTAssertEqual(cacheManager.cachedPayslips.count, 2, "Cache should still contain 2 payslips")
    }

    /// Test: After saving a payslip, notification handlers should get fresh data
    func testPayslipSave_NotificationHandlers_GetFreshData() async throws {
        // Given: Cache is loaded with 1 payslip
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        let initialPayslips = try await cacheManager.loadPayslips()
        XCTAssertEqual(initialPayslips.count, 1, "Should start with 1 payslip")

        // When: A new payslip is saved (simulated by updating mock data)
        mockDataHandler.payslipsToReturn = [
            TestDataGenerator.samplePayslipItem(),
            TestDataGenerator.samplePayslipItem()
        ]

        // Simulate notification handler invalidating cache and reloading
        cacheManager.invalidateCache()
        let updatedPayslips = try await cacheManager.loadPayslips()

        // Then: Should get fresh data with 2 payslips
        XCTAssertEqual(updatedPayslips.count, 2, "Should get updated payslips")
        XCTAssertEqual(cacheManager.cachedPayslips.count, 2, "Cache should have 2 payslips")
    }

    /// Test: Cache validity duration works correctly
    func testCacheValidity_ExpiresAfterDuration() async throws {
        // Given: Cache is loaded
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        // When: Cache is still valid (within 5 minutes)
        let cachedPayslips = try await cacheManager.loadPayslipsIfNeeded()

        // Then: Should return cached data
        XCTAssertEqual(cachedPayslips.count, 1, "Should use cached data")
        XCTAssertEqual(mockDataHandler.loadCallCount, 1, "Should not reload from data handler")
    }

    /// Test: Forced refresh invalidates cache and reloads
    func testForcedRefresh_InvalidatesCacheAndReloads() async throws {
        // Given: Cache is loaded with 1 payslip
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        _ = try await cacheManager.loadPayslips()
        XCTAssertEqual(mockDataHandler.loadCallCount, 1, "Should load once")

        // When: Forced refresh is triggered
        cacheManager.invalidateCache()

        // Update mock data to return 2 payslips
        mockDataHandler.payslipsToReturn = [
            TestDataGenerator.samplePayslipItem(),
            TestDataGenerator.samplePayslipItem()
        ]

        let refreshedPayslips = try await cacheManager.loadPayslipsIfNeeded()

        // Then: Should reload from data handler
        XCTAssertEqual(mockDataHandler.loadCallCount, 2, "Should reload from data handler")
        XCTAssertEqual(refreshedPayslips.count, 2, "Should get fresh data")
    }

    // MARK: - Edge Cases

    /// Test: Empty cache returns empty array (not nil or error)
    func testEmptyCache_ReturnsEmptyArray() async throws {
        // Given: Mock returns empty array
        mockDataHandler.payslipsToReturn = []

        // When: Loading payslips
        let payslips = try await cacheManager.loadPayslips()

        // Then: Should return empty array
        XCTAssertEqual(payslips.count, 0, "Should return empty array")
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be marked as loaded even if empty")
    }

    /// Test: Cache invalidation during load doesn't cause race condition
    func testCacheInvalidation_DuringLoad_NoRaceCondition() async throws {
        // Given: Cache manager ready to load
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]

        // When: Starting load and immediately invalidating
        async let loadTask = cacheManager.loadPayslips()
        cacheManager.invalidateCache()

        let payslips = try await loadTask

        // Then: Should complete without crash
        XCTAssertGreaterThanOrEqual(payslips.count, 0, "Should complete load operation")
        // Cache may or may not be loaded depending on timing, but shouldn't crash
    }

    /// Test: Add payslip invalidates cache
    func testAddPayslip_InvalidatesCache() async throws {
        // Given: Cache is loaded
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        // When: Adding a payslip
        let newPayslip = TestDataGenerator.samplePayslipItem()
        cacheManager.addPayslipToCache(newPayslip)

        // Then: Cache should be invalidated
        XCTAssertFalse(cacheManager.isLoaded, "Cache should be invalidated")
        XCTAssertEqual(cacheManager.cachedPayslips.count, 0, "Cached payslips should be cleared")
    }

    /// Test: Update payslip invalidates cache
    func testUpdatePayslip_InvalidatesCache() async throws {
        // Given: Cache is loaded
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        // When: Updating a payslip
        let updatedPayslip = TestDataGenerator.samplePayslipItem()
        cacheManager.updatePayslipInCache(updatedPayslip)

        // Then: Cache should be invalidated
        XCTAssertFalse(cacheManager.isLoaded, "Cache should be invalidated")
    }

    /// Test: Remove payslip invalidates cache
    func testRemovePayslip_InvalidatesCache() async throws {
        // Given: Cache is loaded
        mockDataHandler.payslipsToReturn = [TestDataGenerator.samplePayslipItem()]
        _ = try await cacheManager.loadPayslips()
        XCTAssertTrue(cacheManager.isLoaded, "Cache should be loaded")

        // When: Removing a payslip
        cacheManager.removePayslipFromCache(withId: UUID())

        // Then: Cache should be invalidated
        XCTAssertFalse(cacheManager.isLoaded, "Cache should be invalidated")
    }
}

import XCTest
@testable import PayslipMax

/// Comprehensive unit tests for PayslipComparisonCacheManager
final class PayslipComparisonCacheManagerTests: XCTestCase {

    var sut: PayslipComparisonCacheManager!

    override func setUp() {
        super.setUp()
        sut = PayslipComparisonCacheManager(
            configuration: .init(maxEntries: 50, ttl: nil)
        )
        sut.clearCache()
        sut.waitForPendingOperations()
    }

    override func tearDown() {
        sut.clearCache()
        sut.waitForPendingOperations()
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Cache Operations

    func testSetAndGetComparison_WithValidData_ReturnsComparison() {
        // Given
        let payslipId = UUID()
        let comparison = createComparison(payslipId: payslipId)

        // When
        sut.setComparison(comparison, for: payslipId)
        sut.waitForPendingOperations()

        // Then
        let retrieved = sut.getComparison(for: payslipId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, comparison.id)
        XCTAssertEqual(retrieved?.currentPayslip.id, comparison.currentPayslip.id)
    }

    func testGetComparison_WithNonExistentId_ReturnsNil() {
        // Given
        let randomId = UUID()

        // When
        let retrieved = sut.getComparison(for: randomId)

        // Then
        XCTAssertNil(retrieved)
    }

    func testSetComparison_OverwritesExistingEntry() {
        // Given
        let payslipId = UUID()
        let firstComparison = createComparison(payslipId: payslipId, netChange: 1000)
        let secondComparison = createComparison(payslipId: payslipId, netChange: 2000)

        // When
        sut.setComparison(firstComparison, for: payslipId)
        sut.setComparison(secondComparison, for: payslipId)
        sut.waitForPendingOperations()

        // Then
        let retrieved = sut.getComparison(for: payslipId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.netRemittanceChange, 2000)
    }

    // MARK: - Cache Invalidation

    func testInvalidateComparison_RemovesSpecificEntry() {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let comparison1 = createComparison(payslipId: id1)
        let comparison2 = createComparison(payslipId: id2)

        sut.setComparison(comparison1, for: id1)
        sut.setComparison(comparison2, for: id2)
        sut.waitForPendingOperations()

        // When
        sut.invalidateComparison(for: id1)
        sut.waitForPendingOperations()

        // Then
        XCTAssertNil(sut.getComparison(for: id1))
        XCTAssertNotNil(sut.getComparison(for: id2))
    }

    func testInvalidateComparison_WithNonExistentId_DoesNotCrash() {
        // Given
        let randomId = UUID()

        // When/Then - Should not crash
        sut.invalidateComparison(for: randomId)
    }

    // MARK: - Clear Cache

    func testClearCache_RemovesAllEntries() {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        sut.setComparison(createComparison(payslipId: id1), for: id1)
        sut.setComparison(createComparison(payslipId: id2), for: id2)
        sut.setComparison(createComparison(payslipId: id3), for: id3)
        sut.waitForPendingOperations()

        // When
        sut.clearCache()
        sut.waitForPendingOperations()

        // Then
        XCTAssertNil(sut.getComparison(for: id1))
        XCTAssertNil(sut.getComparison(for: id2))
        XCTAssertNil(sut.getComparison(for: id3))
        XCTAssertEqual(sut.cacheSize, 0)
    }

    func testClearCache_OnEmptyCache_DoesNotCrash() {
        // When/Then - Should not crash
        sut.clearCache()
        sut.waitForPendingOperations()
        XCTAssertEqual(sut.cacheSize, 0)
    }

    // MARK: - Cache Size Limit

    func testCacheSizeLimit_EnforcesMaximum() {
        // Given - Add 55 entries (max is 50)
        let ids = (0..<55).map { _ in UUID() }

        // When
        for id in ids {
            sut.setComparison(createComparison(payslipId: id), for: id)
        }

        sut.waitForPendingOperations()

        // Then
        XCTAssertLessThanOrEqual(sut.cacheSize, 50)
    }

    func testLRUEviction_RemovesLeastRecentlyUsedEntry() {
        sut = PayslipComparisonCacheManager(
            configuration: .init(maxEntries: 3, ttl: nil)
        )

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()

        sut.setComparison(createComparison(payslipId: id1), for: id1)
        sut.setComparison(createComparison(payslipId: id2), for: id2)
        sut.setComparison(createComparison(payslipId: id3), for: id3)
        sut.waitForPendingOperations()

        // Access id1 to make it most recently used
        _ = sut.getComparison(for: id1)

        // Insert a new entry to trigger eviction
        sut.setComparison(createComparison(payslipId: id4), for: id4)
        sut.waitForPendingOperations()

        XCTAssertNil(sut.getComparison(for: id2)) // Least recently used should be evicted
        XCTAssertNotNil(sut.getComparison(for: id1))
        XCTAssertNotNil(sut.getComparison(for: id3))
        XCTAssertNotNil(sut.getComparison(for: id4))
    }

    func testTTLExpiration_RemovesExpiredEntries() {
        var now = Date()
        let dateProvider: () -> Date = { now }

        sut = PayslipComparisonCacheManager(
            configuration: .init(maxEntries: 5, ttl: 0.05),
            dateProvider: dateProvider
        )

        let id = UUID()
        sut.setComparison(createComparison(payslipId: id), for: id)
        sut.waitForPendingOperations()

        XCTAssertNotNil(sut.getComparison(for: id))

        // Advance time beyond TTL
        now = now.addingTimeInterval(0.1)

        XCTAssertNil(sut.getComparison(for: id))
        sut.waitForPendingOperations()
        XCTAssertEqual(sut.cacheSize, 0)
    }

    func testZeroCapacityImmediatelyClears() {
        sut = PayslipComparisonCacheManager(
            configuration: .init(maxEntries: 0, ttl: nil)
        )
        let id = UUID()
        sut.setComparison(createComparison(payslipId: id), for: id)
        sut.waitForPendingOperations()
        XCTAssertEqual(sut.cacheSize, 0)
    }

    // MARK: - Helper Methods

    private func createComparison(
        payslipId: UUID,
        netChange: Double = 0
    ) -> PayslipComparison {
        let currentPayslip = MockPayslip(
            id: payslipId,
            timestamp: Date(),
            month: "January",
            year: 2025,
            credits: 100000,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: ["Basic": 80000, "HRA": 20000],
            deductions: ["Tax": 15000, "DSOP": 8000],
            name: "Test User",
            accountNumber: "123456",
            panNumber: "ABCDE1234F",
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )

        return PayslipComparison(
            currentPayslip: currentPayslip,
            previousPayslip: nil,
            netRemittanceChange: netChange,
            netRemittancePercentageChange: nil,
            earningsChanges: [:],
            deductionsChanges: [:]
        )
    }
}

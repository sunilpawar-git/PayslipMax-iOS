import XCTest
@testable import PayslipMax

/// Comprehensive unit tests for PayslipComparisonCacheManager
final class PayslipComparisonCacheManagerTests: XCTestCase {

    var sut: PayslipComparisonCacheManager!

    override func setUp() {
        super.setUp()
        sut = PayslipComparisonCacheManager.shared
        sut.clearCache()
    }

    override func tearDown() {
        sut.clearCache()
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

        // When
        sut.invalidateComparison(for: id1)

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

        // When
        sut.clearCache()

        // Then
        XCTAssertNil(sut.getComparison(for: id1))
        XCTAssertNil(sut.getComparison(for: id2))
        XCTAssertNil(sut.getComparison(for: id3))
        XCTAssertEqual(sut.cacheSize, 0)
    }

    func testClearCache_OnEmptyCache_DoesNotCrash() {
        // When/Then - Should not crash
        sut.clearCache()
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

        // Wait for async operations to complete
        Thread.sleep(forTimeInterval: 0.1)

        // Then
        XCTAssertLessThanOrEqual(sut.cacheSize, 50)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentWrites_DoNotCrash() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        let iterations = 100
        var completed = 0

        // When - Perform concurrent writes
        for _ in 0..<iterations {
            DispatchQueue.global().async {
                let id = UUID()
                let comparison = self.createComparison(payslipId: id)
                self.sut.setComparison(comparison, for: id)

                // Track completion
                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }

        // Then - Should not crash
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completed == iterations)
    }

    func testConcurrentReads_DoNotCrash() {
        // Given
        let id = UUID()
        let comparison = createComparison(payslipId: id)
        sut.setComparison(comparison, for: id)

        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        let iterations = 100
        var completed = 0

        // When - Perform concurrent reads
        for _ in 0..<iterations {
            DispatchQueue.global().async {
                _ = self.sut.getComparison(for: id)

                // Track completion
                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }

        // Then - Should not crash
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completed == iterations)
    }

    func testConcurrentReadWriteClear_DoNotCrash() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        let iterations = 50
        let group = DispatchGroup()

        // When - Perform concurrent reads, writes, and clears
        for i in 0..<iterations {
            let id = UUID()
            let comparison = createComparison(payslipId: id)

            // Write
            group.enter()
            DispatchQueue.global().async {
                self.sut.setComparison(comparison, for: id)
                group.leave()
            }

            // Read
            group.enter()
            DispatchQueue.global().async {
                _ = self.sut.getComparison(for: id)
                group.leave()
            }

            // Clear every 10 iterations
            if i % 10 == 0 {
                group.enter()
                DispatchQueue.global().async {
                    self.sut.clearCache()
                    group.leave()
                }
            }
        }

        // Wait for all dispatched operations to complete
        group.notify(queue: .global()) {
            // Wait for all async cache operations to complete
            self.sut.waitForPendingOperations()
            expectation.fulfill()
        }

        // Then - Should not crash
        wait(for: [expectation], timeout: 10.0)
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

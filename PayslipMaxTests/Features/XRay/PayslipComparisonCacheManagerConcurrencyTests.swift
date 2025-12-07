import XCTest
@testable import PayslipMax

/// Concurrency and stress tests for PayslipComparisonCacheManager
final class PayslipComparisonCacheManagerConcurrencyTests: XCTestCase {

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

    func testConcurrentWrites_DoNotCrash() {
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        let iterations = 100
        var completed = 0

        for _ in 0..<iterations {
            DispatchQueue.global().async {
                let id = UUID()
                let comparison = self.createComparison(payslipId: id)
                self.sut.setComparison(comparison, for: id)

                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(completed, iterations)
    }

    func testConcurrentReads_DoNotCrash() {
        let id = UUID()
        let comparison = createComparison(payslipId: id)
        sut.setComparison(comparison, for: id)
        sut.waitForPendingOperations()

        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        let iterations = 100
        var completed = 0

        for _ in 0..<iterations {
            DispatchQueue.global().async {
                _ = self.sut.getComparison(for: id)

                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(completed, iterations)
    }

    func testConcurrentReadWriteClear_DoNotCrash() {
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        let iterations = 50
        let group = DispatchGroup()

        for i in 0..<iterations {
            let id = UUID()
            let comparison = createComparison(payslipId: id)

            group.enter()
            DispatchQueue.global().async {
                self.sut.setComparison(comparison, for: id)
                group.leave()
            }

            group.enter()
            DispatchQueue.global().async {
                _ = self.sut.getComparison(for: id)
                group.leave()
            }

            if i % 10 == 0 {
                group.enter()
                DispatchQueue.global().async {
                    self.sut.clearCache()
                    group.leave()
                }
            }
        }

        group.notify(queue: .global()) {
            self.sut.waitForPendingOperations()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

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


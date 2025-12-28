import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model persistence edge cases
/// Covers memory, performance, and extreme persistence scenarios
class AllowancePersistenceEdgeCaseTests: AllowanceTestCase {

    // MARK: - Memory and Performance Tests

    func testAllowance_LargeNumberOfInstances_DoesNotCauseMemoryIssues() {
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 1000)

        XCTAssertEqual(allowances.count, 1000)

        for allowance in allowances {
            XCTAssertNotNil(allowance.id)
            XCTAssertFalse(allowance.name.isEmpty)
            XCTAssertEqual(allowance.category, "Test")
        }

        let ids = allowances.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - Persistence Edge Cases

    func testAllowance_ExtremeValues_PersistAndRetrieveCorrectly() throws {
        let extremeAllowances = [
            Allowance(name: "Zero Allowance", amount: 0.0, category: "Test"),
            Allowance(name: "Negative Allowance", amount: -1000.0, category: "Test"),
            Allowance(name: "Large Allowance", amount: 1000000.0, category: "Test"),
            Allowance(name: "Decimal Allowance", amount: 1234.56, category: "Test"),
            Allowance(
                name: "Max Double",
                amount: Double.greatestFiniteMagnitude,
                category: "Extreme"
            ),
            Allowance(
                name: "Min Double",
                amount: -Double.greatestFiniteMagnitude,
                category: "Extreme"
            ),
            Allowance(name: "Infinity", amount: Double.infinity, category: "Extreme"),
            Allowance(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme"),
            Allowance(name: "NaN Amount", amount: Double.nan, category: "Special")
        ]

        for allowance in extremeAllowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, extremeAllowances.count)

        for originalAllowance in extremeAllowances {
            let fetchedAllowance = fetchedAllowances.first { $0.id == originalAllowance.id }
            XCTAssertNotNil(fetchedAllowance)
            XCTAssertEqual(fetchedAllowance?.name, originalAllowance.name)
            XCTAssertEqual(fetchedAllowance?.category, originalAllowance.category)

            if originalAllowance.amount.isNaN {
                XCTAssertTrue(fetchedAllowance?.amount.isNaN ?? false)
            } else {
                guard let fetchedAmount = fetchedAllowance?.amount else {
                    XCTFail("Expected fetched allowance to have an amount")
                    continue
                }
                XCTAssertEqual(fetchedAmount, originalAllowance.amount, accuracy: 0.01)
            }
        }
    }

    func testAllowance_VeryLongStrings_PersistCorrectly() throws {
        let longName = String(repeating: "Long name for testing persistence ", count: 50)
        let longCategory = String(repeating: "Long category for testing persistence ", count: 30)
        let allowance = Allowance(name: longName, amount: 12345.67, category: longCategory)

        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        let fetchedAllowance = fetchedAllowances.first!
        XCTAssertEqual(fetchedAllowance.name, longName)
        XCTAssertEqual(fetchedAllowance.category, longCategory)
        XCTAssertEqual(fetchedAllowance.amount, 12345.67)
    }
}


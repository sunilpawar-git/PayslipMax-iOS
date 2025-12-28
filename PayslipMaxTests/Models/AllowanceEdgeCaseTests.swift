import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model edge cases and extreme value handling
/// Covers boundary conditions, special values, and error scenarios
class AllowanceEdgeCaseTests: AllowanceTestCase {

    // MARK: - Extreme Value Tests

    func testAllowance_WithExtremeValues_HandlesCorrectly() {
        let allowances = [
            Allowance(name: "Zero Allowance", amount: 0.0, category: "Test"),
            Allowance(name: "Negative Allowance", amount: -1000.0, category: "Test"),
            Allowance(name: "Large Allowance", amount: 1000000.0, category: "Test"),
            Allowance(name: "Decimal Allowance", amount: 1234.56, category: "Test"),
            Allowance(name: "Max Double", amount: Double.greatestFiniteMagnitude, category: "Extreme"),
            Allowance(name: "Min Double", amount: -Double.greatestFiniteMagnitude, category: "Extreme"),
            Allowance(name: "Infinity", amount: Double.infinity, category: "Extreme"),
            Allowance(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme"),
            Allowance(name: "NaN Amount", amount: Double.nan, category: "Special")
        ]

        for allowance in allowances {
            XCTAssertNotNil(allowance.id, "ID should be generated for \(allowance.name)")
            XCTAssertFalse(allowance.name.isEmpty, "Name should not be empty for \(allowance.name)")
            XCTAssertFalse(allowance.category.isEmpty, "Category should not be empty for \(allowance.name)")
        }
    }

    func testAllowance_WithMaximumDoubleValue_SetsAmountCorrectly() {
        let allowance = Allowance(name: "Max Double", amount: Double.greatestFiniteMagnitude, category: "Extreme")

        XCTAssertEqual(allowance.amount, Double.greatestFiniteMagnitude)
        XCTAssertEqual(allowance.name, "Max Double")
        XCTAssertEqual(allowance.category, "Extreme")
    }

    func testAllowance_WithMinimumDoubleValue_SetsAmountCorrectly() {
        let allowance = Allowance(
            name: "Min Double",
            amount: -Double.greatestFiniteMagnitude,
            category: "Extreme"
        )

        XCTAssertEqual(allowance.amount, -Double.greatestFiniteMagnitude)
        XCTAssertEqual(allowance.name, "Min Double")
        XCTAssertEqual(allowance.category, "Extreme")
    }

    func testAllowance_WithInfinityAmount_HandlesCorrectly() {
        let allowance = Allowance(name: "Infinity", amount: Double.infinity, category: "Extreme")

        XCTAssertEqual(allowance.amount, Double.infinity)
        XCTAssertTrue(allowance.amount.isInfinite)
        XCTAssertFalse(allowance.amount.isNaN)
    }

    func testAllowance_WithNegativeInfinityAmount_HandlesCorrectly() {
        let allowance = Allowance(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme")

        XCTAssertEqual(allowance.amount, -Double.infinity)
        XCTAssertTrue(allowance.amount.isInfinite)
        XCTAssertFalse(allowance.amount.isNaN)
        XCTAssertEqual(allowance.amount.sign, .minus)
    }

    func testAllowance_WithNaNAmount_HandlesCorrectly() {
        let allowance = Allowance(name: "NaN Amount", amount: Double.nan, category: "Special")

        XCTAssertTrue(allowance.amount.isNaN)
        XCTAssertFalse(allowance.amount.isInfinite)
        XCTAssertEqual(allowance.name, "NaN Amount")
        XCTAssertEqual(allowance.category, "Special")
    }

    // MARK: - Zero and Negative Value Tests

    func testAllowance_WithZeroAmount_PersistsCorrectly() throws {
        let allowance = Allowance(name: "Zero Allowance", amount: 0.0, category: "Test")

        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, 0.0)
    }

    func testAllowance_WithNegativeAmount_PersistsCorrectly() throws {
        let allowance = Allowance(name: "Negative Allowance", amount: -1000.0, category: "Test")

        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, -1000.0)
    }

    // MARK: - Large Number Tests

    func testAllowance_WithLargeAmount_PersistsCorrectly() throws {
        let allowance = Allowance(name: "Large Allowance", amount: 1000000.0, category: "Test")

        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, 1000000.0)
    }

    func testAllowance_WithVeryLargeAmount_DoesNotCauseOverflow() throws {
        let allowance = Allowance(
            name: "Very Large",
            amount: Double.greatestFiniteMagnitude,
            category: "Extreme"
        )

        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, Double.greatestFiniteMagnitude)
    }

    // MARK: - String Edge Cases

    func testAllowance_WithEmptyStrings_HandlesCorrectly() {
        let allowance = Allowance(name: "", amount: 1000.0, category: "")

        XCTAssertEqual(allowance.name, "")
        XCTAssertEqual(allowance.category, "")
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    func testAllowance_WithVeryLongStrings_HandlesCorrectly() {
        let veryLongString = String(repeating: "A very long string for testing purposes ", count: 100)
        let allowance = Allowance(name: veryLongString, amount: 1000.0, category: veryLongString)

        XCTAssertEqual(allowance.name, veryLongString)
        XCTAssertEqual(allowance.category, veryLongString)
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    func testAllowance_WithControlCharacters_HandlesCorrectly() {
        let nameWithControlChars = "Allowance\u{0000}\u{0001}\u{0002}with\u{0003}control\u{0004}chars"
        let categoryWithChars = "Category\u{0000}\u{0001}with\u{0002}control\u{0003}chars"
        let allowance = Allowance(name: nameWithControlChars, amount: 1000.0, category: categoryWithChars)

        XCTAssertEqual(allowance.name, nameWithControlChars)
        XCTAssertEqual(allowance.category, categoryWithChars)
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    // MARK: - Precision Tests

    func testAllowance_WithHighPrecisionDecimal_SetsAmountCorrectly() {
        let highPrecisionAmount = 123456789.123456789
        let allowance = Allowance(name: "High Precision", amount: highPrecisionAmount, category: "Precision")

        XCTAssertEqual(allowance.amount, highPrecisionAmount, accuracy: 0.000000001)
        XCTAssertEqual(allowance.name, "High Precision")
        XCTAssertEqual(allowance.category, "Precision")
    }

    func testAllowance_WithVerySmallDecimal_SetsAmountCorrectly() {
        let verySmallAmount = 0.000000001
        let allowance = Allowance(name: "Very Small", amount: verySmallAmount, category: "Precision")

        XCTAssertEqual(allowance.amount, verySmallAmount, accuracy: 0.0000000001)
        XCTAssertEqual(allowance.name, "Very Small")
        XCTAssertEqual(allowance.category, "Precision")
    }

    // MARK: - Concurrent Access Tests

    func testAllowance_MultipleInstances_ShareNoMutableState() {
        let allowance1 = Allowance(name: "First", amount: 1000.0, category: "Test")
        let allowance2 = Allowance(name: "Second", amount: 2000.0, category: "Test")

        allowance1.amount = 1500.0
        allowance1.name = "Modified First"

        XCTAssertEqual(allowance1.name, "Modified First")
        XCTAssertEqual(allowance1.amount, 1500.0)
        XCTAssertEqual(allowance2.name, "Second")
        XCTAssertEqual(allowance2.amount, 2000.0)
    }
}

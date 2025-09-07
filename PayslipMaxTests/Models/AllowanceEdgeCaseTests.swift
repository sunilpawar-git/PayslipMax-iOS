import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model edge cases and extreme value handling
/// Covers boundary conditions, special values, and error scenarios
class AllowanceEdgeCaseTests: AllowanceTestCase {

    // MARK: - Extreme Value Tests

    func testAllowance_WithExtremeValues_HandlesCorrectly() {
        // Given
        let allowances = AllowanceTestHelpers.EdgeCaseData.allEdgeCases

        // When/Then
        for allowance in allowances {
            // Should not crash during initialization
            XCTAssertNotNil(allowance.id, "ID should be generated for \(allowance.name)")
            XCTAssertFalse(allowance.name.isEmpty, "Name should not be empty for \(allowance.name)")
            XCTAssertFalse(allowance.category.isEmpty, "Category should not be empty for \(allowance.name)")
        }
    }

    func testAllowance_WithMaximumDoubleValue_SetsAmountCorrectly() {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.maxDouble

        // When/Then
        XCTAssertEqual(allowance.amount, Double.greatestFiniteMagnitude)
        XCTAssertEqual(allowance.name, "Max Double")
        XCTAssertEqual(allowance.category, "Extreme")
    }

    func testAllowance_WithMinimumDoubleValue_SetsAmountCorrectly() {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.minDouble

        // When/Then
        XCTAssertEqual(allowance.amount, -Double.greatestFiniteMagnitude)
        XCTAssertEqual(allowance.name, "Min Double")
        XCTAssertEqual(allowance.category, "Extreme")
    }

    func testAllowance_WithInfinityAmount_HandlesCorrectly() {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.infinity

        // When/Then
        XCTAssertEqual(allowance.amount, Double.infinity)
        XCTAssertTrue(allowance.amount.isInfinite)
        XCTAssertFalse(allowance.amount.isNaN)
    }

    func testAllowance_WithNegativeInfinityAmount_HandlesCorrectly() {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.negativeInfinity

        // When/Then
        XCTAssertEqual(allowance.amount, -Double.infinity)
        XCTAssertTrue(allowance.amount.isInfinite)
        XCTAssertFalse(allowance.amount.isNaN)
        XCTAssertEqual(allowance.amount.sign, .minus)
    }

    func testAllowance_WithNaNAmount_HandlesCorrectly() {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.nanAmount

        // When/Then
        XCTAssertTrue(allowance.amount.isNaN)
        XCTAssertFalse(allowance.amount.isInfinite)
        XCTAssertEqual(allowance.name, "NaN Amount")
        XCTAssertEqual(allowance.category, "Special")
    }

    // MARK: - Zero and Negative Value Tests

    func testAllowance_WithZeroAmount_PersistsCorrectly() throws {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.zeroAmount

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, 0.0)
    }

    func testAllowance_WithNegativeAmount_PersistsCorrectly() throws {
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.negativeAmount

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
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
        // Given
        let allowance = AllowanceTestHelpers.EdgeCaseData.largeAmount

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.amount, 1000000.0)
    }

    func testAllowance_WithVeryLargeAmount_DoesNotCauseOverflow() throws {
        // Given
        let allowance = Allowance(name: "Very Large", amount: Double.greatestFiniteMagnitude, category: "Extreme")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
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
        // Given
        let allowance = Allowance(name: "", amount: 1000.0, category: "")

        // When/Then
        XCTAssertEqual(allowance.name, "")
        XCTAssertEqual(allowance.category, "")
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    func testAllowance_WithVeryLongStrings_HandlesCorrectly() {
        // Given
        let veryLongString = String(repeating: "A very long string for testing purposes ", count: 100)
        let allowance = Allowance(name: veryLongString, amount: 1000.0, category: veryLongString)

        // When/Then
        XCTAssertEqual(allowance.name, veryLongString)
        XCTAssertEqual(allowance.category, veryLongString)
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    func testAllowance_WithControlCharacters_HandlesCorrectly() {
        // Given
        let nameWithControlChars = "Allowance\u{0000}\u{0001}\u{0002}with\u{0003}control\u{0004}chars"
        let categoryWithControlChars = "Category\u{0000}\u{0001}with\u{0002}control\u{0003}chars"
        let allowance = Allowance(name: nameWithControlChars, amount: 1000.0, category: categoryWithControlChars)

        // When/Then
        XCTAssertEqual(allowance.name, nameWithControlChars)
        XCTAssertEqual(allowance.category, categoryWithControlChars)
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertNotNil(allowance.id)
    }

    // MARK: - Precision Tests

    func testAllowance_WithHighPrecisionDecimal_SetsAmountCorrectly() {
        // Given
        let highPrecisionAmount = 123456789.123456789
        let allowance = Allowance(name: "High Precision", amount: highPrecisionAmount, category: "Precision")

        // When/Then
        XCTAssertEqual(allowance.amount, highPrecisionAmount, accuracy: 0.000000001)
        XCTAssertEqual(allowance.name, "High Precision")
        XCTAssertEqual(allowance.category, "Precision")
    }

    func testAllowance_WithVerySmallDecimal_SetsAmountCorrectly() {
        // Given
        let verySmallAmount = 0.000000001
        let allowance = Allowance(name: "Very Small", amount: verySmallAmount, category: "Precision")

        // When/Then
        XCTAssertEqual(allowance.amount, verySmallAmount, accuracy: 0.0000000001)
        XCTAssertEqual(allowance.name, "Very Small")
        XCTAssertEqual(allowance.category, "Precision")
    }

    // MARK: - Concurrent Access Tests

    func testAllowance_MultipleInstances_ShareNoMutableState() {
        // Given
        let allowance1 = Allowance(name: "First", amount: 1000.0, category: "Test")
        let allowance2 = Allowance(name: "Second", amount: 2000.0, category: "Test")

        // When - Modify one instance
        allowance1.amount = 1500.0
        allowance1.name = "Modified First"

        // Then - Other instance should remain unchanged
        XCTAssertEqual(allowance1.name, "Modified First")
        XCTAssertEqual(allowance1.amount, 1500.0)
        XCTAssertEqual(allowance2.name, "Second")
        XCTAssertEqual(allowance2.amount, 2000.0)
    }

    // MARK: - Memory and Performance Tests

    func testAllowance_LargeNumberOfInstances_DoesNotCauseMemoryIssues() {
        // Given & When
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 1000)

        // Then
        XCTAssertEqual(allowances.count, 1000)

        // Verify all instances are properly initialized
        for allowance in allowances {
            XCTAssertNotNil(allowance.id)
            XCTAssertFalse(allowance.name.isEmpty)
            XCTAssertEqual(allowance.category, "Test")
        }

        // Verify uniqueness of IDs
        let ids = allowances.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - Persistence Edge Cases

    func testAllowance_ExtremeValues_PersistAndRetrieveCorrectly() throws {
        // Given
        let extremeAllowances = AllowanceTestHelpers.EdgeCaseData.allEdgeCases

        // When
        for allowance in extremeAllowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, extremeAllowances.count)

        // Verify each extreme value is retrieved correctly
        for originalAllowance in extremeAllowances {
            let fetchedAllowance = fetchedAllowances.first { $0.id == originalAllowance.id }
            XCTAssertNotNil(fetchedAllowance)
            XCTAssertEqual(fetchedAllowance?.name, originalAllowance.name)
            XCTAssertEqual(fetchedAllowance?.category, originalAllowance.category)

            // Special handling for NaN comparison
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
        // Given
        let longName = String(repeating: "Long name for testing persistence ", count: 50)
        let longCategory = String(repeating: "Long category for testing persistence ", count: 30)
        let allowance = Allowance(name: longName, amount: 12345.67, category: longCategory)

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        let fetchedAllowance = fetchedAllowances.first!
        XCTAssertEqual(fetchedAllowance.name, longName)
        XCTAssertEqual(fetchedAllowance.category, longCategory)
        XCTAssertEqual(fetchedAllowance.amount, 12345.67)
    }
}

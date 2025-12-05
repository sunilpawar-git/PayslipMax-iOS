import XCTest
@testable import PayslipMax

/// Tests for value-based display order in PayslipDisplayNameService
/// Ensures earnings/deductions show in descending value order (highest first)
final class PayslipDisplayNameServiceOrderTests: XCTestCase {

    var sut: PayslipDisplayNameService!

    override func setUp() {
        super.setUp()
        sut = PayslipDisplayNameService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Earnings Display Order Tests

    func testEarningsDisplayOrder_SortedByValueDescending() {
        // Given: Mixed earnings with various values
        let earnings: [String: Double] = [
            "RH12": 12000.0,
            "Basic Pay": 144700.0,
            "ARRTPTL": 1705.0,
            "Military Service Pay": 15500.0,
            "Dearness Allowance": 88110.0,
            "TPTL": 13000.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Should be sorted by value in descending order (highest first)
        XCTAssertEqual(result.count, 6, "Should have 6 earnings items")
        XCTAssertEqual(result[0].value, 144700.0, "Highest value (Basic Pay) should be first")
        XCTAssertEqual(result[1].value, 88110.0, "Second highest (DA) should be second")
        XCTAssertEqual(result[2].value, 15500.0, "Third highest (MSP) should be third")
        XCTAssertEqual(result[3].value, 13000.0, "Fourth highest (TPTL) should be fourth")
        XCTAssertEqual(result[4].value, 12000.0, "Fifth highest (RH12) should be fifth")
        XCTAssertEqual(result[5].value, 1705.0, "Lowest value (ARRTPTL) should be last")
    }

    func testEarningsDisplayOrder_NotAlphabetical() {
        // Given: Earnings that would be in different order if alphabetical
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "ARRTPTL": 1705.0,  // Would be first alphabetically
            "Dearness Allowance": 88110.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Should be sorted by value, not alphabetically
        XCTAssertNotEqual(result[0].displayName, "Arrtptl", "Should not be alphabetically sorted")
        XCTAssertEqual(result[0].displayName, "Basic Pay", "Highest value should be first")
        XCTAssertEqual(result[1].displayName, "Dearness Allowance", "Second highest should be second")
        XCTAssertEqual(result[2].displayName, "Arrtptl", "Lowest value should be last")
    }

    func testEarningsDisplayOrder_OtherEarningsPositionByValue() {
        // Given: Earnings with "Other Earnings" having a mid-range value
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "Other Earnings": 50000.0,  // Mid-range value
            "RH12": 12000.0,
            "Dearness Allowance": 88110.0,
            "Military Service Pay": 15500.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: "Other Earnings" should be positioned by its value, not last
        XCTAssertEqual(result.count, 5, "Should have 5 earnings items")
        XCTAssertEqual(result[0].value, 144700.0, "Basic Pay highest")
        XCTAssertEqual(result[1].value, 88110.0, "DA second")
        XCTAssertEqual(result[2].value, 50000.0, "Other Earnings third by value")
        XCTAssertEqual(result[3].value, 15500.0, "MSP fourth")
        XCTAssertEqual(result[4].value, 12000.0, "RH12 fifth")
    }

    func testEarningsDisplayOrder_EqualValuesMaintainOrder() {
        // Given: Earnings with some equal values
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "Item A": 10000.0,
            "Item B": 10000.0,
            "Item C": 10000.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Basic Pay should be first, equal values grouped together
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].value, 144700.0, "Basic Pay should be first")
        // Equal values (10000) should all be after Basic Pay
        XCTAssertEqual(result[1].value, 10000.0)
        XCTAssertEqual(result[2].value, 10000.0)
        XCTAssertEqual(result[3].value, 10000.0)
    }

    func testEarningsDisplayOrder_ZeroValuesFiltered() {
        // Given: Earnings with zero values
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "RH12": 0.0,  // Should be filtered
            "Dearness Allowance": 88110.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Should only have 2 items (zero values filtered)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].value, 144700.0, "Basic Pay should be first")
        XCTAssertEqual(result[1].value, 88110.0, "DA should be second")
    }

    // MARK: - Deductions Display Order Tests

    func testDeductionsDisplayOrder_SortedByValueDescending() {
        // Given: Mixed deductions with various values
        let deductions: [String: Double] = [
            "EHCESS": 1905.0,
            "Income Tax": 47624.0,
            "DSOP": 40000.0,
            "AGIF": 12500.0,
            "Custom Deduction": 1000.0
        ]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: Should be sorted by value in descending order
        XCTAssertEqual(result.count, 5, "Should have 5 deduction items")
        XCTAssertEqual(result[0].value, 47624.0, "Income Tax (highest) should be first")
        XCTAssertEqual(result[1].value, 40000.0, "DSOP should be second")
        XCTAssertEqual(result[2].value, 12500.0, "AGIF should be third")
        XCTAssertEqual(result[3].value, 1905.0, "EHCESS should be fourth")
        XCTAssertEqual(result[4].value, 1000.0, "Custom Deduction should be last")
    }

    func testDeductionsDisplayOrder_OtherDeductionsPositionByValue() {
        // Given: Deductions with "Other Deductions" having a low value
        let deductions: [String: Double] = [
            "AGIF": 12500.0,
            "Other Deductions": 2000.0,  // Low value
            "DSOP": 40000.0,
            "Income Tax": 47624.0
        ]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: "Other Deductions" should be positioned by its value
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].value, 47624.0, "Income Tax first")
        XCTAssertEqual(result[1].value, 40000.0, "DSOP second")
        XCTAssertEqual(result[2].value, 12500.0, "AGIF third")
        XCTAssertEqual(result[3].value, 2000.0, "Other Deductions last by value")
    }

    func testDeductionsDisplayOrder_NotAlphabetical() {
        // Given: Deductions that would be in different order if alphabetical
        let deductions: [String: Double] = [
            "DSOP": 40000.0,
            "AGIF": 12500.0,  // Would be first alphabetically
            "Income Tax": 47624.0
        ]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: Should be sorted by value, not alphabetically
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].displayName, "Income Tax", "Highest value first")
        XCTAssertEqual(result[1].displayName, "DSOP", "Second highest second")
        XCTAssertEqual(result[2].displayName, "AGIF", "Third highest third")
    }

    // MARK: - Edge Cases

    func testEarningsDisplayOrder_EmptyDictionary() {
        // Given: Empty earnings
        let earnings: [String: Double] = [:]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Should return empty array
        XCTAssertTrue(result.isEmpty, "Empty earnings should return empty array")
    }

    func testDeductionsDisplayOrder_EmptyDictionary() {
        // Given: Empty deductions
        let deductions: [String: Double] = [:]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: Should return empty array
        XCTAssertTrue(result.isEmpty, "Empty deductions should return empty array")
    }

    func testEarningsDisplayOrder_SingleItem() {
        // Given: Single earning
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Should have one item with correct value
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].displayName, "Basic Pay")
        XCTAssertEqual(result[0].value, 144700.0)
    }

    func testDeductionsDisplayOrder_SingleItem() {
        // Given: Single deduction
        let deductions: [String: Double] = [
            "Income Tax": 55100.0
        ]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: Should have one item with correct value
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].displayName, "Income Tax")
        XCTAssertEqual(result[0].value, 55100.0)
    }

    func testEarningsDisplayOrder_AllValuesPreserved() {
        // Given: Earnings with specific values
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "RH12": 12000.0,
            "Dearness Allowance": 88110.0
        ]

        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)

        // Then: Values should be preserved correctly in descending order
        XCTAssertEqual(result[0].value, 144700.0, "Basic Pay value should be preserved")
        XCTAssertEqual(result[1].value, 88110.0, "DA value should be preserved")
        XCTAssertEqual(result[2].value, 12000.0, "RH12 value should be preserved")
    }

    func testDeductionsDisplayOrder_AllValuesPreserved() {
        // Given: Deductions with specific values
        let deductions: [String: Double] = [
            "Income Tax": 55100.0,
            "DSOP": 40000.0,
            "AGIF": 10000.0
        ]

        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)

        // Then: Values should be preserved correctly in descending order
        XCTAssertEqual(result[0].value, 55100.0, "Income Tax value should be preserved")
        XCTAssertEqual(result[1].value, 40000.0, "DSOP value should be preserved")
        XCTAssertEqual(result[2].value, 10000.0, "AGIF value should be preserved")
    }
}

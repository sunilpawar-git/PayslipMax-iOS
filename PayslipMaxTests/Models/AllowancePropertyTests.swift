import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model property validation and handling
/// Covers amount ranges, string properties, and data integrity
class AllowancePropertyTests: AllowanceTestCase {

    // MARK: - Amount Property Tests

    func testAllowance_WithZeroAmount_SetsAmountCorrectly() {
        // Given
        let name = "Special Allowance"
        let amount = 0.0
        let category = "Special"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.amount, 0.0)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithNegativeAmount_SetsAmountCorrectly() {
        // Given
        let name = "Adjustment Allowance"
        let amount = -100.0
        let category = "Adjustment"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.amount, -100.0)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithLargeAmount_SetsAmountCorrectly() {
        // Given
        let name = "Executive Allowance"
        let amount = 100000.0
        let category = "Executive"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.amount, 100000.0)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithDecimalAmount_SetsAmountCorrectly() {
        // Given
        let name = "Partial Allowance"
        let amount = 1234.56
        let category = "Partial"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.amount, 1234.56, accuracy: 0.01)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.category, category)
    }

    // MARK: - String Property Tests

    func testAllowance_WithEmptyName_SetsNameCorrectly() {
        // Given
        let name = ""
        let amount = 500.0
        let category = "Standard"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.name, "")
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithEmptyCategory_SetsCategoryCorrectly() {
        // Given
        let name = "Unnamed Allowance"
        let amount = 500.0
        let category = ""

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, "")
    }

    func testAllowance_WithLongName_SetsNameCorrectly() {
        // Given
        let name = AllowanceTestHelpers.StringTestData.longName
        let amount = 500.0
        let category = "Standard"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithSpecialCharactersInName_SetsNameCorrectly() {
        // Given
        let name = AllowanceTestHelpers.StringTestData.specialCharacters
        let amount = 500.0
        let category = "Special"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testAllowance_WithUnicodeCharacters_SetsNameCorrectly() {
        // Given
        let name = AllowanceTestHelpers.StringTestData.unicodeCharacters
        let amount = 500.0
        let category = "International"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    // MARK: - Property Modification Tests

    func testAllowance_NameProperty_CanBeModified() {
        // Given
        var allowance: Allowance = Allowance(name: "Original Name", amount: 1000.0, category: "Test") // var needed for mutation test
        let newName = "Modified Name"

        // When
        allowance.name = newName

        // Then
        XCTAssertEqual(allowance.name, newName)
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertEqual(allowance.category, "Test")
    }

    func testAllowance_AmountProperty_CanBeModified() {
        // Given
        var allowance: Allowance = Allowance(name: "Test Allowance", amount: 1000.0, category: "Test") // var needed for mutation test
        let newAmount = 2000.0

        // When
        allowance.amount = newAmount

        // Then
        XCTAssertEqual(allowance.name, "Test Allowance")
        XCTAssertEqual(allowance.amount, newAmount)
        XCTAssertEqual(allowance.category, "Test")
    }

    func testAllowance_CategoryProperty_CanBeModified() {
        // Given
        var allowance: Allowance = Allowance(name: "Test Allowance", amount: 1000.0, category: "Test") // var needed for mutation test
        let newCategory = "Modified Category"

        // When
        allowance.category = newCategory

        // Then
        XCTAssertEqual(allowance.name, "Test Allowance")
        XCTAssertEqual(allowance.amount, 1000.0)
        XCTAssertEqual(allowance.category, newCategory)
    }

    // MARK: - Property Validation Tests

    func testAllowance_PropertyValues_RemainConsistent() {
        // Given
        let originalName = "Original Allowance"
        let originalAmount = 1500.0
        let originalCategory = "Original Category"

        // When
        let allowance = Allowance(name: originalName, amount: originalAmount, category: originalCategory)

        // Then
        XCTAssertEqual(allowance.name, originalName)
        XCTAssertEqual(allowance.amount, originalAmount)
        XCTAssertEqual(allowance.category, originalCategory)
    }

    func testAllowance_AllProperties_CanBeSetToEmptyStrings() {
        // Given
        var allowance: Allowance = Allowance(name: "Test", amount: 1000.0, category: "Test") // var needed for mutation test

        // When
        allowance.name = ""
        allowance.category = ""

        // Then
        XCTAssertEqual(allowance.name, "")
        XCTAssertEqual(allowance.category, "")
        XCTAssertEqual(allowance.amount, 1000.0)
    }

    func testAllowance_Amount_CanBeSetToExtremeValues() {
        // Given
        var allowance: Allowance = Allowance(name: "Extreme Test", amount: 1000.0, category: "Test") // var needed for mutation test

        // When/Then
        allowance.amount = Double.greatestFiniteMagnitude
        XCTAssertEqual(allowance.amount, Double.greatestFiniteMagnitude)

        allowance.amount = -Double.greatestFiniteMagnitude
        XCTAssertEqual(allowance.amount, -Double.greatestFiniteMagnitude)

        allowance.amount = Double.infinity
        XCTAssertEqual(allowance.amount, Double.infinity)

        allowance.amount = -Double.infinity
        XCTAssertEqual(allowance.amount, -Double.infinity)

        allowance.amount = Double.nan
        XCTAssertTrue(allowance.amount.isNaN)
    }
}

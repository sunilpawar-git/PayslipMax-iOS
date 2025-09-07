import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model initialization and basic setup
/// Covers constructor validation, default values, and unique ID generation
class AllowanceInitializationTests: AllowanceTestCase {

    // MARK: - Basic Initialization Tests

    func testInitialization_WithAllParameters_SetsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let name = "House Rent Allowance"
        let amount = 1500.0
        let category = "Standard"

        // When
        let allowance = Allowance(id: id, name: name, amount: amount, category: category)

        // Then
        XCTAssertEqual(allowance.id, id)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testInitialization_WithDefaultId_GeneratesUniqueId() {
        // Given
        let name = "Transport Allowance"
        let amount = 800.0
        let category = "Standard"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertNotNil(allowance.id)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testInitialization_MultipleInstances_GenerateUniqueIds() {
        // Given
        let name1 = "Medical Allowance"
        let name2 = "Food Allowance"
        let amount = 500.0
        let category = "Standard"

        // When
        let allowance1 = Allowance(name: name1, amount: amount, category: category)
        let allowance2 = Allowance(name: name2, amount: amount, category: category)

        // Then
        XCTAssertNotEqual(allowance1.id, allowance2.id)
        XCTAssertEqual(allowance1.name, name1)
        XCTAssertEqual(allowance2.name, name2)
        XCTAssertEqual(allowance1.amount, amount)
        XCTAssertEqual(allowance2.amount, amount)
        XCTAssertEqual(allowance1.category, category)
        XCTAssertEqual(allowance2.category, category)
    }

    // MARK: - ID Uniqueness Tests

    func testInitialization_HundredInstances_AllHaveUniqueIds() {
        // Given & When
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 100)

        // Then
        let ids = allowances.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All generated IDs should be unique")
    }

    func testInitialization_SameParameters_DifferentIds() {
        // Given
        let name = "Duplicate Name Allowance"
        let amount = 1000.0
        let category = "Test"

        // When
        let allowance1 = Allowance(name: name, amount: amount, category: category)
        let allowance2 = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertNotEqual(allowance1.id, allowance2.id)
        XCTAssertEqual(allowance1.name, allowance2.name)
        XCTAssertEqual(allowance1.amount, allowance2.amount)
        XCTAssertEqual(allowance1.category, allowance2.category)
    }

    // MARK: - Parameter Validation Tests

    func testInitialization_WithNilOptionalParameters_UsesDefaults() {
        // Given
        let name = "Basic Allowance"
        let amount = 500.0
        let category = "Standard"

        // When
        let allowance = Allowance(name: name, amount: amount, category: category)

        // Then
        XCTAssertNotNil(allowance.id)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }

    func testInitialization_WithExtremeParameterLengths_HandlesCorrectly() {
        // Given
        let longName = String(repeating: "A", count: 1000)
        let longCategory = String(repeating: "B", count: 1000)
        let amount = 12345.67

        // When
        let allowance = Allowance(name: longName, amount: amount, category: longCategory)

        // Then
        XCTAssertEqual(allowance.name, longName)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, longCategory)
    }

    // MARK: - Initialization Edge Cases

    func testInitialization_WithWhitespaceParameters_HandlesCorrectly() {
        // Given
        let nameWithSpaces = "  Allowance with spaces  "
        let categoryWithSpaces = "  Category with spaces  "
        let amount = 1000.0

        // When
        let allowance = Allowance(name: nameWithSpaces, amount: amount, category: categoryWithSpaces)

        // Then
        XCTAssertEqual(allowance.name, nameWithSpaces)
        XCTAssertEqual(allowance.category, categoryWithSpaces)
        XCTAssertEqual(allowance.amount, amount)
    }

    func testInitialization_WithNewlineCharacters_HandlesCorrectly() {
        // Given
        let nameWithNewlines = "Allowance\nwith\nnewlines"
        let categoryWithNewlines = "Category\nwith\nnewlines"
        let amount = 2000.0

        // When
        let allowance = Allowance(name: nameWithNewlines, amount: amount, category: categoryWithNewlines)

        // Then
        XCTAssertEqual(allowance.name, nameWithNewlines)
        XCTAssertEqual(allowance.category, categoryWithNewlines)
        XCTAssertEqual(allowance.amount, amount)
    }

    func testInitialization_WithTabCharacters_HandlesCorrectly() {
        // Given
        let nameWithTabs = "Allowance\twith\ttabs"
        let categoryWithTabs = "Category\twith\ttabs"
        let amount = 3000.0

        // When
        let allowance = Allowance(name: nameWithTabs, amount: amount, category: categoryWithTabs)

        // Then
        XCTAssertEqual(allowance.name, nameWithTabs)
        XCTAssertEqual(allowance.category, categoryWithTabs)
        XCTAssertEqual(allowance.amount, amount)
    }
}

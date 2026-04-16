import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model SwiftData persistence operations
/// Covers CRUD operations, querying, and data integrity
class AllowancePersistenceTests: AllowanceTestCase {

    // MARK: - Basic Persistence Tests

    func testAllowance_CanBePersisted() throws {
        // Given
        let allowance = Allowance(name: "Test Allowance", amount: 1000.0, category: "Test")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.name, "Test Allowance")
        XCTAssertEqual(fetchedAllowance.amount, 1000.0)
        XCTAssertEqual(fetchedAllowance.category, "Test")
    }

    func testAllowance_CanBeFetchedById() throws {
        // Given
        let id = UUID()
        let allowance = Allowance(id: id, name: "Fetchable Allowance", amount: 1500.0, category: "Test")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let predicate = #Predicate<Allowance> { $0.id == id }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.id, id)
        XCTAssertEqual(fetchedAllowances.first?.name, "Fetchable Allowance")
    }

    func testAllowance_CanBeFetchedByName() throws {
        // Given
        let name = "Searchable Allowance"
        let allowance = Allowance(name: name, amount: 1200.0, category: "Test")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Then
        let predicate = #Predicate<Allowance> { $0.name == name }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.name, name)
        XCTAssertEqual(fetchedAllowance.amount, 1200.0)
    }

    func testAllowance_CanBeFetchedByCategory() throws {
        // Given
        let category = "Premium"
        let allowance1 = Allowance(name: "Premium Allowance 1", amount: 1000.0, category: category)
        let allowance2 = Allowance(name: "Premium Allowance 2", amount: 1500.0, category: category)
        let allowance3 = Allowance(name: "Standard Allowance", amount: 800.0, category: "Standard")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance1, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(allowance2, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(allowance3, in: modelContext)

        // Then
        let predicate = #Predicate<Allowance> { $0.category == category }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 2)
        XCTAssertTrue(fetchedAllowances.allSatisfy { $0.category == category })
    }

    // MARK: - Update Tests

    func testAllowance_CanBeUpdated() throws {
        // Given
        let allowance = Allowance(name: "Original Name", amount: 1000.0, category: "Original")
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // When
        try AllowanceTestHelpers.updateAllowance(allowance,
                                                name: "Updated Name",
                                                amount: 2000.0,
                                                category: "Updated",
                                                in: modelContext)

        // Then
        let allowanceId = allowance.id
        let predicate = #Predicate<Allowance> { $0.id == allowanceId }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        let updatedAllowance = fetchedAllowances.first!
        XCTAssertEqual(updatedAllowance.name, "Updated Name")
        XCTAssertEqual(updatedAllowance.amount, 2000.0)
        XCTAssertEqual(updatedAllowance.category, "Updated")
    }

    func testAllowance_UpdateOnlyName_LeavesOtherPropertiesUnchanged() throws {
        // Given
        let originalAllowance = Allowance(name: "Original", amount: 1000.0, category: "Test")
        try AllowanceTestHelpers.persistAllowance(originalAllowance, in: modelContext)

        // When
        try AllowanceTestHelpers.updateAllowance(originalAllowance, name: "Updated Name", in: modelContext)

        // Then
        let fetchedAllowance = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext).first!
        XCTAssertEqual(fetchedAllowance.name, "Updated Name")
        XCTAssertEqual(fetchedAllowance.amount, 1000.0)
        XCTAssertEqual(fetchedAllowance.category, "Test")
    }

    func testAllowance_UpdateOnlyAmount_LeavesOtherPropertiesUnchanged() throws {
        // Given
        let originalAllowance = Allowance(name: "Test", amount: 1000.0, category: "Test")
        try AllowanceTestHelpers.persistAllowance(originalAllowance, in: modelContext)

        // When
        try AllowanceTestHelpers.updateAllowance(originalAllowance, amount: 2500.0, in: modelContext)

        // Then
        let fetchedAllowance = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext).first!
        XCTAssertEqual(fetchedAllowance.name, "Test")
        XCTAssertEqual(fetchedAllowance.amount, 2500.0)
        XCTAssertEqual(fetchedAllowance.category, "Test")
    }

    // MARK: - Delete Tests

    func testAllowance_CanBeDeleted() throws {
        // Given
        let allowance = Allowance(name: "Deletable Allowance", amount: 1000.0, category: "Test")
        try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)

        // Verify it exists
        var fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)

        // When
        try AllowanceTestHelpers.deleteAllowance(allowance, from: modelContext)

        // Then
        fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 0)
    }

    func testAllowance_DeleteNonExistent_DoesNotThrow() throws {
        // Given
        let allowance = Allowance(name: "Non-existent", amount: 1000.0, category: "Test")

        // When/Then - Should not throw even if allowance was never persisted
        XCTAssertNoThrow(try AllowanceTestHelpers.deleteAllowance(allowance, from: modelContext))
    }

}

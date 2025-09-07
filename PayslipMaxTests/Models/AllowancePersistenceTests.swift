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

    // MARK: - Batch Operations Tests

    func testAllowance_MultipleAllowances_CanBePersistedAndFetched() throws {
        // Given
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 5, baseName: "Batch Allowance")

        // When
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // Then
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 5)

        // Verify all allowances are correctly persisted
        for (index, allowance) in allowances.enumerated() {
            guard let fetchedAllowance = fetchedAllowances.first(where: { $0.id == allowance.id }) else {
                XCTFail("Expected to find allowance with ID \(allowance.id)")
                continue
            }
            
            XCTAssertEqual(fetchedAllowance.name, "Batch Allowance \(index + 1)")
            XCTAssertEqual(fetchedAllowance.amount, 1000.0 + Double(index * 100), accuracy: 0.01)
            XCTAssertEqual(fetchedAllowance.category, "Test")
        }
    }

    func testAllowance_BatchDelete_RemovesAllSpecifiedAllowances() throws {
        // Given
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 3)
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // Verify all exist
        var fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 3)

        // When - Delete first two allowances
        try AllowanceTestHelpers.deleteAllowance(allowances[0], from: modelContext)
        try AllowanceTestHelpers.deleteAllowance(allowances[1], from: modelContext)

        // Then
        fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.id, allowances[2].id)
    }

    // MARK: - Query Tests

    func testAllowance_QueryByAmountRange_ReturnsCorrectResults() throws {
        // Given
        let allowances = [
            Allowance(name: "Low Amount", amount: 500.0, category: "Test"),
            Allowance(name: "Medium Amount", amount: 1500.0, category: "Test"),
            Allowance(name: "High Amount", amount: 2500.0, category: "Test")
        ]

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // When - Query for amounts between 1000 and 2000
        let predicate = #Predicate<Allowance> { $0.amount >= 1000.0 && $0.amount <= 2000.0 }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)

        // Then
        XCTAssertEqual(fetchedAllowances.count, 1)
        
        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }
        
        XCTAssertEqual(fetchedAllowance.name, "Medium Amount")
        XCTAssertEqual(fetchedAllowance.amount, 1500.0)
    }

    func testAllowance_QueryByPartialName_ReturnsCorrectResults() throws {
        // Given
        let allowances = [
            Allowance(name: "House Rent Allowance", amount: 1000.0, category: "Standard"),
            Allowance(name: "Transport Allowance", amount: 1000.0, category: "Standard"),
            Allowance(name: "Medical Allowance", amount: 1000.0, category: "Standard")
        ]

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // When - Query for names containing "Rent"
        let predicate = #Predicate<Allowance> { $0.name.contains("Rent") }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)

        // Then
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.name, "House Rent Allowance")
    }

    // MARK: - Unique Constraint Tests

    func testAllowance_UniqueIdConstraint_PreventsDuplicates() throws {
        // Given
        let id = UUID()
        let allowance1 = Allowance(id: id, name: "First Allowance", amount: 1000.0, category: "Test")
        let allowance2 = Allowance(id: id, name: "Second Allowance", amount: 2000.0, category: "Test")

        // When
        try AllowanceTestHelpers.persistAllowance(allowance1, in: modelContext)

        // Then - Note: SwiftData unique constraint enforcement varies by environment
        // In test environment, this may not throw but should handle gracefully
        do {
            try AllowanceTestHelpers.persistAllowance(allowance2, in: modelContext)
            // If it doesn't throw, verify only one allowance exists with that ID
            let predicate = #Predicate<Allowance> { $0.id == id }
            let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
            XCTAssertEqual(fetchedAllowances.count, 1)
        } catch {
            // If it does throw due to unique constraint, that's expected behavior
            XCTAssertTrue(true, "Unique constraint violation caught as expected")
        }
    }
}

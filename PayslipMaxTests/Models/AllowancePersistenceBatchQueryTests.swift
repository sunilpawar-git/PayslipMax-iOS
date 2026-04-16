import XCTest
import SwiftData
@testable import PayslipMax

class AllowancePersistenceBatchQueryTests: AllowanceTestCase {

    // MARK: - Batch Operations Tests

    func testAllowance_MultipleAllowances_CanBePersistedAndFetched() throws {
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 5, baseName: "Batch Allowance")

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 5)

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
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 3)
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        var fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 3)

        try AllowanceTestHelpers.deleteAllowance(allowances[0], from: modelContext)
        try AllowanceTestHelpers.deleteAllowance(allowances[1], from: modelContext)

        fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.id, allowances[2].id)
    }

    // MARK: - Query Tests

    func testAllowance_QueryByAmountRange_ReturnsCorrectResults() throws {
        let allowances = [
            Allowance(name: "Low Amount", amount: 500.0, category: "Test"),
            Allowance(name: "Medium Amount", amount: 1500.0, category: "Test"),
            Allowance(name: "High Amount", amount: 2500.0, category: "Test")
        ]

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        let predicate = #Predicate<Allowance> { $0.amount >= 1000.0 && $0.amount <= 2000.0 }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)

        XCTAssertEqual(fetchedAllowances.count, 1)

        guard let fetchedAllowance = fetchedAllowances.first else {
            XCTFail("Expected to fetch one allowance, but got none")
            return
        }

        XCTAssertEqual(fetchedAllowance.name, "Medium Amount")
        XCTAssertEqual(fetchedAllowance.amount, 1500.0)
    }

    func testAllowance_QueryByPartialName_ReturnsCorrectResults() throws {
        let allowances = [
            Allowance(name: "House Rent Allowance", amount: 1000.0, category: "Standard"),
            Allowance(name: "Transport Allowance", amount: 1000.0, category: "Standard"),
            Allowance(name: "Medical Allowance", amount: 1000.0, category: "Standard")
        ]

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        let predicate = #Predicate<Allowance> { $0.name.contains("Rent") }
        let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)

        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.name, "House Rent Allowance")
    }

    // MARK: - Unique Constraint Tests

    func testAllowance_UniqueIdConstraint_PreventsDuplicates() throws {
        let id = UUID()
        let allowance1 = Allowance(id: id, name: "First Allowance", amount: 1000.0, category: "Test")
        let allowance2 = Allowance(id: id, name: "Second Allowance", amount: 2000.0, category: "Test")

        try AllowanceTestHelpers.persistAllowance(allowance1, in: modelContext)

        do {
            try AllowanceTestHelpers.persistAllowance(allowance2, in: modelContext)
            let predicate = #Predicate<Allowance> { $0.id == id }
            let fetchedAllowances = try AllowanceTestHelpers.fetchAllowances(with: predicate, from: modelContext)
            XCTAssertEqual(fetchedAllowances.count, 1)
        } catch {
            XCTAssertTrue(true, "Unique constraint violation caught as expected")
        }
    }
}

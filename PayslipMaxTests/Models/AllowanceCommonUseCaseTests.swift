import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model common use cases and business scenarios
class AllowanceCommonUseCaseTests: AllowanceTestCase {

    // MARK: - Common Allowance Types Tests

    func testAllowance_CommonAllowanceTypes_CreateCorrectly() {
        let commonAllowances = [
            ("House Rent Allowance", 15000.0, "Standard"),
            ("Transport Allowance", 3000.0, "Standard"),
            ("Medical Allowance", 5000.0, "Standard"),
            ("Food Allowance", 2000.0, "Standard"),
            ("Special Allowance", 10000.0, "Special"),
            ("Overtime Allowance", 5000.0, "Variable"),
            ("Shift Allowance", 2500.0, "Variable"),
            ("Education Allowance", 1000.0, "Welfare"),
            ("Mobile Allowance", 500.0, "Communication"),
            ("Fuel Allowance", 3000.0, "Transport")
        ]

        let allowances = commonAllowances.map { name, amount, category in
            Allowance(name: name, amount: amount, category: category)
        }

        XCTAssertEqual(allowances.count, 10)
        for (index, allowance) in allowances.enumerated() {
            let expected = commonAllowances[index]
            XCTAssertEqual(allowance.name, expected.0)
            XCTAssertEqual(allowance.amount, expected.1)
            XCTAssertEqual(allowance.category, expected.2)
            XCTAssertNotNil(allowance.id)
        }
    }

    // MARK: - Business Logic Tests

    func testAllowance_SalaryBreakdown_CalculatesCorrectly() {
        let basicPay = Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic")
        let houseRentAllowance = Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard")
        let transportAllowance = Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard")
        let dearnessAllowance = Allowance(name: "Dearness Allowance", amount: 10500.0, category: "Standard")
        let medicalAllowance = Allowance(name: "Medical Allowance", amount: 125.0, category: "Standard")

        let allowances = [basicPay, houseRentAllowance, transportAllowance, dearnessAllowance, medicalAllowance]
        let totalEarnings = allowances.reduce(0.0) { $0 + $1.amount }

        XCTAssertEqual(totalEarnings, 75325.0)
    }

    func testAllowance_DefensePayslip_ComponentsAreValid() {
        let defenseAllowances = [
            Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic"),
            Allowance(name: "Grade Pay", amount: 4200.0, category: "Basic"),
            Allowance(name: "Military Service Pay", amount: 2000.0, category: "Military"),
            Allowance(name: "Dearness Allowance", amount: 10500.0, category: "Standard"),
            Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard"),
            Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard"),
            Allowance(name: "Dress Allowance", amount: 5000.0, category: "Special"),
            Allowance(name: "Medical Allowance", amount: 125.0, category: "Standard"),
            Allowance(name: "Washing Allowance", amount: 90.0, category: "Special")
        ]

        for allowance in defenseAllowances {
            XCTAssertNotNil(allowance.id)
            XCTAssertFalse(allowance.name.isEmpty)
            XCTAssertFalse(allowance.category.isEmpty)
            XCTAssertGreaterThanOrEqual(allowance.amount, 0.0)
        }

        let totalAmount = defenseAllowances.reduce(0.0) { $0 + $1.amount }
        XCTAssertGreaterThan(totalAmount, 0.0)
    }

    // MARK: - Category-based Tests

    func testAllowance_CategoryGrouping_WorksCorrectly() throws {
        let allowances = AllowanceTestHelpers.TestAllowanceData.allCommonAllowances

        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        let standardPredicate = #Predicate<Allowance> { $0.category == "Standard" }
        let standardAllowances = try AllowanceTestHelpers.fetchAllowances(
            with: standardPredicate,
            from: modelContext
        )

        let specialPredicate = #Predicate<Allowance> { $0.category == "Special" }
        let specialAllowances = try AllowanceTestHelpers.fetchAllowances(
            with: specialPredicate,
            from: modelContext
        )

        XCTAssertEqual(standardAllowances.count, 3)
        XCTAssertEqual(specialAllowances.count, 1)
        XCTAssertTrue(standardAllowances.allSatisfy { $0.category == "Standard" })
        XCTAssertTrue(specialAllowances.allSatisfy { $0.category == "Special" })
    }

    func testAllowance_AmountRanges_ByCategory_AreRealistic() {
        let testCases = [
            ("Basic Pay", 35000.0, "Basic", 15000.0, 100000.0),
            ("House Rent Allowance", 15000.0, "Standard", 5000.0, 50000.0),
            ("Transport Allowance", 3000.0, "Standard", 1000.0, 20000.0),
            ("Medical Allowance", 5000.0, "Standard", 100.0, 15000.0),
            ("Special Allowance", 10000.0, "Special", 1000.0, 50000.0),
            ("Overtime Allowance", 5000.0, "Variable", 500.0, 25000.0),
            ("Education Allowance", 1000.0, "Welfare", 500.0, 5000.0)
        ]

        for testCase in testCases {
            let allowance = Allowance(name: testCase.0, amount: testCase.1, category: testCase.2)
            XCTAssertGreaterThanOrEqual(allowance.amount, testCase.3)
            XCTAssertLessThanOrEqual(allowance.amount, testCase.4)
            XCTAssertEqual(allowance.category, testCase.2)
        }
    }

    // MARK: - Bulk Operations Tests

    func testAllowance_BulkCreation_PerformsEfficiently() {
        let startTime = Date()
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 100, baseName: "Bulk Test")
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertEqual(allowances.count, 100)
        XCTAssertLessThan(duration, 1.0)

        for allowance in allowances {
            XCTAssertNotNil(allowance.id)
            XCTAssertTrue(allowance.name.hasPrefix("Bulk Test"))
            XCTAssertEqual(allowance.category, "Test")
        }
    }

    func testAllowance_BulkPersistence_WorksCorrectly() throws {
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 50)

        let startTime = Date()
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 5.0)

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 50)
    }
}

import XCTest
import SwiftData
@testable import PayslipMax

/// Tests for Allowance model common use cases and business scenarios
/// Covers typical allowance types and real-world usage patterns
class AllowanceCommonUseCaseTests: AllowanceTestCase {

    // MARK: - Common Allowance Types Tests

    func testAllowance_CommonAllowanceTypes_CreateCorrectly() {
        // Given
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

        // When
        let allowances = commonAllowances.map { name, amount, category in
            Allowance(name: name, amount: amount, category: category)
        }

        // Then
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
        // Given - Typical Indian defense salary components
        let basicPay = Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic")
        let houseRentAllowance = Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard") // 30% of basic
        let transportAllowance = Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard") // Actual transport
        let dearnessAllowance = Allowance(name: "Dearness Allowance", amount: 10500.0, category: "Standard") // Same as HRA
        let medicalAllowance = Allowance(name: "Medical Allowance", amount: 125.0, category: "Standard") // Monthly medical

        let allowances = [basicPay, houseRentAllowance, transportAllowance, dearnessAllowance, medicalAllowance]

        // When
        let totalEarnings = allowances.reduce(0.0) { $0 + $1.amount }

        // Then
        XCTAssertEqual(totalEarnings, 75325.0)
        XCTAssertEqual(basicPay.amount, 35000.0)
        XCTAssertEqual(houseRentAllowance.amount, 10500.0)
        XCTAssertEqual(transportAllowance.amount, 19200.0)
        XCTAssertEqual(dearnessAllowance.amount, 10500.0)
        XCTAssertEqual(medicalAllowance.amount, 125.0)
    }

    func testAllowance_DefensePayslip_ComponentsAreValid() {
        // Given - Defense-specific allowance components
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

        // When/Then
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
        // Given
        let allowances = AllowanceTestHelpers.TestAllowanceData.allCommonAllowances

        // When
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }

        // Then - Query by different categories
        let standardPredicate = #Predicate<Allowance> { $0.category == "Standard" }
        let standardAllowances = try AllowanceTestHelpers.fetchAllowances(with: standardPredicate, from: modelContext)

        let specialPredicate = #Predicate<Allowance> { $0.category == "Special" }
        let specialAllowances = try AllowanceTestHelpers.fetchAllowances(with: specialPredicate, from: modelContext)

        let variablePredicate = #Predicate<Allowance> { $0.category == "Variable" }
        let variableAllowances = try AllowanceTestHelpers.fetchAllowances(with: variablePredicate, from: modelContext)

        let welfarePredicate = #Predicate<Allowance> { $0.category == "Welfare" }
        let welfareAllowances = try AllowanceTestHelpers.fetchAllowances(with: welfarePredicate, from: modelContext)

        // Verify counts
        XCTAssertEqual(standardAllowances.count, 3) // HRA, Transport, Medical
        XCTAssertEqual(specialAllowances.count, 1) // Special Allowance
        XCTAssertEqual(variableAllowances.count, 1) // Overtime
        XCTAssertEqual(welfareAllowances.count, 1) // Education

        // Verify category assignments
        XCTAssertTrue(standardAllowances.allSatisfy { $0.category == "Standard" })
        XCTAssertTrue(specialAllowances.allSatisfy { $0.category == "Special" })
        XCTAssertTrue(variableAllowances.allSatisfy { $0.category == "Variable" })
        XCTAssertTrue(welfareAllowances.allSatisfy { $0.category == "Welfare" })
    }

    func testAllowance_AmountRanges_ByCategory_AreRealistic() {
        // Given - Realistic amount ranges for different categories
        let testCases = [
            // (name, amount, category, minExpected, maxExpected)
            ("Basic Pay", 35000.0, "Basic", 15000.0, 100000.0),
            ("House Rent Allowance", 15000.0, "Standard", 5000.0, 50000.0),
            ("Transport Allowance", 3000.0, "Standard", 1000.0, 20000.0),
            ("Medical Allowance", 5000.0, "Standard", 100.0, 15000.0),
            ("Special Allowance", 10000.0, "Special", 1000.0, 50000.0),
            ("Overtime Allowance", 5000.0, "Variable", 500.0, 25000.0),
            ("Education Allowance", 1000.0, "Welfare", 500.0, 5000.0),
            ("Mobile Allowance", 500.0, "Communication", 200.0, 2000.0),
            ("Fuel Allowance", 3000.0, "Transport", 1000.0, 15000.0)
        ]

        // When/Then
        for testCase in testCases {
            let allowance = Allowance(name: testCase.0, amount: testCase.1, category: testCase.2)

            XCTAssertGreaterThanOrEqual(allowance.amount, testCase.3,
                                      "\(testCase.0) amount \(allowance.amount) should be >= \(testCase.3)")
            XCTAssertLessThanOrEqual(allowance.amount, testCase.4,
                                   "\(testCase.0) amount \(allowance.amount) should be <= \(testCase.4)")
            XCTAssertEqual(allowance.category, testCase.2)
        }
    }

    // MARK: - Bulk Operations Tests

    func testAllowance_BulkCreation_PerformsEfficiently() {
        // Given
        let startTime = Date()

        // When - Create 100 allowances
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 100, baseName: "Bulk Test")

        // Then
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        XCTAssertEqual(allowances.count, 100)
        XCTAssertLessThan(duration, 1.0, "Bulk creation should complete in less than 1 second")

        // Verify all allowances are properly initialized
        for allowance in allowances {
            XCTAssertNotNil(allowance.id)
            XCTAssertTrue(allowance.name.hasPrefix("Bulk Test"))
            XCTAssertEqual(allowance.category, "Test")
            XCTAssertGreaterThanOrEqual(allowance.amount, 1000.0)
        }
    }

    func testAllowance_BulkPersistence_WorksCorrectly() throws {
        // Given
        let allowances = AllowanceTestHelpers.generateMultipleAllowances(count: 50)

        // When
        let startTime = Date()
        for allowance in allowances {
            try AllowanceTestHelpers.persistAllowance(allowance, in: modelContext)
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Then
        XCTAssertLessThan(duration, 5.0, "Bulk persistence should complete in less than 5 seconds")

        let fetchedAllowances = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
        XCTAssertEqual(fetchedAllowances.count, 50)

        // Verify all allowances were persisted correctly
        for originalAllowance in allowances {
            let fetchedAllowance = fetchedAllowances.first { $0.id == originalAllowance.id }
            XCTAssertNotNil(fetchedAllowance)
            XCTAssertEqual(fetchedAllowance?.name, originalAllowance.name)
            XCTAssertEqual(fetchedAllowance?.amount, originalAllowance.amount)
            XCTAssertEqual(fetchedAllowance?.category, originalAllowance.category)
        }
    }

    // MARK: - Real-world Scenarios

    func testAllowance_PayslipCalculation_IncludesAllComponents() {
        // Given - Complete payslip scenario
        let payslipComponents = [
            Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic"),
            Allowance(name: "Grade Pay", amount: 4200.0, category: "Basic"),
            Allowance(name: "Military Service Pay", amount: 2000.0, category: "Military"),
            Allowance(name: "Dearness Allowance", amount: 10500.0, category: "Standard"),
            Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard"),
            Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard"),
            Allowance(name: "Conveyance Allowance", amount: 19200.0, category: "Standard"),
            Allowance(name: "Dress Allowance", amount: 5000.0, category: "Special"),
            Allowance(name: "Medical Allowance", amount: 125.0, category: "Standard"),
            Allowance(name: "Washing Allowance", amount: 90.0, category: "Special"),
            Allowance(name: "CSD Allowance", amount: 300.0, category: "Special"),
            Allowance(name: "Special Allowance", amount: 10000.0, category: "Special")
        ]

        // When
        let grossEarnings = payslipComponents.reduce(0.0) { $0 + $1.amount }
        let basicComponents = payslipComponents.filter { $0.category == "Basic" }
        let standardComponents = payslipComponents.filter { $0.category == "Standard" }
        let specialComponents = payslipComponents.filter { $0.category == "Special" }
        let militaryComponents = payslipComponents.filter { $0.category == "Military" }

        // Then
        XCTAssertEqual(grossEarnings, 116115.0)

        // Verify component breakdowns
        XCTAssertEqual(basicComponents.count, 2) // Basic Pay + Grade Pay
        XCTAssertEqual(standardComponents.count, 6) // DA, HRA, TA, Conveyance, Medical
        XCTAssertEqual(specialComponents.count, 4) // Dress, Washing, CSD, Special
        XCTAssertEqual(militaryComponents.count, 1) // MSP

        // Verify amounts
        XCTAssertEqual(basicComponents.reduce(0.0) { $0 + $1.amount }, 39200.0)
        XCTAssertEqual(standardComponents.reduce(0.0) { $0 + $1.amount }, 59625.0)
        XCTAssertEqual(specialComponents.reduce(0.0) { $0 + $1.amount }, 15390.0)
        XCTAssertEqual(militaryComponents.reduce(0.0) { $0 + $1.amount }, 2000.0)
    }

    func testAllowance_SalaryRevision_Scenario() throws {
        // Given - Pre-revision allowances
        var basicPay = Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic")
        var houseRentAllowance = Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard")
        var transportAllowance = Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard")

        // Persist original values
        try AllowanceTestHelpers.persistAllowance(basicPay, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(houseRentAllowance, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(transportAllowance, in: modelContext)

        // When - Apply 10% revision
        let revisionPercentage = 0.10
        let originalTotal = basicPay.amount + houseRentAllowance.amount + transportAllowance.amount

        basicPay.amount *= (1 + revisionPercentage)
        houseRentAllowance.amount *= (1 + revisionPercentage)
        transportAllowance.amount *= (1 + revisionPercentage)

        // Update in database
        try AllowanceTestHelpers.updateAllowance(basicPay, amount: basicPay.amount, in: modelContext)
        try AllowanceTestHelpers.updateAllowance(houseRentAllowance, amount: houseRentAllowance.amount, in: modelContext)
        try AllowanceTestHelpers.updateAllowance(transportAllowance, amount: transportAllowance.amount, in: modelContext)

        // Then
        let revisedTotal = basicPay.amount + houseRentAllowance.amount + transportAllowance.amount
        let expectedIncrease = originalTotal * revisionPercentage

        XCTAssertEqual(revisedTotal, originalTotal + expectedIncrease, accuracy: 0.01)
        XCTAssertEqual(basicPay.amount, 38500.0, accuracy: 0.01)
        XCTAssertEqual(houseRentAllowance.amount, 11550.0, accuracy: 0.01)
        XCTAssertEqual(transportAllowance.amount, 21120.0, accuracy: 0.01)

        // Verify persistence
        let fetchedBasicPay = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
            .first { $0.name == "Basic Pay" }
        XCTAssertEqual(fetchedBasicPay?.amount, 38500.0, accuracy: 0.01)
    }

    func testAllowance_ArrearCalculation_WorksCorrectly() {
        // Given - Arrear calculation for 3 months
        let monthlyAllowance = Allowance(name: "House Rent Allowance", amount: 15000.0, category: "Standard")
        let months = 3

        // When
        let totalArrear = monthlyAllowance.amount * Double(months)

        // Then
        XCTAssertEqual(totalArrear, 45000.0)
        XCTAssertEqual(monthlyAllowance.amount, 15000.0)
        XCTAssertEqual(monthlyAllowance.category, "Standard")
    }
}

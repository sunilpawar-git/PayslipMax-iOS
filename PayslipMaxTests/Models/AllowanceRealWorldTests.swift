import XCTest
import SwiftData
@testable import PayslipMax

/// Real-world scenario tests for Allowance model
class AllowanceRealWorldTests: AllowanceTestCase {

    // MARK: - Real-world Scenarios

    func testAllowance_PayslipCalculation_IncludesAllComponents() {
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

        let grossEarnings = payslipComponents.reduce(0.0) { $0 + $1.amount }
        let basicComponents = payslipComponents.filter { $0.category == "Basic" }
        let standardComponents = payslipComponents.filter { $0.category == "Standard" }
        let specialComponents = payslipComponents.filter { $0.category == "Special" }
        let militaryComponents = payslipComponents.filter { $0.category == "Military" }

        XCTAssertEqual(grossEarnings, 116115.0)
        XCTAssertEqual(basicComponents.count, 2)
        XCTAssertEqual(standardComponents.count, 5)
        XCTAssertEqual(specialComponents.count, 4)
        XCTAssertEqual(militaryComponents.count, 1)

        XCTAssertEqual(basicComponents.reduce(0.0) { $0 + $1.amount }, 39200.0)
        XCTAssertEqual(standardComponents.reduce(0.0) { $0 + $1.amount }, 59525.0)
        XCTAssertEqual(specialComponents.reduce(0.0) { $0 + $1.amount }, 15390.0)
        XCTAssertEqual(militaryComponents.reduce(0.0) { $0 + $1.amount }, 2000.0)
    }

    func testAllowance_SalaryRevision_Scenario() throws {
        let basicPay = Allowance(name: "Basic Pay", amount: 35000.0, category: "Basic")
        let houseRentAllowance = Allowance(name: "House Rent Allowance", amount: 10500.0, category: "Standard")
        let transportAllowance = Allowance(name: "Transport Allowance", amount: 19200.0, category: "Standard")

        try AllowanceTestHelpers.persistAllowance(basicPay, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(houseRentAllowance, in: modelContext)
        try AllowanceTestHelpers.persistAllowance(transportAllowance, in: modelContext)

        let revisionPercentage = 0.10
        let originalTotal = basicPay.amount + houseRentAllowance.amount + transportAllowance.amount

        basicPay.amount *= (1 + revisionPercentage)
        houseRentAllowance.amount *= (1 + revisionPercentage)
        transportAllowance.amount *= (1 + revisionPercentage)

        try AllowanceTestHelpers.updateAllowance(basicPay, amount: basicPay.amount, in: modelContext)
        try AllowanceTestHelpers.updateAllowance(
            houseRentAllowance,
            amount: houseRentAllowance.amount,
            in: modelContext
        )
        try AllowanceTestHelpers.updateAllowance(
            transportAllowance,
            amount: transportAllowance.amount,
            in: modelContext
        )

        let revisedTotal = basicPay.amount + houseRentAllowance.amount + transportAllowance.amount
        let expectedIncrease = originalTotal * revisionPercentage

        XCTAssertEqual(revisedTotal, originalTotal + expectedIncrease, accuracy: 0.01)
        XCTAssertEqual(basicPay.amount, 38500.0, accuracy: 0.01)
        XCTAssertEqual(houseRentAllowance.amount, 11550.0, accuracy: 0.01)
        XCTAssertEqual(transportAllowance.amount, 21120.0, accuracy: 0.01)

        let fetchedBasicPay = try AllowanceTestHelpers.fetchAllAllowances(from: modelContext)
            .first { $0.name == "Basic Pay" }
        XCTAssertNotNil(fetchedBasicPay)
        XCTAssertEqual(fetchedBasicPay!.amount, 38500.0, accuracy: 0.01)
    }

    func testAllowance_ArrearCalculation_WorksCorrectly() {
        let monthlyAllowance = Allowance(name: "House Rent Allowance", amount: 15000.0, category: "Standard")
        let months = 3

        let totalArrear = monthlyAllowance.amount * Double(months)

        XCTAssertEqual(totalArrear, 45000.0)
        XCTAssertEqual(monthlyAllowance.amount, 15000.0)
        XCTAssertEqual(monthlyAllowance.category, "Standard")
    }
}


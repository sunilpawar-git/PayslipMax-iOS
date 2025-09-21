//
//  PayslipDataComputedPropertiesTests.swift
//  PayslipMaxTests
//
//  Tests for computed properties and derived field calculations
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import XCTest
@testable import PayslipMax

final class PayslipDataComputedPropertiesTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    // MARK: - Computed Properties Validation

    func testCalculateDerivedFieldsWithDualSection() {
        // Test calculateDerivedFields method with dual-section data
        var payslipData = PayslipDataTestHelpers.createEmptyPayslipData()

        // Set up complex dual-section earnings and deductions
        payslipData.allEarnings = [
            "BPAY": 50000.0,
            "DA_EARNINGS": 15000.0,
            "HRA_EARNINGS": 12000.0,
            "RH12_EARNINGS": 21125.0
        ]

        payslipData.allDeductions = [
            "AGIF": 2000.0,
            "DSOP": 5000.0,
            "HRA_DEDUCTIONS": 5000.0,
            "RH12_DEDUCTIONS": 7518.0
        ]

        // Calculate derived fields
        payslipData.calculateDerivedFields()

        // Verify totals are calculated correctly
        XCTAssertEqual(payslipData.totalCredits, 98125.0, "Total credits should sum all earnings including dual-section")
        XCTAssertEqual(payslipData.totalDebits, 19518.0, "Total debits should sum all deductions including dual-section")
        XCTAssertEqual(payslipData.netRemittance, 78607.0, "Net remittance should be correct with dual-section processing")

        // Verify protocol properties are updated
        XCTAssertEqual(payslipData.credits, payslipData.totalCredits, "Credits should match totalCredits")
        XCTAssertEqual(payslipData.debits, payslipData.totalDebits, "Debits should match totalDebits")
    }

    func testNetIncomeCalculationWithDualSection() {
        // Test netIncome computed property with dual-section data
        var payslipData = PayslipDataTestHelpers.createPayslipDataWithDualSectionTotals()

        // Calculate derived fields to ensure credits/debits are set properly
        payslipData.calculateDerivedFields()

        let expectedNetIncome = payslipData.totalCredits - payslipData.totalDebits
        XCTAssertEqual(payslipData.netIncome, expectedNetIncome, "NetIncome should calculate correctly with dual-section data")
        XCTAssertEqual(payslipData.calculateNetAmount(), expectedNetIncome, "calculateNetAmount should match netIncome")
        XCTAssertEqual(payslipData.getNetAmount(), expectedNetIncome, "getNetAmount should match netIncome")
    }
}

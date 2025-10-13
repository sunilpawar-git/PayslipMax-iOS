//
//  PayslipDataDualSectionTests.swift
//  PayslipMaxTests
//
//  Tests for dual-section key compatibility and universal value retrieval
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import XCTest
@testable import PayslipMax

final class PayslipDataDualSectionTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    // MARK: - Universal Dual-Section Key Tests

    func testPayslipDataFactoryWithDualSectionKeys() {
        // Test dual-section key compatibility from roadmap examples
        let mockPayslip = PayslipDataTestHelpers.createMockPayslipWithDualSectionKeys()
        let payslipData = PayslipData(from: mockPayslip)

        // Verify dual-section components are handled correctly
        XCTAssertEqual(payslipData.dearnessPay, 25000.0, "DA should combine DA_EARNINGS + legacy DA")
        XCTAssertEqual(payslipData.agif, 2000.0, "AGIF should be retrieved correctly")

        // Verify computed properties work with dual-section data
        let expectedNetAmount = mockPayslip.credits - mockPayslip.debits
        let actualNetAmount = payslipData.calculateNetAmount()
        XCTAssertEqual(actualNetAmount, expectedNetAmount, "Net amount calculation should work with dual-section (expected: \(expectedNetAmount), actual: \(actualNetAmount))")

        // Verify allEarnings includes dual-section keys
        XCTAssertEqual(payslipData.allEarnings["DA_EARNINGS"], 15000.0, "allEarnings should contain dual-section earnings keys")
        XCTAssertEqual(payslipData.allDeductions["HRA_DEDUCTIONS"], 5000.0, "allDeductions should contain dual-section deductions keys")
    }

    func testUniversalDualSectionValueRetrieval() {
        // Test the enhanced dual-key retrieval system
        let mockPayslip = PayslipDataTestHelpers.createComplexDualSectionPayslip()
        let payslipData = PayslipData(from: mockPayslip)

        // Test HRA dual-section handling (earnings and recovery scenarios)
        XCTAssertTrue(payslipData.allEarnings.keys.contains("HRA_EARNINGS") || payslipData.allDeductions.keys.contains("HRA_DEDUCTIONS"),
                      "HRA dual-section keys should be preserved in PayslipData")

        // Test RH12 absolute value calculation
        XCTAssertTrue(payslipData.allEarnings["RH12_EARNINGS"] != nil || payslipData.allDeductions["RH12_DEDUCTIONS"] != nil,
                      "RH12 dual-section keys should be preserved")
    }

    func testArrearsWithDualSectionKeys() {
        // Test arrears components with dual-section support
        let mockPayslip = PayslipDataTestHelpers.createMockPayslipWithArrearsComponents()
        let payslipData = PayslipData(from: mockPayslip)

        // Verify arrears dual-section keys are preserved
        XCTAssertEqual(payslipData.allEarnings["ARR-HRA_EARNINGS"], 1650.0, "Arrears earnings should be preserved")
        XCTAssertEqual(payslipData.allDeductions["ARR-CEA_DEDUCTIONS"], 2000.0, "Arrears deductions should be preserved")

        // Verify totals include arrears components
        let totalEarnings = payslipData.allEarnings.values.reduce(0, +)
        let totalDeductions = payslipData.allDeductions.values.reduce(0, +)
        XCTAssertEqual(totalEarnings, payslipData.totalCredits, "Total earnings should match credits")
        XCTAssertEqual(totalDeductions, payslipData.totalDebits, "Total deductions should match debits")
    }
}

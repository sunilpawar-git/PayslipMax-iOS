//
//  PayslipSanityCheckValidatorTests.swift
//  PayslipMaxTests
//
//  Tests for sanity check validation logic
//

import XCTest
@testable import PayslipMax

final class PayslipSanityCheckValidatorTests: XCTestCase {
    var validator: PayslipSanityCheckValidator!

    override func setUp() {
        super.setUp()
        validator = PayslipSanityCheckValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Valid Payslip Tests

    func testValidPayslip_NoIssues() {
        // Given: A well-formed payslip
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000, "DA": 24200, "MSP": 5200],
            deductions: ["DSOP": 2220, "AGIF": 3396, "ITAX": 15585],
            grossPay: 86953,
            totalDeductions: 21201,
            netRemittance: 65752,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: No issues should be found
        XCTAssertEqual(result.severity, SanityCheckSeverity.none)
        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertEqual(result.confidenceAdjustment, 0.0)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Deductions Exceed Earnings Tests

    func testDeductionsExceedEarnings_CriticalIssue() {
        // Given: Deductions > Earnings (impossible!)
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: ["Loans & Advances": 86953, "ITAX": 15585], // Total: 102538
            grossPay: 86953,
            totalDeductions: 102538,
            netRemittance: -15585,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Critical issue should be detected
        XCTAssertEqual(result.severity, SanityCheckSeverity.critical)
        XCTAssertFalse(result.issues.isEmpty)
        XCTAssertTrue(result.confidenceAdjustment < -0.3)
        XCTAssertFalse(result.isValid)

        // Verify specific issue
        let hasDeductionsExceedError = result.issues.contains { $0.code == "DEDUCTIONS_EXCEED_EARNINGS" }
        XCTAssertTrue(hasDeductionsExceedError, "Should detect deductions exceeding earnings")
    }

    // MARK: - Net Reconciliation Tests

    func testNetReconciliation_MinorError() {
        // Given: Small net reconciliation error (2%)
        let gross: Double = 86953
        let deductions: Double = 21201
        let expectedNet = gross - deductions // 65752
        let actualNet: Double = 65000 // Off by 752 (~1.15%)

        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: ["DSOP": 2220],
            grossPay: gross,
            totalDeductions: deductions,
            netRemittance: actualNet,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Minor issue should be detected
        XCTAssertEqual(result.severity, SanityCheckSeverity.minor)
        XCTAssertFalse(result.issues.isEmpty)

        let hasNetError = result.issues.contains { $0.code == "NET_RECONCILIATION_MINOR" }
        XCTAssertTrue(hasNetError, "Should detect minor net reconciliation error")
    }

    func testNetReconciliation_MajorError() {
        // Given: Large net reconciliation error (10%)
        let gross: Double = 86953
        let deductions: Double = 21201
        let actualNet: Double = 50000 // Way off

        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: ["DSOP": 2220],
            grossPay: gross,
            totalDeductions: deductions,
            netRemittance: actualNet,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Warning should be detected
        XCTAssertEqual(result.severity, SanityCheckSeverity.warning)

        let hasNetError = result.issues.contains { $0.code == "NET_RECONCILIATION_FAILED" }
        XCTAssertTrue(hasNetError, "Should detect major net reconciliation error")
    }

    // MARK: - Suspicious Keys Tests

    func testSuspiciousDeductionKeys_Detected() {
        // Given: Deductions with suspicious keywords
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: [
                "Loans & Advances": 86953,  // Suspicious: "advance"
                "Credit Balance Released": 58252,  // Suspicious: "balance", "released"
                "AFPP Fund Refund": 7500,  // Suspicious: "refund"
                "DSOP": 2220  // Valid
            ],
            grossPay: 37000,
            totalDeductions: 20000,
            netRemittance: 17000,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Multiple suspicious keys should be detected
        let suspiciousKeyIssues = result.issues.filter { $0.code == "SUSPICIOUS_DEDUCTION_KEY" }
        XCTAssertEqual(suspiciousKeyIssues.count, 3, "Should detect 3 suspicious deduction keys")

        // Verify confidence penalty is applied
        XCTAssertTrue(result.confidenceAdjustment < -0.4, "Should apply significant penalty for multiple suspicious keys")
    }

    // MARK: - Totals Mismatch Tests

    func testEarningsTotalMismatch_Warning() {
        // Given: Sum of earnings doesn't match gross pay
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000, "DA": 24200], // Sum: 61200
            deductions: ["DSOP": 2220],
            grossPay: 86953, // Doesn't match sum (off by ~30%)
            totalDeductions: 2220,
            netRemittance: 84733,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Warning should be detected
        XCTAssertTrue(result.hasConcerns)
        let hasMismatch = result.issues.contains { $0.code == "EARNINGS_TOTAL_MISMATCH" }
        XCTAssertTrue(hasMismatch, "Should detect earnings total mismatch")
    }

    // MARK: - Mandatory Components Tests

    func testMissingBPAY_MinorIssue() {
        // Given: Payslip without BPAY (basic pay)
        let response = LLMPayslipResponse(
            earnings: ["DA": 24200, "MSP": 5200], // No BPAY
            deductions: ["DSOP": 2220],
            grossPay: 29400,
            totalDeductions: 2220,
            netRemittance: 27180,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Minor issue should be detected
        XCTAssertTrue(result.hasConcerns)
        let hasMissingBPAY = result.issues.contains { $0.code == "MISSING_BPAY" }
        XCTAssertTrue(hasMissingBPAY, "Should detect missing BPAY")
    }

    // MARK: - Value Range Tests

    func testGrossPayTooLow_MinorIssue() {
        // Given: Unusually low gross pay
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 5000],
            deductions: ["DSOP": 500],
            grossPay: 5000,
            totalDeductions: 500,
            netRemittance: 4500,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Warning about low gross pay
        let hasLowGrossPay = result.issues.contains { $0.code == "GROSS_PAY_TOO_LOW" }
        XCTAssertTrue(hasLowGrossPay, "Should detect unusually low gross pay")
    }

    func testNegativeNetPay_CriticalIssue() {
        // Given: Negative net remittance
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: ["DSOP": 50000],
            grossPay: 37000,
            totalDeductions: 50000,
            netRemittance: -13000,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Critical issue
        XCTAssertEqual(result.severity, SanityCheckSeverity.critical)
        let hasNegativeNet = result.issues.contains { $0.code == "NEGATIVE_NET_PAY" }
        XCTAssertTrue(hasNegativeNet, "Should detect negative net pay")
    }

    // MARK: - Edge Cases

    func testEmptyEarningsAndDeductions_HandledGracefully() {
        // Given: Empty earnings and deductions
        let response = LLMPayslipResponse(
            earnings: [:],
            deductions: [:],
            grossPay: 0,
            totalDeductions: 0,
            netRemittance: 0,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Should handle gracefully without crashes
        XCTAssertNotNil(result)
        // May have issues but shouldn't crash
    }

    func testNilValues_HandledGracefully() {
        // Given: Response with nil values
        let response = LLMPayslipResponse(
            earnings: nil,
            deductions: nil,
            grossPay: nil,
            totalDeductions: nil,
            netRemittance: nil,
            month: nil,
            year: nil
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Should handle gracefully
        XCTAssertNotNil(result)
    }
}

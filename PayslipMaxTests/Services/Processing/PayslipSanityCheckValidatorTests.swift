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
        // Given: A well-formed payslip where:
        // - Sum of earnings = grossPay (within 5%)
        // - totalDeductions = grossPay - netRemittance
        // - grossPay - totalDeductions = netRemittance (fundamental equation)
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 56553, "DA": 24200, "MSP": 6200],  // Sum = 86953
            deductions: ["DSOP": 2220, "AGIF": 3396, "ITAX": 15585],  // Sum = 21201
            grossPay: 86953,
            totalDeductions: 21201,
            netRemittance: 65752,  // 86953 - 21201 = 65752 ✓
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: No issues should be found
        XCTAssertEqual(result.severity, SanityCheckSeverity.none)
        XCTAssertTrue(result.issues.isEmpty, "Expected no issues but got: \(result.issues.map { $0.code })")
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
        // Given: Net reconciliation error of ~2% (triggers >1% threshold)
        let gross: Double = 86953
        let deductions: Double = 21201
        _ = gross - deductions  // 65752 (expectedNet)
        let actualNet: Double = 64000  // Off by 1752 (~2.7%)

        let response = LLMPayslipResponse(
            earnings: ["BPAY": 86953],  // Match grossPay
            deductions: ["DSOP": 21201],  // Match totalDeductions
            grossPay: gross,
            totalDeductions: deductions,
            netRemittance: actualNet,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Should detect net reconciliation issue (>1% error)
        XCTAssertFalse(result.issues.isEmpty, "Should have issues for 2.7% reconciliation error")

        // FUNDAMENTAL_EQUATION_FAILED triggers for >1% error (warning for 1-5%)
        let hasFundamentalError = result.issues.contains { $0.code == "FUNDAMENTAL_EQUATION_FAILED" }
        XCTAssertTrue(hasFundamentalError, "Should detect fundamental equation error")
    }

    func testNetReconciliation_MajorError() {
        // Given: Large net reconciliation error (>5% triggers critical)
        let gross: Double = 86953
        let deductions: Double = 21201
        let actualNet: Double = 50000 // Way off - expected 65752

        let response = LLMPayslipResponse(
            earnings: ["BPAY": 86953],  // Match grossPay
            deductions: ["DSOP": 21201],  // Match totalDeductions
            grossPay: gross,
            totalDeductions: deductions,
            netRemittance: actualNet,
            month: "AUGUST",
            year: 2025
        )

        // When: Validating
        let result = validator.validate(response)

        // Then: Critical issue detected (>5% fundamental equation error)
        XCTAssertEqual(result.severity, SanityCheckSeverity.critical)

        // FUNDAMENTAL_EQUATION_FAILED triggers (critical for >5%)
        let hasFundamentalError = result.issues.contains { $0.code == "FUNDAMENTAL_EQUATION_FAILED" }
        XCTAssertTrue(hasFundamentalError, "Should detect fundamental equation error")
    }

    // MARK: - Suspicious Keys Tests

    func testSuspiciousDeductionKeys_Detected() {
        // Given: Deductions with suspicious keywords
        // Suspicious keywords must match exactly (case-insensitive):
        // "credit balance released", "balance released", "credited to bank", "net pay", etc.
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: [
                "Credit Balance Released": 58252,  // Suspicious: matches "credit balance released"
                "Amount Credited to Bank": 7500,  // Suspicious: matches "credited to bank"
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

        // Then: Suspicious keys should be detected
        let suspiciousKeyIssues = result.issues.filter { $0.code == "SUSPICIOUS_DEDUCTION_KEY" }
        XCTAssertGreaterThanOrEqual(suspiciousKeyIssues.count, 2, "Should detect suspicious deduction keys")

        // Verify some confidence penalty is applied
        XCTAssertTrue(result.confidenceAdjustment < -0.2, "Should apply penalty for suspicious keys")
    }

}

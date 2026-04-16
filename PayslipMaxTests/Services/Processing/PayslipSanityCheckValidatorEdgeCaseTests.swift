import XCTest
@testable import PayslipMax

final class PayslipSanityCheckValidatorEdgeCaseTests: XCTestCase {
    var validator: PayslipSanityCheckValidator!

    override func setUp() {
        super.setUp()
        validator = PayslipSanityCheckValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Totals Mismatch Tests

    func testEarningsTotalMismatch_Warning() {
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000, "DA": 24200], // Sum: 61200
            deductions: ["DSOP": 2220],
            grossPay: 86953,
            totalDeductions: 2220,
            netRemittance: 84733,
            month: "AUGUST",
            year: 2025
        )

        let result = validator.validate(response)

        XCTAssertTrue(result.hasConcerns)
        let hasMismatch = result.issues.contains { $0.code == "EARNINGS_SUM_MISMATCH" }
        XCTAssertTrue(hasMismatch, "Should detect earnings sum mismatch")
    }

    // MARK: - Mandatory Components Tests

    func testMissingBPAY_MinorIssue() {
        let response = LLMPayslipResponse(
            earnings: ["DA": 24200, "MSP": 5200],
            deductions: ["DSOP": 2220],
            grossPay: 29400,
            totalDeductions: 2220,
            netRemittance: 27180,
            month: "AUGUST",
            year: 2025
        )

        let result = validator.validate(response)

        XCTAssertTrue(result.hasConcerns)
        let hasMissingBPAY = result.issues.contains { $0.code == "MISSING_BPAY" }
        XCTAssertTrue(hasMissingBPAY, "Should detect missing BPAY")
    }

    // MARK: - Value Range Tests

    func testGrossPayTooLow_MinorIssue() {
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 5000],
            deductions: ["DSOP": 500],
            grossPay: 5000,
            totalDeductions: 500,
            netRemittance: 4500,
            month: "AUGUST",
            year: 2025
        )

        let result = validator.validate(response)

        let hasLowGrossPay = result.issues.contains { $0.code == "GROSS_PAY_TOO_LOW" }
        XCTAssertTrue(hasLowGrossPay, "Should detect unusually low gross pay")
    }

    func testNegativeNetPay_CriticalIssue() {
        let response = LLMPayslipResponse(
            earnings: ["BPAY": 37000],
            deductions: ["DSOP": 50000],
            grossPay: 37000,
            totalDeductions: 50000,
            netRemittance: -13000,
            month: "AUGUST",
            year: 2025
        )

        let result = validator.validate(response)

        XCTAssertEqual(result.severity, SanityCheckSeverity.critical)
        let hasNegativeNet = result.issues.contains { $0.code == "NEGATIVE_NET_PAY" }
        XCTAssertTrue(hasNegativeNet, "Should detect negative net pay")
    }

    // MARK: - Edge Cases

    func testEmptyEarningsAndDeductions_HandledGracefully() {
        let response = LLMPayslipResponse(
            earnings: [:],
            deductions: [:],
            grossPay: 0,
            totalDeductions: 0,
            netRemittance: 0,
            month: "AUGUST",
            year: 2025
        )

        let result = validator.validate(response)

        XCTAssertNotNil(result)
    }

    func testNilValues_HandledGracefully() {
        let response = LLMPayslipResponse(
            earnings: nil,
            deductions: nil,
            grossPay: nil,
            totalDeductions: nil,
            netRemittance: nil,
            month: nil,
            year: nil
        )

        let result = validator.validate(response)

        XCTAssertNotNil(result)
    }
}

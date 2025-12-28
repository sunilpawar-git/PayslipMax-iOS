import XCTest
@testable import PayslipMax

/// Tests for ConfidenceCalculator
/// Validates confidence scoring algorithm for parsed payslip data
///
/// Additional tests in extensions:
/// - ConfidenceCalculatorTests+ValidationTests.swift (Validation, Edge Cases, Confidence Levels)
final class ConfidenceCalculatorTests: XCTestCase {

    var calculator: ConfidenceCalculator!

    override func setUp() {
        super.setUp()
        calculator = ConfidenceCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    func makeInput(
        basicPay: Double = 0,
        dearnessAllowance: Double = 0,
        militaryServicePay: Double = 0,
        grossPay: Double = 0,
        dsop: Double = 0,
        agif: Double = 0,
        incomeTax: Double = 0,
        totalDeductions: Double = 0,
        netRemittance: Double = 0
    ) -> ConfidenceInput {
        ConfidenceInput(
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        )
    }

    // MARK: - Perfect Data Tests

    func testPerfectDataReturnsHighConfidence() async {
        // Perfect data where all validations pass
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 248310,
            dsop: 40000,
            agif: 12500,
            incomeTax: 47624,
            totalDeductions: 100124,
            netRemittance: 148186
        )
        let result = await calculator.calculate(input)

        XCTAssertEqual(result.overall, 1.0, "Perfect data should have 100% confidence")
        XCTAssertEqual(result.methodology, "Simplified", "Should use Simplified methodology")
        XCTAssertFalse(result.fieldLevel.isEmpty, "Should have field-level breakdown")
    }

    func testConfidenceCalculation_AllTotalsCorrect() async {
        // Given: May 2025 payslip data with "Other Earnings"
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 168140
        )
        let result = await calculator.calculate(input)

        // Then: Should be 100% (not 80%)
        XCTAssertEqual(result.overall, 1.0, "Confidence should be 100% when all totals are correct")
    }

    func testConfidenceCalculation_LargeOtherEarnings() async {
        // Given: Large "Other Earnings" (₹28,355)
        // BPAY + DA + MSP = ₹248,310, but Gross = ₹276,665
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 168140
        )
        let result = await calculator.calculate(input)

        // Then: Should NOT be penalized for large "Other Earnings"
        XCTAssertEqual(result.overall, 1.0, "Should not penalize for large Other Earnings")
    }

    func testConfidenceCalculation_PerfectAccuracy() async {
        // Given: All fields perfect (August 2025 data)
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 275015,
            dsop: 40000,
            agif: 12500,
            incomeTax: 47624,
            totalDeductions: 102029,
            netRemittance: 172986
        )
        let result = await calculator.calculate(input)

        // Then: 100% confidence
        XCTAssertEqual(result.overall, 1.0, "Perfect accuracy should give 100%")
    }
}

import XCTest
@testable import PayslipMax

/// Tests for ConfidenceCalculator
/// Validates confidence scoring algorithm for parsed payslip data
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

    private func makeInput(
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

    // MARK: - Validation Tests

    func testConfidenceCalculation_NetMismatch() async {
        // Given: Net Remittance doesn't match calculation
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 165000
        )
        let result = await calculator.calculate(input)

        // Then: Confidence should drop to 90% (±5% tolerance)
        XCTAssertEqual(
            result.overall, 0.90, accuracy: 0.01,
            "Confidence should be 90% for 1.9% net mismatch"
        )
    }

    func testConfidenceCalculation_MissingGrossPay() async {
        // Given: Gross Pay not extracted
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 0,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 168140
        )
        let result = await calculator.calculate(input)

        // Then: Confidence should be low (30%)
        XCTAssertLessThanOrEqual(result.overall, 0.40, "Confidence should be low without Gross Pay")
    }

    func testConfidenceCalculation_OnlyCoreFieldsNoTotals() async {
        // Given: Only core fields, no totals
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 0,
            dsop: 40000,
            agif: 12500,
            incomeTax: 0,
            totalDeductions: 0,
            netRemittance: 0
        )
        let result = await calculator.calculate(input)

        // Then: Should get 10% for core fields only
        XCTAssertEqual(result.overall, 0.10, accuracy: 0.01, "Only core fields should give 10%")
    }

    func testNetRemittanceValidation() async {
        // Test with correct net remittance
        let validInput = makeInput(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 105000
        )
        let validResult = await calculator.calculate(validInput)

        // Test with incorrect net remittance
        let invalidInput = makeInput(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 150000
        )
        let invalidResult = await calculator.calculate(invalidInput)

        XCTAssertGreaterThan(
            validResult.overall, invalidResult.overall,
            "Valid net remittance should have higher confidence"
        )
    }

    // MARK: - Missing Data Tests

    func testMissingCoreFieldsLowersConfidence() async {
        // All fields present - should get 100%
        let fullInput = makeInput(
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
        let fullResult = await calculator.calculate(fullInput)

        // Missing DA and AGIF - should still get 100% if totals are correct
        let partialInput = makeInput(
            basicPay: 144700,
            dearnessAllowance: 0,
            militaryServicePay: 15500,
            grossPay: 160200,
            dsop: 40000,
            agif: 0,
            incomeTax: 47624,
            totalDeductions: 87624,
            netRemittance: 72576
        )
        let partialResult = await calculator.calculate(partialInput)

        // Both should be 100% because totals are correct in both cases
        XCTAssertEqual(
            fullResult.overall, 1.0,
            "All fields present with correct totals should be 100%"
        )
        XCTAssertEqual(
            partialResult.overall, 1.0,
            "Missing some fields but correct totals should still be 100%"
        )
    }

    // MARK: - Edge Case Tests

    func testConfidenceCalculation_NetMath10PercentOff() async {
        // Given: Net is off by ~10%
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 152000
        )
        let result = await calculator.calculate(input)

        // Then: Should get 70% (20+20+20+10) for ±10% tolerance
        XCTAssertEqual(result.overall, 0.70, accuracy: 0.01, "Should get 70% for ~10% net mismatch")
    }

    func testConfidenceCalculation_NetMathSeverelyOff() async {
        // Given: Net is off by >10%
        let input = makeInput(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 140000
        )
        let result = await calculator.calculate(input)

        // Then: Should lose net remittance points
        XCTAssertLessThanOrEqual(result.overall, 0.50, "Should be ≤50% for >10% net mismatch")
    }

    // MARK: - Confidence Level Helper Tests

    func testConfidenceLevels() {
        XCTAssertEqual(ConfidenceCalculator.confidenceLevel(for: 0.95), .excellent)
        XCTAssertEqual(ConfidenceCalculator.confidenceLevel(for: 0.82), .good)
        XCTAssertEqual(ConfidenceCalculator.confidenceLevel(for: 0.65), .reviewRecommended)
        XCTAssertEqual(ConfidenceCalculator.confidenceLevel(for: 0.35), .manualVerificationRequired)
    }

    func testConfidenceColors() {
        XCTAssertEqual(ConfidenceCalculator.confidenceColor(for: 0.95), "green")
        XCTAssertEqual(ConfidenceCalculator.confidenceColor(for: 0.82), "yellow")
        XCTAssertEqual(ConfidenceCalculator.confidenceColor(for: 0.65), "orange")
        XCTAssertEqual(ConfidenceCalculator.confidenceColor(for: 0.35), "red")
    }
}

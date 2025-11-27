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

    // MARK: - Perfect Data Tests

    func testPerfectDataReturnsHighConfidence() async {
        // Perfect data where all validations pass
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 248310, // Exactly BPAY + DA + MSP
            dsop: 40000,
            agif: 12500,
            incomeTax: 47624,
            totalDeductions: 100124, // Exactly DSOP + AGIF + Tax
            netRemittance: 148186 // Exactly Gross - Total
        )

        XCTAssertEqual(result.overall, 1.0, "Perfect data should have 100% confidence")
        XCTAssertEqual(result.methodology, "Simplified", "Should use Simplified methodology")
        XCTAssertFalse(result.fieldLevel.isEmpty, "Should have field-level breakdown")
    }

    func testConfidenceCalculation_AllTotalsCorrect() async {
        // Given: May 2025 payslip data with "Other Earnings"
        let result = await calculator.calculate(
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

        // Then: Should be 100% (not 80%)
        XCTAssertEqual(result.overall, 1.0, "Confidence should be 100% when all totals are correct")
    }

    func testConfidenceCalculation_LargeOtherEarnings() async {
        // Given: Large "Other Earnings" (₹28,355)
        // BPAY + DA + MSP = ₹248,310, but Gross = ₹276,665
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,  // 89.7% of breakdown
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 168140
        )

        // Then: Should NOT be penalized for large "Other Earnings"
        XCTAssertEqual(result.overall, 1.0, "Should not penalize for large Other Earnings")
    }

    func testConfidenceCalculation_PerfectAccuracy() async {
        // Given: All fields perfect (August 2025 data)
        let result = await calculator.calculate(
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

        // Then: 100% confidence
        XCTAssertEqual(result.overall, 1.0, "Perfect accuracy should give 100%")
    }

    // MARK: - Validation Tests

    func testConfidenceCalculation_NetMismatch() async {
        // Given: Net Remittance doesn't match calculation
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 165000  // Wrong! Should be 168,140 (1.9% off)
        )

        // Then: Confidence should drop to 90% (±5% tolerance)
        XCTAssertEqual(result.overall, 0.90, accuracy: 0.01, "Confidence should be 90% for 1.9% net mismatch")
    }

    func testConfidenceCalculation_MissingGrossPay() async {
        // Given: Gross Pay not extracted
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 0,  // Missing!
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 168140
        )

        // Then: Confidence should be low (30%)
        XCTAssertLessThanOrEqual(result.overall, 0.40, "Confidence should be low without Gross Pay")
    }

    func testConfidenceCalculation_OnlyCoreFieldsNoTotals() async {
        // Given: Only core fields, no totals
        let result = await calculator.calculate(
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

        // Then: Should get 10% for core fields only
        XCTAssertEqual(result.overall, 0.10, accuracy: 0.01, "Only core fields should give 10%")
    }

    func testNetRemittanceValidation() async {
        // Test with correct net remittance
        let validResult = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 105000 // 165000 - 60000
        )

        // Test with incorrect net remittance
        let invalidResult = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 150000 // Wrong
        )

        XCTAssertGreaterThan(validResult.overall, invalidResult.overall, "Valid net remittance should have higher confidence")
    }

    // MARK: - Missing Data Tests
    
    func testMissingCoreFieldsLowersConfidence() async {
        // All fields present - should get 100%
        let fullResult = await calculator.calculate(
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

        // Missing DA and AGIF - should still get 100% if totals are correct
        // Under new logic: totals accuracy matters, not field granularity
        let partialResult = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 0, // Missing
            militaryServicePay: 15500,
            grossPay: 160200,
            dsop: 40000,
            agif: 0, // Missing
            incomeTax: 47624,
            totalDeductions: 87624,
            netRemittance: 72576
        )

        // Both should be 100% because totals are correct in both cases
        // Only difference: fullResult has 5/5 core fields, partialResult has 3/5
        // But core fields only contribute 10% max, and both have ≥3 fields
        XCTAssertEqual(fullResult.overall, 1.0, "All fields present with correct totals should be 100%")
        XCTAssertEqual(partialResult.overall, 1.0, "Missing some fields but correct totals should still be 100%")
    }

    // MARK: - Edge Case Tests

    func testConfidenceCalculation_NetMath10PercentOff() async {
        // Given: Net is off by ~10%
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 152000  // Should be 168,140 (9.6% off)
        )

        // Then: Should get 70% (20+20+20+10) for ±10% tolerance
        // Check 1: Gross Pay = 0.20, Check 2: Deductions = 0.20
        // Check 3: Net within ±10% = 0.20, Check 4: Core fields = 0.10
        XCTAssertEqual(result.overall, 0.70, accuracy: 0.01, "Should get 70% for ~10% net mismatch")
    }

    func testConfidenceCalculation_NetMathSeverelyOff() async {
        // Given: Net is off by >10%
        let result = await calculator.calculate(
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            grossPay: 276665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 46641,
            totalDeductions: 108525,
            netRemittance: 140000  // Should be 168,140 (16.7% off)
        )

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


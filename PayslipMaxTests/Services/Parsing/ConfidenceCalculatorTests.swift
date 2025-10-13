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
        let score = await calculator.calculate(
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
        
        XCTAssertGreaterThan(score, 0.95, "Perfect data should have >95% confidence")
    }
    
    // MARK: - Validation Tests
    
    func testGrossPayValidation() async {
        // Test with correct gross pay
        let validScore = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000, // 100000 + 50000 + 15000
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 105000
        )
        
        // Test with incorrect gross pay
        let invalidScore = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 200000, // Wrong total
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000,
            netRemittance: 140000
        )
        
        XCTAssertGreaterThan(validScore, invalidScore, "Valid gross pay should have higher confidence")
    }
    
    func testTotalDeductionsValidation() async {
        // Test with correct deductions total
        let validScore = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 60000, // 30000 + 10000 + 20000
            netRemittance: 105000
        )
        
        // Test with incorrect deductions total
        let invalidScore = await calculator.calculate(
            basicPay: 100000,
            dearnessAllowance: 50000,
            militaryServicePay: 15000,
            grossPay: 165000,
            dsop: 30000,
            agif: 10000,
            incomeTax: 20000,
            totalDeductions: 100000, // Wrong total
            netRemittance: 65000
        )
        
        XCTAssertGreaterThan(validScore, invalidScore, "Valid total deductions should have higher confidence")
    }
    
    func testNetRemittanceValidation() async {
        // Test with correct net remittance
        let validScore = await calculator.calculate(
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
        let invalidScore = await calculator.calculate(
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
        
        XCTAssertGreaterThan(validScore, invalidScore, "Valid net remittance should have higher confidence")
    }
    
    // MARK: - Missing Data Tests
    
    func testMissingCoreFieldsLowersConfidence() async {
        // All fields present
        let fullScore = await calculator.calculate(
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
        
        // Missing DA and AGIF
        let partialScore = await calculator.calculate(
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
        
        XCTAssertGreaterThan(fullScore, partialScore, "Missing core fields should lower confidence")
    }
    
    // MARK: - Range Validation Tests
    
    func testReasonableRanges() async {
        // Test with values in reasonable range
        let validScore = await calculator.calculate(
            basicPay: 144700, // Within 50K-300K
            dearnessAllowance: 88110, // Within 30K-200K
            militaryServicePay: 15500, // Within 10K-25K
            grossPay: 248310,
            dsop: 40000, // Within 10K-100K
            agif: 12500, // Within 5K-30K
            incomeTax: 47624,
            totalDeductions: 100124,
            netRemittance: 148186
        )
        
        // Test with values outside reasonable range
        let invalidScore = await calculator.calculate(
            basicPay: 500000, // Too high
            dearnessAllowance: 5000, // Too low
            militaryServicePay: 50000, // Too high
            grossPay: 555000,
            dsop: 150000, // Too high
            agif: 2000, // Too low
            incomeTax: 100000,
            totalDeductions: 252000,
            netRemittance: 303000
        )
        
        XCTAssertGreaterThan(validScore, invalidScore, "Reasonable ranges should increase confidence")
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


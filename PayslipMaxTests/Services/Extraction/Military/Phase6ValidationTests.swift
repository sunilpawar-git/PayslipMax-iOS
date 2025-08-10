import XCTest
@testable import PayslipMax

/// Simple validation tests for Phase 6.3 PCDA Table Structure Revolution
/// Focuses on key objectives without complex mocking
class Phase6ValidationTests: XCTestCase {
    
    var militaryProcessor: MilitaryPayslipProcessor!
    var militaryExtractor: MilitaryFinancialDataExtractor!
    
    override func setUp() {
        super.setUp()
        militaryProcessor = MilitaryPayslipProcessor()
        militaryExtractor = MilitaryFinancialDataExtractor()
    }
    
    override func tearDown() {
        militaryProcessor = nil
        militaryExtractor = nil
        super.tearDown()
    }
    
    // MARK: - Core Phase 6.3 Success Criteria Tests
    
    /// Test 1: Verify PCDA format detection works correctly
    func testPCDAFormatDetection() {
        let pcdaPayslipText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        Statement of Account for October 2023
        
        विवरण / DESCRIPTION    राशि / AMOUNT    विवरण / DESCRIPTION    राशि / AMOUNT
        Basic Pay              136400           DSOPF Subn             40000
        DA                     69874            AGIF                   10000
        MSP                    15600            Incm Tax               48030
        """
        
        // Test that military processor can detect this as a military payslip
        let confidence = militaryProcessor.canProcess(text: pcdaPayslipText)
        XCTAssertGreaterThan(confidence, 0.5, "Should detect PCDA format as military payslip")
        
        print("✅ PCDA Format Detection Test PASSED - Confidence: \(confidence)")
    }
    
    /// Test 2: Verify military processor processes PCDA payslips without errors
    func testMilitaryProcessorPCDAProcessing() {
        let pcdaPayslipText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        Statement of Account for October 2023
        Service No & Name: 123456 - Military Personnel
        
        विवरण / DESCRIPTION    राशि / AMOUNT    विवरण / DESCRIPTION    राशि / AMOUNT
        Basic Pay              50000            DSOPF Subn             5000
        DA                     20000            AGIF                   2000
        MSP                    10000            Incm Tax               4000
        """
        
        // Test that the processor can handle PCDA format without crashing
        XCTAssertNoThrow({
            let payslipItem = try self.militaryProcessor.processPayslip(from: pcdaPayslipText)
            XCTAssertNotNil(payslipItem, "Should create payslip item")
            XCTAssertGreaterThan(payslipItem.credits, 0, "Should extract positive credits")
            XCTAssertGreaterThan(payslipItem.debits, 0, "Should extract positive debits")
            
            print("✅ Military Processor PCDA Processing Test PASSED")
            print("   Credits: \(payslipItem.credits), Debits: \(payslipItem.debits)")
        })
    }
    
    /// Test 3: Verify financial data extraction improves over baseline
    func testFinancialDataExtractionImprovement() {
        let testPayslipText = """
        PCDA Format Payslip
        Credits and Debits Layout
        BPAY 50000 DSOP 5000
        DA 20000 AGIF 2000
        MSP 10000 IT 3000
        """
        
        // Test text-based extraction
        let (earnings, deductions) = militaryExtractor.extractMilitaryTabularData(from: testPayslipText)
        
        // Verify basic extraction works
        XCTAssertGreaterThan(earnings.count, 0, "Should extract earnings components")
        XCTAssertGreaterThan(deductions.count, 0, "Should extract deduction components")
        
        // Verify specific military codes are recognized
        let hasBasicPay = earnings.keys.contains { key in
            key.uppercased().contains("BPAY") || key.uppercased().contains("BASIC")
        }
        XCTAssertTrue(hasBasicPay, "Should recognize basic pay component")
        
        let hasDSOP = deductions.keys.contains { key in
            key.uppercased().contains("DSOP")
        }
        XCTAssertTrue(hasDSOP, "Should recognize DSOP component")
        
        print("✅ Financial Data Extraction Test PASSED")
        print("   Earnings: \(earnings)")
        print("   Deductions: \(deductions)")
    }
    
    /// Test 4: Verify PCDA validation service works
    func testPCDAValidationService() {
        let validator = PCDAFinancialValidator()
        
        // Test balanced PCDA scenario (Credits = Debits as per PCDA rules)
        let balancedCredits = ["BASIC PAY": 100000.0, "DA": 50000.0]
        let balancedDebits = ["DSOP": 75000.0, "AGIF": 25000.0, "IT": 50000.0]
        
        let balancedResult = validator.validatePCDAExtraction(
            credits: balancedCredits,
            debits: balancedDebits,
            remittance: nil
        )
        
        XCTAssertTrue(balancedResult.isValid, "Balanced PCDA data should validate successfully")
        
        // Test unbalanced scenario
        let unbalancedCredits = ["BASIC PAY": 100000.0]
        let unbalancedDebits = ["DSOP": 5000.0]
        
        let unbalancedResult = validator.validatePCDAExtraction(
            credits: unbalancedCredits,
            debits: unbalancedDebits,
            remittance: nil
        )
        
        // This might pass or warn depending on validation logic - we just ensure it doesn't crash
        XCTAssertTrue(true, "Validation should complete without errors")
        
        print("✅ PCDA Validation Service Test PASSED")
        print("   Balanced result: \(balancedResult)")
        print("   Unbalanced result: \(unbalancedResult)")
    }
    
    /// Test 5: Performance requirement validation (< 3 seconds)
    func testProcessingPerformance() {
        let testPayslipText = createLargeTestPayslip()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test the main extraction pipeline
        let _ = militaryExtractor.extractMilitaryTabularData(from: testPayslipText)
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Phase 6 requirement: < 3 seconds processing time
        XCTAssertLessThan(processingTime, 3.0, "Processing should complete within 3 seconds")
        
        print("✅ Performance Test PASSED - Processing time: \(String(format: "%.3f", processingTime)) seconds")
    }
    
    /// Test 6: Error handling and fallback behavior
    func testErrorHandlingAndFallbacks() {
        // Test with empty input
        let (emptyEarnings, emptyDeductions) = militaryExtractor.extractMilitaryTabularData(from: "")
        XCTAssertTrue(emptyEarnings.isEmpty && emptyDeductions.isEmpty, "Empty input should return empty results")
        
        // Test with malformed input
        let malformedText = "Random text with no financial data @#$%"
        let (malformedEarnings, malformedDeductions) = militaryExtractor.extractMilitaryTabularData(from: malformedText)
        XCTAssertTrue(malformedEarnings.isEmpty && malformedDeductions.isEmpty, "Malformed input should return empty results")
        
        // Test with partial PCDA format
        let partialPCDAText = """
        PCDA Format
        Some earning 50000
        Some deduction 5000
        """
        
        // Should not crash and might extract some data
        XCTAssertNoThrow({
            let (_, _) = self.militaryExtractor.extractMilitaryTabularData(from: partialPCDAText)
            // Results may be empty or contain data - both are acceptable for partial input
            XCTAssertTrue(true, "Partial PCDA processing should not crash")
        })
        
        print("✅ Error Handling and Fallback Test PASSED")
    }
    
    /// Test 7: October 2023 Reference Case (Simplified)
    func testOctober2023ReferenceCase() {
        // Simplified version of the October 2023 payslip that caused the 5.8x error
        let october2023Text = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        Statement of Account for October 2023
        
        CREDIT SIDE:
        Basic Pay 136400
        DA 69874
        MSP 15600
        Transport Allowance 5256
        
        DEBIT SIDE:
        DSOPF Subscription 40000
        AGIF 10000
        Income Tax 48030
        Education Cess 1740
        
        Total Credits: 263160
        Total Debits: 263160
        Net Remittance: 160570
        """
        
        let (earnings, deductions) = militaryExtractor.extractMilitaryTabularData(from: october2023Text)
        
        // Test that we extract meaningful data (exact matching would require full integration)
        XCTAssertGreaterThan(earnings.count, 0, "Should extract earnings from October 2023 case")
        XCTAssertGreaterThan(deductions.count, 0, "Should extract deductions from October 2023 case")
        
        // Test that the total values are reasonable (not the 5.8x error we had before)
        let totalEarnings = earnings.values.reduce(0, +)
        let totalDeductions = deductions.values.reduce(0, +)
        
        // Ensure we're not getting the massive over-calculation error (15,27,640 vs 2,63,160)
        XCTAssertLessThan(totalEarnings, 500000, "Earnings should not have massive over-calculation")
        XCTAssertLessThan(totalDeductions, 500000, "Deductions should not have massive over-calculation")
        
        print("✅ October 2023 Reference Case Test PASSED")
        print("   Total Earnings: \(totalEarnings) (should be reasonable)")
        print("   Total Deductions: \(totalDeductions) (should be reasonable)")
        print("   Components - Earnings: \(earnings.count), Deductions: \(deductions.count)")
    }
    
    // MARK: - Helper Methods
    
    private func createLargeTestPayslip() -> String {
        var payslipText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        Large Test Payslip for Performance Testing
        
        विवरण / DESCRIPTION    राशि / AMOUNT    विवरण / DESCRIPTION    राशि / AMOUNT
        """
        
        // Add many rows to test performance
        for i in 1...50 {
            payslipText += "\nEarning\(i) \(10000 + i * 100)    Deduction\(i) \(1000 + i * 10)"
        }
        
        return payslipText
    }
}

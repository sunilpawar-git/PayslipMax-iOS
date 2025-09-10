//
//  May2025PayslipAccuracyTests.swift
//  PayslipMaxTests
//
//  Test case for May 2025 payslip accuracy based on reference dataset
//  Validates critical fixes for string interpolation and ARR-RSHNA detection
//

import XCTest
@testable import PayslipMax

final class May2025PayslipAccuracyTests: XCTestCase {
    
    // MARK: - Properties
    
    private var militaryPatternExtractor: MilitaryPatternExtractor!
    private var testContainer: DIContainer!
    
    // MARK: - Setup
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize test DI container
        testContainer = DIContainer.shared
        
        // Initialize military pattern extractor
        militaryPatternExtractor = MilitaryPatternExtractor()
    }
    
    override func tearDownWithError() throws {
        militaryPatternExtractor = nil
        testContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - May 2025 Reference Dataset Tests
    
    /// Test May 2025 payslip against reference dataset expectations
    /// Expected results from PCDA_Military_Payslip_Reference_Dataset.md
    func testMay2025PayslipAccuracy() throws {
        // Expected results from reference dataset
        let expectedCredits: Double = 276665
        let expectedDebits: Double = 108525
        let expectedComponents: [String: Double] = [
            "BasicPay": 144700,  // Extractor returns "BasicPay", not "BPAY"
            "DA": 88110,
            "MSP": 15500,
            "RH12": 21125,
            "TPTA": 3600,
            "TPTADA": 1980,
            "ARR-RSHNA": 1650  // Must detect this after fix
        ]
        
        // May 2025 payslip text (simplified for testing)
        let may2025Text = """
        Principal Controller of Defence Accounts (Officers), Pune - 05/2025
        Name: Sunil Suresh Pawar
        A/C No: 16/110/206718K
        
        EARNINGS (आय/EARNINGS ₹)
        BPAY (12A)    144700
        DA            88110
        MSP           15500
        RH12          21125
        TPTA          3600
        TPTADA        1980
        ARR-RSHNA     1650
        Gross Pay     276665
        
        DEDUCTIONS (कटौती/DEDUCTIONS ₹)
        RH12          7518
        DSOP          40000
        AGIF          12500
        ITAX          46641
        EHCESS        1866
        Total Deductions  108525
        
        Net Remittance: Rs.1,68,140
        """
        
        // Test extraction
        let result = militaryPatternExtractor.extractFinancialDataLegacy(from: may2025Text)
        
        // Validate ARR-RSHNA detection (critical fix)
        XCTAssertNotNil(result["ARR-RSHNA"], "ARR-RSHNA should be detected after pattern fix")
        if let actualRSHNA = result["ARR-RSHNA"], let expectedRSHNA = expectedComponents["ARR-RSHNA"] {
            XCTAssertEqual(actualRSHNA, expectedRSHNA, accuracy: 1.0,
                          "ARR-RSHNA amount should match reference dataset")
        }
        
        // Validate other critical components
        for (component, expectedAmount) in expectedComponents {
            if component != "ARR-RSHNA" { // Already tested above
                XCTAssertNotNil(result[component], "\(component) should be detected")
                if let actualAmount = result[component] {
                    XCTAssertEqual(actualAmount, expectedAmount, accuracy: 1.0,
                                  "\(component) amount should match reference dataset")
                }
            }
        }
        
        // Test total calculations
        if let grossPay = result["credits"] {
            XCTAssertEqual(grossPay, expectedCredits, accuracy: 1.0,
                          "Gross pay should match reference dataset")
        }
        
        if let totalDeductions = result["debits"] {
            XCTAssertEqual(totalDeductions, expectedDebits, accuracy: 1.0,
                          "Total deductions should match reference dataset")
        }
    }
    
    /// Test ARR-RSHNA pattern recognition specifically
    func testARRRSHNAPatternExtraction() throws {
        let testCases = [
            // Standard format
            ("ARR-RSHNA: ₹1650", 1650.0),
            // Space-separated format
            ("ARR RSHNA: 1650", 1650.0),
            // Verbose format
            ("ARREARS RSHNA: Rs. 1,650", 1650.0),
            // Mixed format
            ("ARR-RSHNA    1650", 1650.0)
        ]
        
        for (input, expected) in testCases {
            let result = militaryPatternExtractor.extractFinancialDataLegacy(from: input)
            if let actualAmount = result["ARR-RSHNA"] {
                XCTAssertEqual(actualAmount, expected, accuracy: 1.0,
                              "Should extract ARR-RSHNA from: \(input)")
            } else {
                XCTFail("Failed to extract ARR-RSHNA from: \(input)")
            }
        }
    }
    
    /// Test string interpolation fix in logging
    func testStringInterpolationFix() throws {
        // This test ensures the string interpolation bug is fixed
        // by checking that static pattern extraction works properly
        let testText = "ARR-RSHNA: 1650"
        
        // Should not crash with string interpolation error
        let result = militaryPatternExtractor.extractFinancialDataLegacy(from: testText)
        
        // Should successfully extract the value
        XCTAssertNotNil(result["ARR-RSHNA"], "Should extract ARR-RSHNA without string interpolation errors")
        XCTAssertEqual(result["ARR-RSHNA"], 1650.0, "Should extract correct amount")
    }
    
    /// Test no regression on existing functionality
    func testNoRegressionOnExistingPatterns() throws {
        let testText = """
        BPAY: 144700
        DA: 88110
        DSOP: 40000
        AGIF: 12500
        ARR-DA: 5000
        ARR-CEA: 2000
        """
        
        let result = militaryPatternExtractor.extractFinancialDataLegacy(from: testText)
        
        // Existing patterns should still work
        XCTAssertEqual(result["ARR-DA"], 5000.0, "ARR-DA should still be detected")
        XCTAssertEqual(result["ARR-CEA"], 2000.0, "ARR-CEA should still be detected")
        XCTAssertEqual(result["DSOP"], 40000.0, "DSOP should still be detected")
        XCTAssertEqual(result["AGIF"], 12500.0, "AGIF should still be detected")
    }
    
    /// Performance test for pattern extraction
    func testPatternExtractionPerformance() throws {
        let largeText = String(repeating: "BPAY: 144700 DA: 88110 ARR-RSHNA: 1650 ", count: 1000)
        
        measure {
            _ = militaryPatternExtractor.extractFinancialDataLegacy(from: largeText)
        }
    }
}

//
//  ArrearsClassificationIntegrationTests.swift
//  PayslipMaxTests
//
//  Created for Phase 3: Universal Arrears Enhancement - Integration Testing
//  Tests complex arrears scenarios with dual-section support
//

import XCTest
@testable import PayslipMax

final class ArrearsClassificationIntegrationTests: XCTestCase {
    
    var arrearsService: ArrearsClassificationService!
    var arrearsPatternMatcher: UniversalArrearsPatternMatcher!
    var displayFormatter: ArrearsDisplayFormatter!
    
    override func setUp() {
        super.setUp()
        arrearsService = ArrearsClassificationService()
        arrearsPatternMatcher = UniversalArrearsPatternMatcher()
        displayFormatter = ArrearsDisplayFormatter()
    }
    
    override func tearDown() {
        arrearsService = nil
        arrearsPatternMatcher = nil
        displayFormatter = nil
        super.tearDown()
    }
    
    // MARK: - Target 3.3 Integration Tests
    
    /// Test dual-section arrears classification scenarios
    func testComplexArrearsScenarios_DualSectionClassification() {
        // Test scenario: HRA payment vs HRA recovery
        let hraPaymentText = """
        EARNINGS
        ARR-HRA House Rent Allowance   15000
        Back payment for arrears
        """
        
        let hraRecoveryText = """
        DEDUCTIONS
        ARR-HRA Recovery              5000
        Excess recovery of overpayment
        """
        
        // Test HRA payment classification
        let hraPaymentSection = arrearsService.classifyArrearsSection(
            component: "ARR-HRA",
            baseComponent: "HRA", 
            value: 15000,
            text: hraPaymentText
        )
        XCTAssertEqual(hraPaymentSection, .earnings, "ARR-HRA payment should be classified as earnings")
        
        // Test HRA recovery classification
        let hraRecoverySection = arrearsService.classifyArrearsSection(
            component: "ARR-HRA",
            baseComponent: "HRA",
            value: 5000,
            text: hraRecoveryText
        )
        XCTAssertEqual(hraRecoverySection, .deductions, "ARR-HRA recovery should be classified as deductions")
    }
    
    /// Test arrears pattern extraction with dual storage
    func testArrearsPatternExtraction_DualStorageKeys() async {
        let dualSectionText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR MAY 2025
        
        EARNINGS
        ARR-HRA House Rent Allowance   15000
        ARR-CEA Children Education     3375
        
        DEDUCTIONS  
        ARR-HRA Recovery               5000
        ARR-RSHNA Excess Recovery      1650
        """
        
        let extractedArrears = await arrearsPatternMatcher.extractArrearsComponents(from: dualSectionText)
        
        // Verify dual-section keys are generated correctly
        XCTAssertTrue(extractedArrears.keys.contains { $0.contains("ARR-HRA_EARNINGS") || $0.contains("ARR-HRA_DEDUCTIONS") },
                     "Should generate section-specific keys for HRA arrears")
        
        XCTAssertTrue(extractedArrears.keys.contains { $0.contains("ARR-CEA") },
                     "Should extract CEA arrears")
        
        XCTAssertTrue(extractedArrears.keys.contains { $0.contains("ARR-RSHNA") },
                     "Should extract RSHNA arrears")
        
        // Verify we have at least 3 arrears components
        XCTAssertGreaterThanOrEqual(extractedArrears.count, 3, 
                                   "Should extract multiple arrears components")
    }
    
    /// Test guaranteed single-section arrears (backward compatibility)
    func testGuaranteedSingleSectionArrears() {
        let basicPayArrearsText = """
        EARNINGS
        ARR-BPAY Basic Pay Arrears     25000
        Back payment of basic pay
        """
        
        let dsopArrearsText = """
        DEDUCTIONS
        ARR-DSOP DSOP Recovery         2000
        Excess DSOP adjustment
        """
        
        // Test guaranteed earnings (ARR-BPAY)
        let bpaySection = arrearsService.classifyArrearsSection(
            component: "ARR-BPAY",
            baseComponent: "BPAY",
            value: 25000,
            text: basicPayArrearsText
        )
        XCTAssertEqual(bpaySection, .earnings, "ARR-BPAY should always be earnings")
        
        // Test guaranteed deductions (ARR-DSOP)
        let dsopSection = arrearsService.classifyArrearsSection(
            component: "ARR-DSOP",
            baseComponent: "DSOP",
            value: 2000,
            text: dsopArrearsText
        )
        XCTAssertEqual(dsopSection, .deductions, "ARR-DSOP should always be deductions")
    }
    
    /// Test May 2025 payslip scenario with RH12 and ARR-RSHNA
    func testMay2025PayslipScenario() async {
        let may2025Text = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR THE MONTH OF MAY 2025
        
        EARNINGS
        Basic Pay                    78800
        RH12                        21125
        ARR-RSHNA                   1650
        
        DEDUCTIONS
        RH12                         7518
        Income Tax                  52380
        """
        
        let extractedArrears = await arrearsPatternMatcher.extractArrearsComponents(from: may2025Text)
        
        // Verify ARR-RSHNA is extracted
        XCTAssertTrue(extractedArrears.keys.contains { $0.contains("ARR-RSHNA") },
                     "Should extract ARR-RSHNA from May 2025 scenario")
        
        // Test RSHNA classification in earnings context
        let rshnaSection = arrearsService.classifyArrearsSection(
            component: "ARR-RSHNA",
            baseComponent: "RSHNA",
            value: 1650,
            text: may2025Text
        )
        XCTAssertEqual(rshnaSection, .earnings, "ARR-RSHNA should be classified as earnings in this context")
    }
    
    /// Test arrears display formatting with dual-section keys
    func testArrearsDisplayFormatting_DualSectionKeys() {
        // Test dual-section display names
        let hraEarningsDisplay = displayFormatter.formatArrearsDisplayName("ARR-HRA_EARNINGS")
        XCTAssertEqual(hraEarningsDisplay, "Arrears House Rent Allowance (Payment)", 
                      "Should format dual-section earnings display correctly")
        
        let hraDeductionsDisplay = displayFormatter.formatArrearsDisplayName("ARR-HRA_DEDUCTIONS") 
        XCTAssertEqual(hraDeductionsDisplay, "Arrears House Rent Allowance (Recovery)",
                      "Should format dual-section deductions display correctly")
        
        // Test single-section display names (backward compatibility)
        let bpayDisplay = displayFormatter.formatArrearsDisplayName("ARR-BPAY")
        XCTAssertEqual(bpayDisplay, "Arrears Basic Pay",
                      "Should format single-section display correctly")
    }
    
    /// Test performance of enhanced arrears processing
    func testArrearsProcessingPerformance() async {
        let largePayslipText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR MAY 2025
        
        EARNINGS
        Basic Pay                    78800
        RH12                        21125
        ARR-HRA                     15000
        ARR-CEA                      3375
        ARR-DA                      12500
        ARR-RSHNA                   1650
        
        DEDUCTIONS
        RH12                         7518
        ARR-HRA Recovery             5000
        ARR-CEA Recovery             1200
        Income Tax                  52380
        DSOP                        25600
        """
        
        measure {
            Task {
                _ = await arrearsPatternMatcher.extractArrearsComponents(from: largePayslipText)
            }
        }
    }
    
    /// Test edge cases with unknown arrears codes
    func testUnknownArrearsCodesHandling() async {
        let unknownArrearsText = """
        EARNINGS
        ARR-NEWCODE New Allowance    5000
        
        DEDUCTIONS
        ARR-FUTURE Future Deduction  2000
        """
        
        let extractedArrears = await arrearsPatternMatcher.extractArrearsComponents(from: unknownArrearsText)
        
        // Should handle unknown codes gracefully with universal dual-section processing
        XCTAssertGreaterThan(extractedArrears.count, 0, "Should extract unknown arrears codes")
        
        // Test classification of unknown codes
        let newCodeSection = arrearsService.classifyArrearsSection(
            component: "ARR-NEWCODE",
            baseComponent: "NEWCODE",
            value: 5000,
            text: unknownArrearsText
        )
        // Unknown codes should be classified based on context
        XCTAssertNotNil(newCodeSection, "Should classify unknown arrears codes")
    }
    
    /// Test backward compatibility with existing arrears patterns
    func testBackwardCompatibility_ExistingArrearsPatterns() async {
        let legacyArrearsText = """
        ARREARS BASIC PAY            25000
        ARR-DA                       12500  
        ARREARS HRA                  15000
        """
        
        let extractedArrears = await arrearsPatternMatcher.extractArrearsComponents(from: legacyArrearsText)
        
        // Should extract legacy patterns
        XCTAssertGreaterThan(extractedArrears.count, 0, "Should extract legacy arrears patterns")
        
        // Should validate legacy patterns
        XCTAssertTrue(arrearsPatternMatcher.validateArrearsPattern("ARR-DA"),
                     "Should validate known arrears patterns")
    }
}

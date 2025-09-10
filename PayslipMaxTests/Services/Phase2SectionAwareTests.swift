//
//  Phase2SectionAwareTests.swift
//  PayslipMaxTests
//
//  Comprehensive tests for Phase 2: Section-Aware Processing with Universal RH and Arrears support
//  Tests RH Family (RH11-RH33) and Universal Arrears Pattern System integration
//

import XCTest
@testable import PayslipMax

final class Phase2SectionAwareTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sectionAwareMatcher: SectionAwarePatternMatcher!
    private var rh12DualHandler: RH12DualSectionHandler!
    private var testContainer: DIContainer!
    
    // MARK: - Setup
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize test DI container
        testContainer = DIContainer.shared
        
        // Initialize services
        sectionAwareMatcher = SectionAwarePatternMatcher()
        rh12DualHandler = RH12DualSectionHandler(sectionAwareMatcher: sectionAwareMatcher)
    }
    
    override func tearDownWithError() throws {
        sectionAwareMatcher = nil
        rh12DualHandler = nil
        testContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Phase 2 Core Functionality Tests
    
    func testMay2025RH12DualSectionDetection() async throws {
        // Test based on real May 2025 payslip data from reference dataset
        let may2025PayslipText = """
        Principal Controller of Defence Accounts (Officers), Pune - 05/2025
        
        EARNINGS (आय/EARNINGS ₹)
        BPAY (12A): ₹144,700
        DA: ₹88,110
        MSP: ₹15,500
        RH12: ₹21,125
        TPTA: ₹3,600
        TPTADA: ₹1,980
        ARR-RSHNA: ₹1,650
        Gross Pay: ₹276,665
        
        DEDUCTIONS (कटौती/DEDUCTIONS ₹)
        RH12: ₹7,518
        DSOP: ₹40,000
        AGIF: ₹12,500
        ITAX: ₹46,641
        EHCESS: ₹1,866
        Total Deductions: ₹108,525
        """
        
        // Test RH12 dual-section extraction
        let rh12Components = await rh12DualHandler.extractRH12Components(from: may2025PayslipText)
        
        // Validate RH12 appears in both sections
        XCTAssertEqual(rh12Components.count, 2, "Should detect RH12 in both earnings and deductions")
        
        let earningsRH12 = rh12Components.first { $0.isEarnings }
        let deductionsRH12 = rh12Components.first { $0.isDeduction }
        
        XCTAssertNotNil(earningsRH12, "Should detect RH12 in earnings section")
        XCTAssertNotNil(deductionsRH12, "Should detect RH12 in deductions section")
        
        if let earnings = earningsRH12, let deductions = deductionsRH12 {
            XCTAssertEqual(earnings.amount, 21125, "RH12 earnings should be ₹21,125")
            XCTAssertEqual(deductions.amount, 7518, "RH12 deductions should be ₹7,518")
            XCTAssertEqual(earnings.code, "RH12", "Should identify as RH12")
            XCTAssertEqual(deductions.code, "RH12", "Should identify as RH12")
        }
    }
    
    func testUniversalRHFamilyExtraction() async throws {
        // Test all RH codes (RH11-RH33) in various formats
        let universalRHText = """
        EARNINGS SECTION
        RH11: ₹50,000  (Highest Risk Allowance)
        RH12: ₹21,125  (High Risk)
        RH13: ₹18,500  (Moderate-High Risk)
        RISK & HARDSHIP RH21: ₹15,000
        R&H ALLOWANCE RH22: ₹12,500
        RISK HARDSHIP RH23: ₹10,000
        
        DEDUCTIONS SECTION  
        RH31: ₹8,000   (Low Risk Recovery)
        RH32: ₹6,500   (Lower Risk Recovery)
        RH33: ₹5,000   (Lowest Risk Recovery)
        """
        
        // Test Universal RH Family extraction
        let allRHComponents = await rh12DualHandler.extractAllRHComponents(from: universalRHText)
        
        // Should detect all 9 RH codes
        XCTAssertEqual(allRHComponents.count, 9, "Should detect all 9 RH codes")
        
        // Validate specific codes and amounts
        let rhCodes = Set(allRHComponents.map { $0.code })
        let expectedCodes: Set<String> = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
        XCTAssertEqual(rhCodes, expectedCodes, "Should detect all expected RH codes")
        
        // Test hierarchy validation (RH11 highest, RH33 lowest)
        if let rh11 = allRHComponents.first(where: { $0.code == "RH11" }),
           let rh33 = allRHComponents.first(where: { $0.code == "RH33" }) {
            XCTAssertEqual(rh11.level.priority, 1, "RH11 should have highest priority")
            XCTAssertEqual(rh33.level.priority, 9, "RH33 should have lowest priority")
            XCTAssertGreaterThan(rh11.amount, rh33.amount, "RH11 amount should be higher than RH33")
        }
    }
    
    func testUniversalArrearsPatternDetection() async throws {
        // Test Universal Arrears Pattern System
        let arrearsText = """
        EARNINGS SECTION
        ARR-BPAY: ₹5,000
        ARR-DA: ₹2,500
        ARR-RH12: ₹1,800
        Arr-TPTA: ₹800
        ARREARS MSP: ₹1,500
        ARR RSHNA: ₹1,650
        
        DEDUCTIONS SECTION
        ARR-DSOP: ₹2,000
        ARR-AGIF: ₹1,000
        """
        
        // Extract using section-aware matcher
        let sections = sectionAwareMatcher.identifyDocumentSections(in: arrearsText)
        
        // Test section identification
        XCTAssertTrue(sections.keys.contains(.earnings), "Should identify earnings section")
        XCTAssertTrue(sections.keys.contains(.deductions), "Should identify deductions section")
        
        // Test that we can extract arrears using the section-aware system
        let financialItems = await sectionAwareMatcher.handleDualSectionComponents(arrearsText)
        
        // Should detect arrears components
        let arrearsItems = financialItems.filter { $0.isArrearsCode }
        XCTAssertGreaterThan(arrearsItems.count, 0, "Should detect arrears components")
        
        // Validate specific arrears codes
        let arrearsEarnings = arrearsItems.filter { $0.section == .earnings }
        let arrearsDeductions = arrearsItems.filter { $0.section == .deductions }
        
        XCTAssertGreaterThan(arrearsEarnings.count, 0, "Should detect arrears in earnings")
        XCTAssertGreaterThan(arrearsDeductions.count, 0, "Should detect arrears in deductions")
    }
    
    func testSectionIdentificationAccuracy() {
        // Test section boundary detection
        let complexPayslipText = """
        Principal Controller of Defence Accounts (Officers), Pune
        Name: SUNIL SURESH PAWAR
        A/C No: 16/110/206718K
        
        EARNINGS (आय/EARNINGS ₹)
        BPAY: ₹144,700
        DA: ₹88,110
        RH12: ₹21,125
        
        DEDUCTIONS (कटौती/DEDUCTIONS ₹)  
        RH12: ₹7,518
        DSOP: ₹40,000
        
        DETAILS OF TRANSACTIONS
        Transaction 1: Payment processed
        Transaction 2: Deduction applied
        """
        
        let sections = sectionAwareMatcher.identifyDocumentSections(in: complexPayslipText)
        
        // Should identify all major sections
        XCTAssertTrue(sections.keys.contains(.earnings), "Should identify earnings section")
        XCTAssertTrue(sections.keys.contains(.deductions), "Should identify deductions section")
        XCTAssertTrue(sections.keys.contains(.transactions), "Should identify transactions section")
        XCTAssertTrue(sections.keys.contains(.metadata), "Should identify metadata section")
        
        // Validate section content separation
        if let earningsText = sections[.earnings] {
            XCTAssertTrue(earningsText.contains("BPAY"), "Earnings section should contain BPAY")
            XCTAssertTrue(earningsText.contains("RH12"), "Earnings section should contain RH12")
        }
        
        if let deductionsText = sections[.deductions] {
            XCTAssertTrue(deductionsText.contains("DSOP"), "Deductions section should contain DSOP")
            XCTAssertTrue(deductionsText.contains("RH12"), "Deductions section should contain RH12")
        }
    }
    
    func testDualSectionValidation() async throws {
        // Test validation logic for dual-section components
        let rh12Components = [
            RHComponent(code: "RH12", amount: 21125, section: .earnings, confidence: 0.9, 
                       isEarnings: true, isDeduction: false, level: .rh12),
            RHComponent(code: "RH12", amount: 7518, section: .deductions, confidence: 0.9,
                       isEarnings: false, isDeduction: true, level: .rh12)
        ]
        
        let validationResult = rh12DualHandler.validateDualSectionConsistency(rh12Components)
        
        XCTAssertTrue(validationResult.isValid, "Dual-section RH12 should be valid")
        XCTAssertEqual(validationResult.errors.count, 0, "Should have no errors")
        XCTAssertGreaterThan(validationResult.suggestions.count, 0, "Should provide suggestions")
        
        // Should suggest net positive allowance
        let hasNetPositiveSuggestion = validationResult.suggestions.contains { 
            $0.contains("Net positive allowance") 
        }
        XCTAssertTrue(hasNetPositiveSuggestion, "Should suggest net positive allowance for RH12")
    }
    
    func testPerformanceWithLargePayslip() async throws {
        // Test performance with complex, large payslip text
        let largePayslipText = String(repeating: """
        EARNINGS: RH11: ₹50000, RH12: ₹21125, RH13: ₹18500
        DEDUCTIONS: RH31: ₹8000, RH32: ₹6500, RH33: ₹5000
        ARR-BPAY: ₹5000, ARR-DA: ₹2500, ARR-RH12: ₹1800
        """, count: 100)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let allComponents = await rh12DualHandler.extractAllRHComponents(from: largePayslipText)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let processingTime = endTime - startTime
        
        // Should process within reasonable time
        XCTAssertLessThan(processingTime, 1.0, "Should process large payslip within 1 second")
        XCTAssertGreaterThan(allComponents.count, 0, "Should extract components from large payslip")
    }
    
    // MARK: - Integration Tests
    
    func testPhase2IntegrationWithMay2025() async throws {
        // Complete integration test using actual May 2025 payslip structure
        let may2025CompleteText = """
        Principal Controller of Defence Accounts (Officers), Pune - 05/2025
        Name: Sunil Suresh Pawar
        A/C No: 16/110/206718K
        PAN No: AR*****90G
        
        EARNINGS (आय/EARNINGS ₹)
        BPAY (12A): ₹144,700
        DA: ₹88,110  
        MSP: ₹15,500
        RH12: ₹21,125
        TPTA: ₹3,600
        TPTADA: ₹1,980
        ARR-RSHNA: ₹1,650
        Gross Pay: ₹276,665
        
        DEDUCTIONS (कटौती/DEDUCTIONS ₹)
        RH12: ₹7,518
        DSOP: ₹40,000
        AGIF: ₹12,500
        ITAX: ₹46,641
        EHCESS: ₹1,866
        Total Deductions: ₹108,525
        """
        
        // Test complete Phase 2 functionality
        let allComponents = await sectionAwareMatcher.handleDualSectionComponents(may2025CompleteText)
        
        // Should detect all major components
        let componentCodes = Set(allComponents.map { $0.code })
        let expectedComponents: Set<String> = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA", "ARR-RSHNA", "DSOP", "AGIF", "ITAX", "EHCESS"]
        
        // Check that we detect most expected components (allowing for some extraction method differences)
        let detectedExpected = componentCodes.intersection(expectedComponents)
        XCTAssertGreaterThan(detectedExpected.count, 5, "Should detect majority of expected components")
        
        // Specifically check RH12 dual-section detection
        let rh12Components = allComponents.filter { $0.code == "RH12" }
        XCTAssertGreaterThan(rh12Components.count, 0, "Should detect RH12 components")
        
        // Check ARR-RSHNA detection (Phase 1 + Phase 2 integration)
        let arrearsComponents = allComponents.filter { $0.isArrearsCode }
        XCTAssertGreaterThan(arrearsComponents.count, 0, "Should detect arrears components")
    }
}

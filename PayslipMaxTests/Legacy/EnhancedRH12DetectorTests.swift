//
//  EnhancedRH12DetectorTests.swift
//  PayslipMaxTests
//
//  Created for testing Enhanced RH12 detection functionality
//  Validates Phase 4 implementation from RH12_Dual_Section_Parsing_Fix_Roadmap
//

import XCTest
@testable import PayslipMax

/// Comprehensive tests for EnhancedRH12Detector
/// Validates enhanced dual-section RH12 detection as implemented in Phase 4 of the roadmap
@MainActor
final class EnhancedRH12DetectorTests: BaseTestCase {

    // MARK: - Properties

    private var detector: EnhancedRH12Detector!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        detector = EnhancedRH12Detector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Single RH12 Detection Tests

    func testDetectAllRH12Instances_StandardPattern() {
        let payslipText = """
        STATEMENT OF ACCOUNT
        EARNINGS
        Basic Pay: ₹50,000
        RH12: ₹21,125
        TOTAL: ₹276,665
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 1, "Should detect exactly one RH12 instance")
        XCTAssertEqual(instances.first?.value, 21125.0, "Should correctly parse RH12 value")
        XCTAssertTrue(instances.first?.context.contains("RH12") ?? false, "Context should contain RH12")
    }

    func testDetectAllRH12Instances_NoColonPattern() {
        let payslipText = """
        EARNINGS
        RH12 ₹15,000
        MSP: ₹10,000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 1, "Should detect RH12 without colon")
        XCTAssertEqual(instances.first?.value, 15000.0, "Should correctly parse RH12 value")
    }

    func testDetectAllRH12Instances_SpacedPattern() {
        let payslipText = """
        ALLOWANCES
        R H 1 2    ₹8,500
        Other allowances
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 1, "Should detect spaced RH12 pattern")
        XCTAssertEqual(instances.first?.value, 8500.0, "Should correctly parse spaced RH12 value")
    }

    // MARK: - Dual RH12 Detection Tests (Core Phase 4 Functionality)

    func testDetectAllRH12Instances_DualSectionMay2025() {
        // Test case based on actual May 2025 payslip data from roadmap
        let may2025PayslipText = """
        STATEMENT OF ACCOUNT - MAY 2025

        EARNINGS                               AMOUNT
        Basic Pay                              50,000
        Dearness Allowance                     15,000
        Military Service Pay                   10,000
        RH12                                   21,125
        Transport Allowance                     3,000
        TOTAL EARNINGS                        276,665

        DEDUCTIONS                             AMOUNT
        Income Tax                              8,000
        AGIF                                    2,000
        DSOP                                    5,000
        RH12                                    7,518
        Other Deductions                        1,500
        TOTAL DEDUCTIONS                      108,525

        NET REMITTANCE                        168,140
        """

        let instances = detector.detectAllRH12Instances(in: may2025PayslipText)

        // Should detect both RH12 instances
        XCTAssertEqual(instances.count, 2, "Should detect both RH12 instances from May 2025 payslip")

        let values = instances.map { $0.value }.sorted()
        XCTAssertTrue(values.contains(7518.0), "Should detect RH12 deductions value ₹7,518")
        XCTAssertTrue(values.contains(21125.0), "Should detect RH12 earnings value ₹21,125")

        // Verify contexts are different (earnings vs deductions sections)
        let contexts = instances.map { $0.context }
        XCTAssertTrue(contexts.contains { $0.uppercased().contains("EARNINGS") }, "Should have earnings context")
        XCTAssertTrue(contexts.contains { $0.uppercased().contains("DEDUCTIONS") }, "Should have deductions context")
    }

    func testDetectAllRH12Instances_MultiplePatternsInSamePayslip() {
        let mixedPatternText = """
        EARNINGS
        RH12: ₹21,125          // Standard colon pattern
        Basic Pay ₹50,000

        DEDUCTIONS
        Risk Hardship ₹7,518   // Full text pattern
        Income Tax ₹8,000

        ALLOWANCES
        R H 1 2 ₹3,500         // Spaced pattern
        """

        let instances = detector.detectAllRH12Instances(in: mixedPatternText)

        XCTAssertEqual(instances.count, 3, "Should detect all RH12 patterns regardless of format")

        let values = instances.map { $0.value }.sorted()
        XCTAssertEqual(values, [3500.0, 7518.0, 21125.0], "Should detect all RH12 values correctly")
    }

    // MARK: - Pattern Variation Tests

    func testDetectAllRH12Instances_WithoutCurrencySymbol() {
        let payslipText = """
        EARNINGS
        RH12 21125
        Basic Pay 50000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 1, "Should detect RH12 without currency symbol")
        XCTAssertEqual(instances.first?.value, 21125.0, "Should correctly parse value without currency")
    }

    func testDetectAllRH12Instances_WithCommasInValue() {
        let payslipText = """
        DEDUCTIONS
        RH12: ₹21,125
        Tax: ₹8,000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 1, "Should handle comma-separated values")
        XCTAssertEqual(instances.first?.value, 21125.0, "Should correctly parse comma-separated value")
    }

    func testDetectAllRH12Instances_CaseInsensitive() {
        let payslipText = """
        EARNINGS
        rh12: ₹15,000
        Rh12 ₹10,000
        RH12: ₹5,000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 3, "Should detect RH12 regardless of case")
        let values = instances.map { $0.value }.sorted()
        XCTAssertEqual(values, [5000.0, 10000.0, 15000.0], "Should parse all case variations")
    }

    // MARK: - Context Extraction Tests

    func testDetectAllRH12Instances_ContextWindow() {
        let longPayslipText = String(repeating: "A", count: 1000) +
                             " EARNINGS RH12: ₹21,125 MSP " +
                             String(repeating: "B", count: 1000)

        let instances = detector.detectAllRH12Instances(in: longPayslipText)

        XCTAssertEqual(instances.count, 1, "Should detect RH12 in long text")

        let context = instances.first?.context ?? ""
        XCTAssertLessThanOrEqual(context.count, 800, "Context should be limited to 800 characters")
        XCTAssertTrue(context.contains("RH12"), "Context should contain the RH12 match")
        XCTAssertTrue(context.contains("EARNINGS"), "Context should include surrounding text")
    }

    // MARK: - Deduplication Tests

    func testDetectAllRH12Instances_DuplicateValues() {
        let payslipText = """
        EARNINGS
        RH12: ₹15,000
        Risk Hardship: ₹15,000
        RH12 ₹15,000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        // Should deduplicate same values (within 0.01 tolerance)
        XCTAssertEqual(instances.count, 1, "Should deduplicate identical RH12 values")
        XCTAssertEqual(instances.first?.value, 15000.0, "Should keep the deduplicated value")
    }

    func testDetectAllRH12Instances_NearDuplicateValues() {
        let payslipText = """
        EARNINGS
        RH12: ₹15,000.50
        RH12 ₹15,000.49
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        // Values differ by more than tolerance (0.01), so both should be kept
        XCTAssertEqual(instances.count, 2, "Should keep values that differ by more than tolerance")
    }

    // MARK: - Edge Cases and Error Handling

    func testDetectAllRH12Instances_EmptyText() {
        let instances = detector.detectAllRH12Instances(in: "")

        XCTAssertEqual(instances.count, 0, "Should handle empty text gracefully")
    }

    func testDetectAllRH12Instances_NoRH12() {
        let payslipText = """
        EARNINGS
        Basic Pay: ₹50,000
        MSP: ₹10,000
        DA: ₹15,000

        DEDUCTIONS
        Tax: ₹8,000
        AGIF: ₹2,000
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 0, "Should return empty array when no RH12 found")
    }

    func testDetectAllRH12Instances_InvalidAmounts() {
        let payslipText = """
        EARNINGS
        RH12: ₹abc
        RH12: ₹
        RH12:
        RH12: ₹-500
        """

        let instances = detector.detectAllRH12Instances(in: payslipText)

        XCTAssertEqual(instances.count, 0, "Should ignore invalid amount formats")
    }

    // MARK: - Performance Tests

    func testDetectAllRH12Instances_LargeText() {
        // Create a large payslip text with embedded RH12 values
        let baseText = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 1000)
        let payslipText = baseText + " RH12: ₹21,125 " + baseText + " RH12 ₹7,518 " + baseText

        let startTime = CFAbsoluteTimeGetCurrent()
        let instances = detector.detectAllRH12Instances(in: payslipText)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertEqual(instances.count, 2, "Should detect RH12 in large text")
        XCTAssertLessThan(executionTime, 1.0, "Should complete detection within 1 second for large text")
    }

    // MARK: - Integration Test with Real-World Data

    func testDetectAllRH12Instances_RealWorldMay2025Scenario() {
        // This test validates the exact scenario described in the roadmap
        let realWorldText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR THE MONTH OF MAY 2025

        NAME: MAJOR RAJESH KUMAR
        SERVICE NO: IC-56789
        UNIT: 15 RAJPUT REGIMENT

        EARNINGS                                          AMOUNT (₹)
        001  Basic Pay                                     65,000
        002  Dearness Allowance @ 42%                      27,300
        003  Military Service Pay                          15,500
        004  High Altitude Allowance                        8,200
        005  Technical Allowance                            5,800
        006  RH12                                          21,125
        007  Field Area Allowance                           4,500
        008  Transport Allowance                            3,240
                                            TOTAL EARNINGS  276,665

        DEDUCTIONS                                        AMOUNT (₹)
        101  Income Tax u/s 192                            45,280
        102  AGIF                                           6,500
        103  DSOP                                          32,500
        104  Group Insurance                                1,850
        105  RH12                                           7,518
        106  Welfare Fund                                   2,000
        107  Mess Charges                                   8,877
        108  Other Deductions                               4,000
                                         TOTAL DEDUCTIONS  108,525

        NET REMITTANCE                                    168,140
        """

        let instances = detector.detectAllRH12Instances(in: realWorldText)

        // Validate detection results match roadmap expectations
        XCTAssertEqual(instances.count, 2, "Should detect exactly 2 RH12 instances")

        let sortedValues = instances.map { $0.value }.sorted()
        XCTAssertEqual(sortedValues[0], 7518.0, "Should detect deduction RH12: ₹7,518")
        XCTAssertEqual(sortedValues[1], 21125.0, "Should detect earning RH12: ₹21,125")

        // Verify total matches roadmap calculation
        let totalRH12 = instances.map { $0.value }.reduce(0, +)
        XCTAssertEqual(totalRH12, 28643.0, "Total RH12 should be ₹28,643 (₹21,125 + ₹7,518)")

        // Verify contexts contain section information
        let contexts = instances.map { $0.context.uppercased() }
        XCTAssertTrue(contexts.contains { $0.contains("EARNINGS") }, "Should have earnings section context")
        XCTAssertTrue(contexts.contains { $0.contains("DEDUCTIONS") }, "Should have deductions section context")
    }
}

//
//  RiskHardshipProcessorTests.swift
//  PayslipMaxTests
//
//  Created for testing RH12 dual-section parsing functionality
//  Validates Phase 2 implementation from RH12_Dual_Section_Parsing_Fix_Roadmap
//

import XCTest
@testable import PayslipMax

/// Comprehensive tests for RiskHardshipProcessor
/// Validates dual-section RH12 processing as implemented in Phase 2 of the roadmap
@MainActor
final class RiskHardshipProcessorTests: BaseTestCase {

    // MARK: - Properties

    private var processor: RiskHardshipProcessor!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        processor = RiskHardshipProcessor()
    }

    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    // MARK: - RH Code Recognition Tests

    func testIsRiskHardshipCode_ValidRHCodes() {
        // Test all valid RH codes as specified in the processor
        let validCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]

        for code in validCodes {
            XCTAssertTrue(processor.isRiskHardshipCode(code), "Should recognize \(code) as valid RH code")
            XCTAssertTrue(processor.isRiskHardshipCode(code.lowercased()), "Should recognize lowercase \(code) as valid RH code")
            XCTAssertTrue(processor.isRiskHardshipCode("ALLOWANCE_\(code)"), "Should recognize \(code) within context")
        }
    }

    func testIsRiskHardshipCode_InvalidCodes() {
        let invalidCodes = ["RH10", "RH34", "RH99", "RH", "R12", "H12", "Basic Pay", "MSP"]

        for code in invalidCodes {
            XCTAssertFalse(processor.isRiskHardshipCode(code), "Should not recognize \(code) as valid RH code")
        }
    }

    // MARK: - Dual-Section Processing Tests (Phase 2 Core Functionality)

    func testProcessRiskHardshipComponent_EarningsClassification() {
        // Test data based on May 2025 payslip - RH12 earnings ₹21,125
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Mock payslip text with earnings context for high-value RH12
        let earningsContextText = """
        STATEMENT OF ACCOUNT
        EARNINGS                     AMOUNT
        Basic Pay                    50000
        Dearness Allowance          15000
        RH12                        21125
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                   8000
        """

        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 21125.0,
            text: earningsContextText,
            earnings: &earnings,
            deductions: &deductions
        )

        // Verify earnings classification using Phase 2 distinct key
        XCTAssertEqual(earnings["RH12_EARNINGS"], 21125.0, "RH12 earnings should be stored under RH12_EARNINGS key")
        XCTAssertNil(deductions["RH12_DEDUCTIONS"], "RH12 should not be classified as deduction in earnings context")
        XCTAssertEqual(earnings.count, 1, "Should store exactly one earnings entry")
        XCTAssertEqual(deductions.count, 0, "Should not store any deductions")
    }

    func testProcessRiskHardshipComponent_DeductionsClassification() {
        // Test data based on May 2025 payslip - RH12 deductions ₹7,518
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Mock payslip text with deductions context for low-value RH12
        let deductionsContextText = """
        STATEMENT OF ACCOUNT
        EARNINGS                     AMOUNT
        Basic Pay                    50000
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                   8000
        AGIF                        2000
        RH12                        7518
        TOTAL DEDUCTIONS           108525
        """

        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 7518.0,
            text: deductionsContextText,
            earnings: &earnings,
            deductions: &deductions
        )

        // Verify deductions classification using Phase 2 distinct key
        XCTAssertEqual(deductions["RH12_DEDUCTIONS"], 7518.0, "RH12 deductions should be stored under RH12_DEDUCTIONS key")
        XCTAssertNil(earnings["RH12_EARNINGS"], "RH12 should not be classified as earning in deductions context")
        XCTAssertEqual(deductions.count, 1, "Should store exactly one deductions entry")
        XCTAssertEqual(earnings.count, 0, "Should not store any earnings")
    }

    func testProcessRiskHardshipComponent_DualSectionComplete() {
        // Test the complete dual-section scenario from May 2025 payslip
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        let fullPayslipText = """
        STATEMENT OF ACCOUNT - MAY 2025
        EARNINGS                     AMOUNT
        Basic Pay                    50000
        Dearness Allowance          15000
        RH12                        21125  // High-value RH12 for earnings
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                   8000
        AGIF                        2000
        RH12                        7518   // Low-value RH12 for deductions
        TOTAL DEDUCTIONS           108525
        """

        // Process earnings RH12
        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 21125.0,
            text: fullPayslipText,
            earnings: &earnings,
            deductions: &deductions
        )

        // Process deductions RH12
        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 7518.0,
            text: fullPayslipText,
            earnings: &earnings,
            deductions: &deductions
        )

        // Verify dual-section storage
        XCTAssertEqual(earnings["RH12_EARNINGS"], 21125.0, "Should store earnings RH12")
        XCTAssertEqual(deductions["RH12_DEDUCTIONS"], 7518.0, "Should store deductions RH12")
        XCTAssertEqual(earnings.count, 1, "Should have exactly one earnings entry")
        XCTAssertEqual(deductions.count, 1, "Should have exactly one deductions entry")

        // Verify total RH12 value matches May 2025 expectation
        let totalRH12 = (earnings["RH12_EARNINGS"] ?? 0) + (deductions["RH12_DEDUCTIONS"] ?? 0)
        XCTAssertEqual(totalRH12, 28643.0, "Total RH12 should be ₹28,643 (₹21,125 + ₹7,518)")
    }

    // MARK: - Value-Based Heuristic Tests (Phase 3 Enhancement)

    func testProcessRiskHardshipComponent_HighValueHeuristic() {
        // Test enhanced heuristic for high values (>₹15,000) → earnings
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        let ambiguousText = "RH12 20000" // No clear section context

        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 20000.0,
            text: ambiguousText,
            earnings: &earnings,
            deductions: &deductions
        )

        XCTAssertEqual(earnings["RH12_EARNINGS"], 20000.0, "High-value RH12 should default to earnings")
        XCTAssertNil(deductions["RH12_DEDUCTIONS"], "High-value RH12 should not be deduction")
    }

    func testProcessRiskHardshipComponent_LowValueHeuristic() {
        // Test enhanced heuristic for low values (<₹10,000) → deductions
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        let ambiguousText = "RH12 5000" // No clear section context

        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 5000.0,
            text: ambiguousText,
            earnings: &earnings,
            deductions: &deductions
        )

        XCTAssertEqual(deductions["RH12_DEDUCTIONS"], 5000.0, "Low-value RH12 should default to deductions")
        XCTAssertNil(earnings["RH12_EARNINGS"], "Low-value RH12 should not be earning")
    }

    func testProcessRiskHardshipComponent_MidRangeHeuristic() {
        // Test enhanced heuristic for mid-range values (₹10,000-₹15,000) → earnings (safer default)
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        let ambiguousText = "RH12 12000" // No clear section context

        processor.processRiskHardshipComponent(
            key: "RH12",
            value: 12000.0,
            text: ambiguousText,
            earnings: &earnings,
            deductions: &deductions
        )

        XCTAssertEqual(earnings["RH12_EARNINGS"], 12000.0, "Mid-range RH12 should default to earnings (safer)")
        XCTAssertNil(deductions["RH12_DEDUCTIONS"], "Mid-range RH12 should not be deduction")
    }

    // MARK: - Invalid Input Handling Tests

    func testProcessRiskHardshipComponent_InvalidRHCode() {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        let text = "Some payslip text"

        processor.processRiskHardshipComponent(
            key: "InvalidCode",
            value: 1000.0,
            text: text,
            earnings: &earnings,
            deductions: &deductions
        )

        // Should not process invalid codes
        XCTAssertEqual(earnings.count, 0, "Should not process invalid RH codes in earnings")
        XCTAssertEqual(deductions.count, 0, "Should not process invalid RH codes in deductions")
    }

    // MARK: - Edge Cases and Boundary Tests

    func testProcessRiskHardshipComponent_BoundaryValues() {
        // Test boundary values for the enhanced heuristic thresholds
        let boundaryTestCases: [(value: Double, expectedSection: String)] = [
            (15000.0, "earnings"),    // Exactly at high threshold
            (15001.0, "earnings"),    // Just above high threshold
            (14999.0, "earnings"),    // Just below high threshold (mid-range default)
            (10000.0, "earnings"),    // Exactly at low threshold (mid-range default)
            (9999.0, "deductions"),   // Just below low threshold
            (10001.0, "earnings")     // Just above low threshold (mid-range default)
        ]

        for (value, expectedSection) in boundaryTestCases {
            var earnings: [String: Double] = [:]
            var deductions: [String: Double] = [:]

            processor.processRiskHardshipComponent(
                key: "RH12",
                value: value,
                text: "RH12 \(value)", // Minimal context
                earnings: &earnings,
                deductions: &deductions
            )

            if expectedSection == "earnings" {
                XCTAssertEqual(earnings["RH12_EARNINGS"], value, "Value ₹\(value) should be classified as earnings")
                XCTAssertNil(deductions["RH12_DEDUCTIONS"], "Value ₹\(value) should not be deduction")
            } else {
                XCTAssertEqual(deductions["RH12_DEDUCTIONS"], value, "Value ₹\(value) should be classified as deductions")
                XCTAssertNil(earnings["RH12_EARNINGS"], "Value ₹\(value) should not be earning")
            }
        }
    }
}

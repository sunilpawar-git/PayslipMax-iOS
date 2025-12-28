import XCTest
@testable import PayslipMax

/// Unit tests for UniversalParserConfidenceCalculator
/// Additional tests in extension files:
/// - UniversalParserConfidenceCalculatorTests+FieldTests.swift (month/year tests)
/// - UniversalParserConfidenceCalculatorTests+AmountTests.swift (amount/dictionary tests)
final class UniversalParserConfidenceCalculatorTests: XCTestCase {

    // MARK: - Perfect Parse Tests

    func testPerfectParse_AllFieldsValid_HighConfidence() {
        // Given: Perfect payslip data
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 75000.0,
            debits: 15000.0,
            earnings: [
                "Basic Pay": 42000.0,
                "DA": 20000.0,
                "MSP": 13000.0
            ],
            deductions: [
                "DSOP": 10000.0,
                "ITAX": 5000.0
            ]
        )

        // Then: Very high confidence (>90%)
        XCTAssertGreaterThan(result.overall, 0.90, "Perfect parse should have >90% confidence")
        XCTAssertLessThanOrEqual(result.overall, 1.0)

        // Verify field confidences
        XCTAssertEqual(result.fieldLevel["month"], 1.0)
        XCTAssertEqual(result.fieldLevel["year"], 1.0)
        XCTAssertGreaterThan(result.fieldLevel["netRemittance"] ?? 0, 0.9)
        XCTAssertGreaterThan(result.fieldLevel["earnings"] ?? 0, 0.9)
    }

    // MARK: - Overall Confidence Tests

    func testOverallConfidence_ProblematicParse_LowScore() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "Unknown",
            year: 2025,
            credits: 0,
            debits: 0,
            earnings: [:],
            deductions: [:]
        )

        XCTAssertLessThan(result.overall, 0.5, "Problematic parse should have <50% overall confidence")
    }

    func testOverallConfidence_MixedQuality_HighScore() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 0,
            earnings: [
                "Basic Pay": 50000,
                "DA": 0,
                "MSP": 0
            ],
            deductions: [:]
        )

        XCTAssertGreaterThan(
            result.overall, 0.9,
            "Mixed quality parse with perfect core fields should have >90% confidence"
        )
    }

    // MARK: - Edge Cases

    func testEdgeCase_NetRemittanceNegative_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 10000,
            debits: 20000, // Debits > Credits
            earnings: ["Basic Pay": 10000],
            deductions: ["DSOP": 20000]
        )

        XCTAssertLessThan(
            result.fieldLevel["netRemittance"] ?? 1.0, 0.5,
            "Negative net remittance should have low confidence"
        )
    }

    func testEdgeCase_BasicPayMissing_ReducedConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: [
                "DA": 25000,
                "MSP": 25000
                // No "Basic Pay" or "BPAY"
            ],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(
            result.fieldLevel["basicPay"] ?? 1.0, 0.2,
            "Missing basic pay should have 20% confidence"
        )
    }

    func testEdgeCase_BPAYInsteadOfBasicPay_FullConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: [
                "BPAY": 30000,
                "DA": 20000
            ],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["basicPay"], 1.0, "BPAY should be recognized as basic pay")
    }

    // MARK: - Boundary Tests

    func testBoundary_ConfidenceNeverExceedsOne() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 100000,
            debits: 10000,
            earnings: [
                "Basic Pay": 50000,
                "DA": 30000,
                "MSP": 20000
            ],
            deductions: ["DSOP": 10000]
        )

        XCTAssertLessThanOrEqual(result.overall, 1.0, "Overall confidence should never exceed 1.0")

        for (_, confidence) in result.fieldLevel {
            XCTAssertLessThanOrEqual(confidence, 1.0, "Field confidence should never exceed 1.0")
        }
    }

    func testBoundary_ConfidenceNeverBelowZero() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "",
            year: 1800,
            credits: -1000,
            debits: -2000,
            earnings: [:],
            deductions: [:]
        )

        XCTAssertGreaterThanOrEqual(result.overall, 0.0, "Overall confidence should never be negative")

        for (_, confidence) in result.fieldLevel {
            XCTAssertGreaterThanOrEqual(confidence, 0.0, "Field confidence should never be negative")
        }
    }
}

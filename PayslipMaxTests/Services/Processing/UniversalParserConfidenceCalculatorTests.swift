import XCTest
@testable import PayslipMax

/// Unit tests for UniversalParserConfidenceCalculator
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

    // MARK: - Month Field Tests

    func testMonthField_ValidFullName_FullConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JANUARY",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["month"], 1.0, "Valid month name should have 100% confidence")
    }

    func testMonthField_ValidAbbreviation_HighConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JAN",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["month"], 0.95, "Abbreviated month should have 95% confidence")
    }

    func testMonthField_Unknown_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "Unknown",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["month"], 0.1, "Unknown month should have 10% confidence")
    }

    func testMonthField_Empty_NoConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["month"], 0.0, "Empty month should have 0% confidence")
    }

    func testMonthField_PartialMatch_MediumConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUN",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertGreaterThanOrEqual(result.fieldLevel["month"] ?? 0, 0.7, "Partial month match should have >=70% confidence")
    }

    // MARK: - Year Field Tests

    func testYearField_CurrentYear_FullConfidence() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: currentYear,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["year"], 1.0, "Current year should have 100% confidence")
    }

    func testYearField_ValidRange_FullConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2020,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["year"], 1.0, "Year 2020 should have 100% confidence")
    }

    func testYearField_OldYear_MediumConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2010,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["year"], 0.7, "Year 2010 should have 70% confidence (suspicious but possible)")
    }

    func testYearField_VeryOldYear_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 1990,
            credits: 50000,
            debits: 10000,
            earnings: ["Basic Pay": 50000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["year"], 0.2, "Year 1990 should have 20% confidence (likely incorrect)")
    }

    // MARK: - Amount Field Tests

    func testAmountField_ValidPositive_FullConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 60000.0,
            debits: 10000.0,
            earnings: ["Basic Pay": 60000],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["credits"], 1.0, "Valid positive amount should have 100% confidence")
    }

    func testAmountField_Zero_LowConfidenceForCriticalFields() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 0.0,
            debits: 5000.0,
            earnings: [:],
            deductions: ["DSOP": 5000]
        )

        XCTAssertEqual(result.fieldLevel["credits"], 0.2, "Zero credits should have 20% confidence")
    }

    func testAmountField_Negative_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: -5000.0,
            debits: 0,
            earnings: [:],
            deductions: [:]
        )

        XCTAssertEqual(result.fieldLevel["credits"], 0.3, "Negative amount should have 30% confidence")
    }

    func testAmountField_VeryHigh_GoodConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 12000000.0, // 1.2 crore
            debits: 100000,
            earnings: ["Basic Pay": 12000000],
            deductions: ["DSOP": 100000]
        )

        XCTAssertEqual(result.fieldLevel["credits"], 0.8, "Very high amount should have 80% confidence")
    }

    // MARK: - Dictionary Field Tests

    func testEarnings_AllNonZero_FullConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 75000,
            debits: 10000,
            earnings: [
                "Basic Pay": 42000.0,
                "DA": 20000.0,
                "MSP": 13000.0
            ],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["earnings"], 1.0, "All non-zero earnings should have 100% confidence")
    }

    func testEarnings_SomeZeros_MediumConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 42000,
            debits: 10000,
            earnings: [
                "Basic Pay": 42000.0,
                "DA": 0.0,
                "MSP": 0.0
            ],
            deductions: ["DSOP": 10000]
        )

        let earningsConfidence = result.fieldLevel["earnings"] ?? 0
        XCTAssertEqual(earningsConfidence, 0.6, "Earnings with some zeros (1/3 valid) should have 0.6 confidence")
    }

    func testEarnings_Empty_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 10000,
            earnings: [:],
            deductions: ["DSOP": 10000]
        )

        XCTAssertEqual(result.fieldLevel["earnings"], 0.2, "Empty earnings should have 20% confidence")
    }

    func testDeductions_Empty_AcceptableConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 0,
            earnings: ["Basic Pay": 50000],
            deductions: [:]
        )

        XCTAssertEqual(result.fieldLevel["deductions"], 0.8, "Empty deductions should have 80% confidence (valid scenario)")
    }

    func testDeductions_AllZeros_LowConfidence() {
        let result = UniversalParserConfidenceCalculator.calculateConfidence(
            month: "JUNE",
            year: 2025,
            credits: 50000,
            debits: 0,
            earnings: ["Basic Pay": 50000],
            deductions: [
                "DSOP": 0.0,
                "ITAX": 0.0,
                "AGIF": 0.0
            ]
        )

        XCTAssertEqual(result.fieldLevel["deductions"], 0.3, "All-zero deductions should have 30% confidence")
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

        XCTAssertGreaterThan(result.overall, 0.9, "Mixed quality parse with perfect core fields should have >90% confidence")
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

        XCTAssertLessThan(result.fieldLevel["netRemittance"] ?? 1.0, 0.5, "Negative net remittance should have low confidence")
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

        XCTAssertEqual(result.fieldLevel["basicPay"] ?? 1.0, 0.2, "Missing basic pay should have 20% confidence")
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

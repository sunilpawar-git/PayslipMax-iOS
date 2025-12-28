import XCTest
@testable import PayslipMax

// MARK: - Amount and Dictionary Field Tests

extension UniversalParserConfidenceCalculatorTests {

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
        XCTAssertEqual(
            earningsConfidence, 0.6,
            "Earnings with some zeros (1/3 valid) should have 0.6 confidence"
        )
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

        XCTAssertEqual(
            result.fieldLevel["deductions"], 0.8,
            "Empty deductions should have 80% confidence (valid scenario)"
        )
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
}


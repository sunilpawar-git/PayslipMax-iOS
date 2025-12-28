import XCTest
@testable import PayslipMax

// MARK: - Month and Year Field Tests

extension UniversalParserConfidenceCalculatorTests {

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

        XCTAssertGreaterThanOrEqual(
            result.fieldLevel["month"] ?? 0, 0.7,
            "Partial month match should have >=70% confidence"
        )
    }

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

        XCTAssertEqual(
            result.fieldLevel["year"], 0.7,
            "Year 2010 should have 70% confidence (suspicious but possible)"
        )
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

        XCTAssertEqual(
            result.fieldLevel["year"], 0.2,
            "Year 1990 should have 20% confidence (likely incorrect)"
        )
    }
}


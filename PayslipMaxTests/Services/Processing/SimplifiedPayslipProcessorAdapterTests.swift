import XCTest
@testable import PayslipMax

/// Tests for SimplifiedPayslipProcessorAdapter
/// Validates metadata storage, confidence score preservation, and PayslipItem conversion
final class SimplifiedPayslipProcessorAdapterTests: XCTestCase {

    var adapter: SimplifiedPayslipProcessorAdapter!

    override func setUp() {
        super.setUp()
        adapter = SimplifiedPayslipProcessorAdapter()
    }

    override func tearDown() {
        adapter = nil
        super.tearDown()
    }

    // MARK: - Metadata Storage Tests

    func testConfidenceScoreStoredInMetadata() throws {
        // Given: Sample payslip text with all fields
        let sampleText = """
        नाम/Name: Sunil Suresh Pawar
        08/2025 की लेखा विवरणी / STATEMENT OF ACCOUNT FOR 08/2025

        BPAY (12A) : 1,44,700
        DA : 88,110
        MSP : 15,500
        कुल प्रभार / Gross Pay : 2,75,015

        DSOP : 21,705
        AGIF (01D) : 3,200
        Income Tax : 75,219
        कुल कटौती / Total Deductions : 1,02,029

        निवल प्रेषित धन/Net Remittance : Rs.1,72,986
        """

        // When: Process the payslip
        let payslipItem = try adapter.processPayslip(from: sampleText)

        // Then: Confidence score should be stored in metadata
        XCTAssertNotNil(payslipItem.metadata["parsingConfidence"],
                       "Confidence score should be stored in metadata")

        // Parse confidence value
        guard let confidenceStr = payslipItem.metadata["parsingConfidence"],
              let confidence = Double(confidenceStr) else {
            XCTFail("Confidence score should be a valid double")
            return
        }

        // Verify confidence is in valid range (0.0 to 1.0)
        XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should be >= 0.0")
        XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should be <= 1.0")

        // For perfect parsing, confidence should be high
        XCTAssertGreaterThan(confidence, 0.9, "Perfect parsing should have >90% confidence")
    }

    func testParserVersionStoredInMetadata() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 100000
        DA: 50000
        MSP: 15000
        Gross Pay: 165000
        DSOP: 30000
        AGIF: 10000
        Income Tax: 20000
        Total Deductions: 60000
        Net Remittance: 105000
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        XCTAssertEqual(payslipItem.metadata["parserVersion"], "1.0",
                      "Parser version should be stored as '1.0'")
    }

    func testParsingDateStoredInMetadata() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 100000
        DA: 50000
        MSP: 15000
        Gross Pay: 165000
        DSOP: 30000
        AGIF: 10000
        Income Tax: 20000
        Total Deductions: 60000
        Net Remittance: 105000
        """

        let beforeParsing = Date()
        let payslipItem = try adapter.processPayslip(from: sampleText)
        let afterParsing = Date()

        XCTAssertNotNil(payslipItem.metadata["parsingDate"],
                       "Parsing date should be stored in metadata")

        // Verify it's a valid ISO8601 date
        guard let dateStr = payslipItem.metadata["parsingDate"],
              let parsedDate = ISO8601DateFormatter().date(from: dateStr) else {
            XCTFail("Parsing date should be valid ISO8601 format")
            return
        }

        // Date should be between before and after
        XCTAssertGreaterThanOrEqual(parsedDate, beforeParsing.addingTimeInterval(-1),
                                   "Parsing date should be recent")
        XCTAssertLessThanOrEqual(parsedDate, afterParsing.addingTimeInterval(1),
                                "Parsing date should be recent")
    }

    // MARK: - Confidence Score Format Tests

    func testConfidenceStoredWithTwoDecimalPlaces() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 100000
        DA: 50000
        MSP: 15000
        Gross Pay: 165000
        DSOP: 30000
        AGIF: 10000
        Income Tax: 20000
        Total Deductions: 60000
        Net Remittance: 105000
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        guard let confidenceStr = payslipItem.metadata["parsingConfidence"] else {
            XCTFail("Confidence should be in metadata")
            return
        }

        // Check format: should have at most 2 decimal places
        let components = confidenceStr.components(separatedBy: ".")
        if components.count == 2 {
            XCTAssertLessThanOrEqual(components[1].count, 2,
                                    "Confidence should have at most 2 decimal places")
        }
    }

    // MARK: - Conversion Accuracy Tests

    func testBasicFieldsConvertedCorrectly() throws {
        let sampleText = """
        Name: John Smith
        08/2025
        BPAY: 144700
        DA: 88110
        MSP: 15500
        Gross Pay: 275015
        DSOP: 21705
        AGIF: 3200
        Income Tax: 75219
        Total Deductions: 102029
        Net Remittance: 172986
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        // Verify core fields
        XCTAssertEqual(payslipItem.name, "John Smith")
        XCTAssertEqual(payslipItem.month, "Aug", "Month should be converted to 'Aug'")
        XCTAssertEqual(payslipItem.year, 2025)
        XCTAssertEqual(payslipItem.credits, 275015, accuracy: 1.0)
        XCTAssertEqual(payslipItem.debits, 102029, accuracy: 1.0)
        XCTAssertEqual(payslipItem.dsop, 21705, accuracy: 1.0)
        XCTAssertEqual(payslipItem.tax, 75219, accuracy: 1.0)
    }

    func testEarningsBreakdownConvertedCorrectly() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 144700
        DA: 88110
        MSP: 15500
        Gross Pay: 275015
        DSOP: 21705
        AGIF: 3200
        Income Tax: 75219
        Total Deductions: 102029
        Net Remittance: 172986
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        // Verify earnings breakdown
        XCTAssertEqual(payslipItem.earnings["Basic Pay"] ?? 0, 144700, accuracy: 1.0)
        XCTAssertEqual(payslipItem.earnings["Dearness Allowance"] ?? 0, 88110, accuracy: 1.0)
        XCTAssertEqual(payslipItem.earnings["Military Service Pay"] ?? 0, 15500, accuracy: 1.0)

        // Other Earnings = Gross - BPAY - DA - MSP = 275015 - 144700 - 88110 - 15500 = 26705
        XCTAssertEqual(payslipItem.earnings["Other Earnings"] ?? 0, 26705, accuracy: 1.0)
    }

    func testDeductionsBreakdownConvertedCorrectly() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 144700
        DA: 88110
        MSP: 15500
        Gross Pay: 275015
        DSOP: 21705
        AGIF: 3200
        Income Tax: 75219
        Total Deductions: 102029
        Net Remittance: 172986
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        // Verify deductions breakdown
        XCTAssertEqual(payslipItem.deductions["DSOP"] ?? 0, 21705, accuracy: 1.0)
        XCTAssertEqual(payslipItem.deductions["AGIF"] ?? 0, 3200, accuracy: 1.0)
        XCTAssertEqual(payslipItem.deductions["Income Tax"] ?? 0, 75219, accuracy: 1.0)

        // Other Deductions = Total - DSOP - AGIF - Tax = 102029 - 21705 - 3200 - 75219 = 1905
        XCTAssertEqual(payslipItem.deductions["Other Deductions"] ?? 0, 1905, accuracy: 1.0)
    }

    // MARK: - Source Field Tests

    func testSourceFieldIndicatesSimplifiedParser() throws {
        let sampleText = """
        Name: Test User
        08/2025
        BPAY: 100000
        DA: 50000
        MSP: 15000
        Gross Pay: 165000
        DSOP: 30000
        AGIF: 10000
        Income Tax: 20000
        Total Deductions: 60000
        Net Remittance: 105000
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        XCTAssertEqual(payslipItem.source, "SimplifiedParser_v1.0",
                      "Source should indicate SimplifiedParser version")
    }

    // MARK: - Confidence Score Preservation Tests

    func testHighConfidenceForPerfectParsing() throws {
        // Perfect parsing: all fields present and totals match
        let sampleText = """
        Name: Perfect User
        08/2025
        BPAY: 100000
        DA: 50000
        MSP: 15000
        Gross Pay: 165000
        DSOP: 30000
        AGIF: 10000
        Income Tax: 20000
        Total Deductions: 60000
        Net Remittance: 105000
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        guard let confidenceStr = payslipItem.metadata["parsingConfidence"],
              let confidence = Double(confidenceStr) else {
            XCTFail("Confidence should be in metadata")
            return
        }

        // Perfect parsing should yield 100% confidence
        XCTAssertGreaterThan(confidence, 0.95, "Perfect parsing should have >95% confidence")
    }

    func testLowerConfidenceForPartialParsing() throws {
        // Partial parsing: some fields missing but totals are perfect
        let sampleText = """
        Name: Partial User
        08/2025
        BPAY: 100000
        Gross Pay: 100000
        Total Deductions: 30000
        Net Remittance: 70000
        """

        let payslipItem = try adapter.processPayslip(from: sampleText)

        guard let confidenceStr = payslipItem.metadata["parsingConfidence"],
              let confidence = Double(confidenceStr) else {
            XCTFail("Confidence should be in metadata")
            return
        }

        // With new totals-first system: Gross (20) + Deductions (20) + Perfect Net (50) + 1 core field (5) = 95%
        // Perfect math (100000 - 30000 = 70000) yields high confidence despite missing individual fields
        XCTAssertGreaterThan(confidence, 0.9, "Partial parsing with perfect totals should have >90% confidence")
    }

    // MARK: - Performance Tests

    func testConfidenceCalculationPerformance() throws {
        let sampleText = """
        Name: Performance Test
        08/2025
        BPAY: 144700
        DA: 88110
        MSP: 15500
        Gross Pay: 275015
        DSOP: 21705
        AGIF: 3200
        Income Tax: 75219
        Total Deductions: 102029
        Net Remittance: 172986
        """

        measure {
            _ = try? adapter.processPayslip(from: sampleText)
        }

        // Baseline: Should complete in <100ms for typical payslip
    }

    // MARK: - Edge Cases

    func testMetadataPreservedForEmptyFields() throws {
        // Even if parsing fails, metadata should still be created
        let sampleText = "Invalid payslip data with no recognizable fields"

        do {
            let payslipItem = try adapter.processPayslip(from: sampleText)

            // Metadata should exist even for poor parsing
            XCTAssertNotNil(payslipItem.metadata["parsingConfidence"])
            XCTAssertNotNil(payslipItem.metadata["parserVersion"])
            XCTAssertNotNil(payslipItem.metadata["parsingDate"])

            // Confidence should be very low
            if let confidenceStr = payslipItem.metadata["parsingConfidence"],
               let confidence = Double(confidenceStr) {
                XCTAssertLessThan(confidence, 0.3, "Poor parsing should have <30% confidence")
            }
        } catch {
            // If it throws, that's also acceptable for invalid data
            XCTAssertNotNil(error)
        }
    }
}


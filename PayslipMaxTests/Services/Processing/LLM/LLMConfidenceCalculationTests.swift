import XCTest
@testable import PayslipMax

/// Unit tests for LLM confidence calculation in LLMPayslipParser
/// Tests the private calculateConfidence method through public parse method
final class LLMConfidenceCalculationTests: XCTestCase {

    // MARK: - Test Helpers

    /// Helper to create a mock LLM response
    private func createMockResponse(
        month: String? = "JUNE",
        year: Int? = 2025,
        netRemittance: Double? = 50000,
        grossPay: Double? = 60000,
        totalDeductions: Double? = 10000,
        earnings: [String: Double]? = ["Basic Pay": 42000, "DA": 18000],
        deductions: [String: Double]? = ["DSOP": 10000]
    ) -> String {
        var json: [String: Any] = [:]

        if let month = month { json["month"] = month }
        if let year = year { json["year"] = year }
        if let netRemittance = netRemittance { json["netRemittance"] = netRemittance }
        if let grossPay = grossPay { json["grossPay"] = grossPay }
        if let totalDeductions = totalDeductions { json["totalDeductions"] = totalDeductions }
        if let earnings = earnings { json["earnings"] = earnings }
        if let deductions = deductions { json["deductions"] = deductions }

        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }

    // MARK: - Perfect Parse Tests

    func testPerfectLLMParse_AllFieldsPresent_HighConfidence() async throws {
        // Given: Mock LLM service that returns perfect data
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse()

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        // When: Parsing a payslip
        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Confidence should be very high (95% base for LLM)
        XCTAssertNotNil(payslipItem.confidenceScore, "Confidence score should be calculated")
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.95, accuracy: 0.01, "Perfect LLM parse should have 95% confidence")

        // Verify field-level confidences
        XCTAssertEqual(payslipItem.fieldConfidences?["month"], 1.0)
        XCTAssertEqual(payslipItem.fieldConfidences?["year"], 1.0)
        XCTAssertEqual(payslipItem.fieldConfidences?["netRemittance"], 1.0)
        XCTAssertEqual(payslipItem.fieldConfidences?["grossPay"], 1.0)
    }

    // MARK: - Missing Field Tests

    func testMissingMonth_ReducedConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(month: nil)

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Confidence reduced by 15% for missing month
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.80, accuracy: 0.01, "Missing month should reduce confidence to 80%")
        XCTAssertEqual(payslipItem.fieldConfidences?["month"], 0.0)
    }

    func testMissingYear_ReducedConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(year: nil)

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Confidence reduced by 15% for missing year
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.80, accuracy: 0.01, "Missing year should reduce confidence to 80%")
        XCTAssertEqual(payslipItem.fieldConfidences?["year"], 0.0)
    }

    func testMissingNetRemittance_MajorReduction() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(netRemittance: nil)

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Confidence reduced by 20% for missing net remittance (most critical)
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.75, accuracy: 0.01, "Missing net remittance should reduce confidence to 75%")
        XCTAssertEqual(payslipItem.fieldConfidences?["netRemittance"], 0.0)
    }

    func testMissingGrossPay_MinorReduction() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(grossPay: nil)

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Confidence reduced by 10% for missing gross pay
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.85, accuracy: 0.01, "Missing gross pay should reduce confidence to 85%")
    }

    // MARK: - Multiple Missing Fields Tests

    func testMultipleMissingFields_CompoundedReduction() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(
            month: nil,
            year: nil,
            netRemittance: nil
        )

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Then: Multiple penalties compound (-15% -15% -20% = -50%)
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.45, accuracy: 0.01, "Multiple missing fields should compound to 45%")
    }

    // MARK: - Empty/Zero Value Tests

    func testEmptyMonth_ReducedConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(month: "")

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.80, accuracy: 0.01, "Empty month should reduce confidence")
        XCTAssertEqual(payslipItem.fieldConfidences?["month"], 0.0)
    }

    func testZeroNetRemittance_ReducedConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(netRemittance: 0)

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.75, accuracy: 0.01, "Zero net remittance should reduce confidence")
        // Updated expectation: Shared FieldValidators returns 0.2 for critical zero fields (more consistent)
        XCTAssertEqual(payslipItem.fieldConfidences?["netRemittance"], 0.2, "Zero critical field should have 20% field confidence")
    }

    // MARK: - Earnings/Deductions Tests

    func testEmptyEarnings_ReducedConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(earnings: [:])

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.80, accuracy: 0.01, "Empty earnings should reduce confidence to 80%")
        XCTAssertEqual(payslipItem.fieldConfidences?["earnings"], 0.2)
    }

    func testPartialEarnings_MediumConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(
            earnings: [
                "Basic Pay": 42000,
                "DA": 0,
                "MSP": 0
            ]
        )

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Updated expectations: Shared FieldValidators is more lenient
        // 1 out of 3 values non-zero = 33% -> field confidence 0.6 (acceptable range)
        // No penalty triggered since 33% >= 30% threshold in shared validators
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.95, accuracy: 0.01, "Partial earnings above 30% threshold should not trigger penalty")

        let earningsConfidence = payslipItem.fieldConfidences?["earnings"] ?? 0
        XCTAssertEqual(earningsConfidence, 0.6, accuracy: 0.01, "33% non-zero ratio should have 60% field confidence")
    }

    func testEmptyDeductions_AcceptableConfidence() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(deductions: [:])

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        // Empty deductions is valid, should have 80% field confidence
        XCTAssertEqual(payslipItem.confidenceScore ?? 0.0, 0.95, accuracy: 0.01, "Empty deductions should not reduce overall confidence")
        XCTAssertEqual(payslipItem.fieldConfidences?["deductions"], 0.8)
    }

    // MARK: - Boundary Tests

    func testConfidenceNeverExceedsOne() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse()

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        XCTAssertLessThanOrEqual(payslipItem.confidenceScore ?? 0, 1.0, "Confidence should never exceed 1.0")

        for (_, confidence) in payslipItem.fieldConfidences ?? [:] {
            XCTAssertLessThanOrEqual(confidence, 1.0, "Field confidence should never exceed 1.0")
        }
    }

    func testConfidenceNeverBelowZero() async throws {
        let mockService = MockLLMService()
        mockService.mockResponse = createMockResponse(
            month: nil,
            year: nil,
            netRemittance: nil,
            grossPay: nil,
            earnings: [:],
            deductions: [:]
        )

        let mockRedactor = MockSelectiveRedactor()
        let parser = LLMPayslipParser(service: mockService, selectiveRedactor: mockRedactor)

        let payslipItem = try await parser.parse("Mock payslip text")

        XCTAssertGreaterThanOrEqual(payslipItem.confidenceScore ?? 0, 0.0, "Confidence should never be negative")

        for (_, confidence) in payslipItem.fieldConfidences ?? [:] {
            XCTAssertGreaterThanOrEqual(confidence, 0.0, "Field confidence should never be negative")
        }
    }
}

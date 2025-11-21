//
//  IntegrationTests.swift
//  PayslipMaxTests
//
//  End-to-End Integration Tests for LLM Parsing Pipeline
//

import XCTest
@testable import PayslipMax

final class IntegrationTests: XCTestCase {

    var anonymizer: PayslipAnonymizer!
    var mockLLMService: MockLLMSettingsService!
    var processor: HybridPayslipProcessor!

    override func setUp() {
        super.setUp()
        anonymizer = try! PayslipAnonymizer()
        mockLLMService = MockLLMSettingsService()

        // Configure mock service
        mockLLMService.isLLMEnabled = true
        mockLLMService.selectedProvider = .openai
        try? mockLLMService.setAPIKey("sk-mock-key", for: .openai)

        // Initialize processor with mock dependencies
        let mockRegex = MockRegexProcessor()

        processor = HybridPayslipProcessor(
            regexProcessor: mockRegex,
            settings: mockLLMService,
            llmFactory: { config in
                // Create a mock LLM parser adapter
                return MockLLMParserAdapter()
            }
        )
    }

    override func tearDown() {
        anonymizer = nil
        mockLLMService = nil
        processor = nil
        super.tearDown()
    }

    // MARK: - Privacy Verification

    func testAnonymizationBeforeLLM() throws {
        // Given
        let originalText = MockData.honeyPotText

        // When
        let anonymizedText = try anonymizer.anonymize(originalText)

        // Then
        // 1. Verify PII is removed
        XCTAssertFalse(anonymizedText.contains("John Doe"), "Name should be redacted")
        XCTAssertFalse(anonymizedText.contains("ABCDE1234F"), "PAN should be redacted")
        XCTAssertFalse(anonymizedText.contains("123456789012"), "Account number should be redacted")
        XCTAssertFalse(anonymizedText.contains("Bangalore, Karnataka"), "Location should be redacted")

        //2. Verify financial data is PRESERVED
        XCTAssertTrue(anonymizedText.contains("50,000") || anonymizedText.contains("50000"), "Basic Salary should be preserved")
        XCTAssertTrue(anonymizedText.contains("95,050") || anonymizedText.contains("95050"), "Net Pay should be preserved")
        XCTAssertTrue(anonymizedText.contains("June") || anonymizedText.contains("JUNE"), "Date should be preserved")
    }

    // MARK: - Mock LLM Flow

    func testMockLLMParsingFlow() async throws {
        // This test simulates the flow: Text -> Anonymizer -> Mock LLM -> JSON -> PayslipItem

        // 1. Call the processor directly (which handles the full flow)
        let result = try await processor.processPayslip(from: MockData.honeyPotText)

        // 2. Verify the returned PayslipItem
        let netPay = result.credits - result.debits
        XCTAssertEqual(netPay, 95050.0, accuracy: 0.01)
        XCTAssertEqual(result.credits, 106250.0) // Gross Pay

        // 3. Verify Earnings
        // Note: MockLLMParser returns data from MockData.expectedLLMResponse
        XCTAssertEqual(result.earnings["Basic Salary"], 50000.0)
        XCTAssertEqual(result.earnings["HRA"], 20000.0)
        XCTAssertEqual(result.earnings["Special Allowance"], 30000.0)

        // 4. Verify Deductions
        XCTAssertEqual(result.deductions["Provident Fund"], 6000.0)
        XCTAssertEqual(result.deductions["Income Tax"], 5000.0)

        // 5. Verify Month/Year
        XCTAssertEqual(result.month, "June")
    }

    // MARK: - Error Handling

    func testFallbackLogic() async throws {
        // Given: LLM is disabled
        mockLLMService.isLLMEnabled = false

        // When
        let result = try await processor.processPayslip(from: MockData.honeyPotText)

        // Then
        // Should return result from MockRegexProcessor
        // MockRegexProcessor returns 50000.0 for basic pay
        let netPay = result.credits - result.debits
        XCTAssertEqual(netPay, 50000.0, accuracy: 0.01)
        XCTAssertEqual(result.earnings["Basic Pay"], 50000.0)
    }

    // MARK: - Performance

    func testAnonymizationPerformance() {
        // Goal: Ensure anonymization takes less than 100ms for a standard payslip
        let text = MockData.honeyPotText

        measure {
            _ = try? anonymizer.anonymize(text)
        }
    }
}

//
//  HybridPayslipProcessorTests.swift
//  PayslipMaxTests
//
//  Tests for HybridPayslipProcessor
//

import XCTest
@testable import PayslipMax

final class HybridPayslipProcessorTests: XCTestCase {

    var hybridProcessor: HybridPayslipProcessor!
    var mockRegexProcessor: MockPayslipProcessor!
    var mockSettings: MockLLMSettingsService!
    var mockLLMService: MockLLMService!

    override func setUp() {
        super.setUp()
        mockRegexProcessor = MockPayslipProcessor()
        mockSettings = MockLLMSettingsService()
        mockLLMService = MockLLMService()

        hybridProcessor = HybridPayslipProcessor(
            regexProcessor: mockRegexProcessor,
            settings: mockSettings,
            llmFactory: { config in
                // Return a parser with mock service
                let parser = LLMPayslipParser(service: self.mockLLMService, anonymizer: MockPayslipAnonymizer())
                return parser
            }
        )
    }

    override func tearDown() {
        hybridProcessor = nil
        mockRegexProcessor = nil
        mockSettings = nil
        mockLLMService = nil
        super.tearDown()
    }

    func testLLMDisabled_ReturnsRegexResult() async throws {
        mockSettings.isLLMEnabled = false
        mockRegexProcessor.resultToReturn = createHighQualityItem()

        let result = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex")
        XCTAssertNil(mockLLMService.lastRequest) // LLM not called
    }

    func testLLMEnabled_HighQualityRegex_BackupMode_ReturnsRegexResult() async throws {
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true
        mockRegexProcessor.resultToReturn = createHighQualityItem()

        let result = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex")
        XCTAssertNil(mockLLMService.lastRequest) // LLM not called
    }

    func testLLMEnabled_LowQualityRegex_ReturnsLLMResult() async throws {
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true
        mockRegexProcessor.resultToReturn = createLowQualityItem()

        // Setup LLM response
        mockLLMService.mockResponse = """
        {
            "earnings": {"BPAY": 5000.0},
            "deductions": {"DSOP": 1000.0},
            "grossPay": 5000.0,
            "totalDeductions": 1000.0,
            "netRemittance": 4000.0,
            "month": "JUNE",
            "year": 2025
        }
        """

        let result = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertEqual(result.source, "LLM (mock)")
        XCTAssertNotNil(mockLLMService.lastRequest) // LLM called
    }

    func testLLMFails_ReturnsRegexResult() async throws {
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true
        mockRegexProcessor.resultToReturn = createLowQualityItem()

        // Setup LLM failure
        mockLLMService.shouldFail = true

        let result = try await hybridProcessor.processPayslip(from: "text")

        // Should fallback to regex result even if low quality
        XCTAssertEqual(result.source, "Regex")
    }

    // Helper methods to create items
    func createHighQualityItem() -> PayslipItem {
        return PayslipItem(
            month: "JAN", year: 2025,
            credits: 1000, debits: 300,  // Changed from 500 to 300 to match deductions sum
            dsop: 200, tax: 100,
            earnings: ["BPAY": 1000], deductions: ["DSOP": 200, "ITAX": 100],
            source: "Regex"
        )
    }

    func createLowQualityItem() -> PayslipItem {
        return PayslipItem(
            month: "JAN", year: 2025,
            credits: 0, debits: 0,
            dsop: 0, tax: 0,
            earnings: [:], deductions: [:], // Missing BPAY/DSOP
            source: "Regex"
        )
    }
}

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
    var mockDiagnosticsService: MockParsingDiagnosticsService!

    override func setUp() {
        super.setUp()
        mockRegexProcessor = MockPayslipProcessor()
        mockSettings = MockLLMSettingsService()
        mockLLMService = MockLLMService()
        mockDiagnosticsService = MockParsingDiagnosticsService()

        hybridProcessor = HybridPayslipProcessor(
            regexProcessor: mockRegexProcessor,
            settings: mockSettings,
            llmFactory: { config in
                // Return a parser with mock service
                let parser = LLMPayslipParser(service: self.mockLLMService, anonymizer: MockPayslipAnonymizer())
                return parser
            },
            diagnosticsService: mockDiagnosticsService
        )
    }

    override func tearDown() {
        hybridProcessor = nil
        mockRegexProcessor = nil
        mockSettings = nil
        mockLLMService = nil
        mockDiagnosticsService = nil
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

    // MARK: - Diagnostics Integration Tests

    func testProcessPayslip_ResetsSessionOnStart() async throws {
        mockSettings.isLLMEnabled = false
        mockRegexProcessor.resultToReturn = createHighQualityItem()

        _ = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertTrue(mockDiagnosticsService.resetSessionCalled)
    }

    func testMissingBPAY_RecordsMandatoryMissing() async throws {
        // LLM must be enabled for confidence calculation to run
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true

        let itemWithoutBPAY = PayslipItem(
            month: "JAN", year: 2025,
            credits: 1000, debits: 300,
            dsop: 200, tax: 100,
            earnings: ["DA": 500], deductions: ["DSOP": 200, "ITAX": 100],
            source: "Regex"
        )
        mockRegexProcessor.resultToReturn = itemWithoutBPAY

        _ = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertTrue(mockDiagnosticsService.recordedMandatoryMissing.contains("BPAY"))
    }

    func testMissingDSOP_RecordsMandatoryMissing() async throws {
        // LLM must be enabled for confidence calculation to run
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true

        // Item with BPAY but NO DSOP in deductions dictionary
        // Note: The dsop property value (0) doesn't matter - only the deductions dict is checked
        let itemWithoutDSOP = PayslipItem(
            month: "JAN", year: 2025,
            credits: 1000, debits: 100,
            dsop: 0, tax: 100,
            earnings: ["BPAY": 1000],
            deductions: ["ITAX": 100],  // No DSOP or AFPP Fund key
            source: "Regex"
        )
        mockRegexProcessor.resultToReturn = itemWithoutDSOP

        _ = try await hybridProcessor.processPayslip(from: "text")

        // DSOP should be recorded as missing since deductions dict lacks DSOP/AFPP Fund
        XCTAssertTrue(
            mockDiagnosticsService.recordedMandatoryMissing.contains("DSOP"),
            "Expected DSOP to be recorded as missing. Recorded: \(mockDiagnosticsService.recordedMandatoryMissing)"
        )
    }

    // MARK: - Confidence Scoring Tests

    func testExcellentConfidence_SkipsLLM() async throws {
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = false
        // High quality item with all components matching
        mockRegexProcessor.resultToReturn = createHighQualityItem()

        let result = try await hybridProcessor.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex")
        XCTAssertNil(mockLLMService.lastRequest) // LLM should not be called
    }

    func testTotalsMismatch_WithinNearMissRange_RecordsNearMiss() async throws {
        // LLM must be enabled for confidence calculation to run
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = true

        // Item with 2% mismatch - clearly within 1-5% near-miss range
        // credits = 100000, earningsSum = 98000 → 2% error
        // debits = 30000, deductionsSum = 29400 → 2% error
        let itemWithMismatch = PayslipItem(
            month: "JAN", year: 2025,
            credits: 100000, debits: 30000,
            dsop: 10000, tax: 5000,
            earnings: ["BPAY": 60000, "DA": 38000],  // Sum = 98000 (2% less than 100000)
            deductions: ["DSOP": 10000, "ITAX": 5000, "AGIF": 14400], // Sum = 29400 (2% less than 30000)
            source: "Regex"
        )
        mockRegexProcessor.resultToReturn = itemWithMismatch

        _ = try await hybridProcessor.processPayslip(from: "text")

        // Should record near-miss since error is between 1-5%
        // Note: Near-miss is only recorded when maxErrorPercent > 0.01 and <= 0.05
        XCTAssertFalse(
            mockDiagnosticsService.recordedNearMissTotals.isEmpty,
            "Expected near-miss to be recorded. Recorded count: \(mockDiagnosticsService.recordedNearMissTotals.count)"
        )
    }

    // MARK: - Additional Helper Methods

    func createMediumQualityItem() -> PayslipItem {
        // Has BPAY and DSOP but slight totals mismatch
        return PayslipItem(
            month: "JAN", year: 2025,
            credits: 100000, debits: 30000,
            dsop: 10000, tax: 5000,
            earnings: ["BPAY": 60000, "DA": 38000], // 2% off
            deductions: ["DSOP": 10000, "ITAX": 5000, "AGIF": 14400], // 2% off
            source: "Regex"
        )
    }
}

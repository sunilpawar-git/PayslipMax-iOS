//
//  HybridPayslipProcessorProxyTests.swift
//  PayslipMaxTests
//
//  Ensures backend-proxy style configs still run selective redaction before LLM
//

import XCTest
@testable import PayslipMax

final class HybridPayslipProcessorProxyTests: XCTestCase {

    func testRedactionRunsWhenProxyEnabledAndLLMDisabled() async throws {
        let regexProcessor = MockPayslipProcessor()
        let diagnostics = MockParsingDiagnosticsService()
        let settings = BackendProxySettingsMock()
        settings.isLLMEnabled = false
        settings.useAsBackupOnly = true

        var item = PayslipItem(
            month: "AUGUST",
            year: 2025,
            credits: 86953,
            debits: 58252,
            dsop: 2220,
            tax: 0,
            earnings: ["DA": 1800], // Missing BPAY
            deductions: ["AGIF": 1088], // Missing ITAX/DSOP
            source: "Regex"
        )
        item.metadata["anchors.present"] = "true"
        item.metadata["anchors.isNetDerived"] = "false"
        regexProcessor.resultToReturn = item

        let spyRedactor = SpySelectiveRedactor()
        let service = MockLLMService()
        service.mockResponse = """
        {
            "earnings": {"BPAY": 50000, "DA": 1800},
            "deductions": {"ITAX": 1200, "AGIF": 1088},
            "grossPay": 50000,
            "totalDeductions": 2288,
            "netRemittance": 47712,
            "month": "AUGUST",
            "year": 2025
        }
        """

        let processor = HybridPayslipProcessor(
            regexProcessor: regexProcessor,
            settings: settings,
            llmFactory: { _ in
                LLMPayslipParser(service: service, selectiveRedactor: spyRedactor)
            },
            diagnosticsService: diagnostics
        )

        let result = try await processor.processPayslip(from: "text")

        XCTAssertTrue(spyRedactor.redactCalled, "Selective redaction should run before LLM")
        XCTAssertEqual(result.source, "LLM (mock)")
    }
}

// MARK: - Test Doubles

private final class BackendProxySettingsMock: LLMSettingsServiceProtocol {
    var isLLMEnabled: Bool = false
    var selectedProvider: LLMProvider = .gemini
    var useAsBackupOnly: Bool = true

    func getAPIKey(for provider: LLMProvider) -> String? { "backend-proxy" }
    func setAPIKey(_ key: String, for provider: LLMProvider) throws {}

    func getConfiguration() -> LLMConfiguration? {
        LLMConfiguration(
            provider: selectedProvider,
            apiKey: "backend-proxy",
            model: "gemini-2.5-flash-lite",
            temperature: 0.0,
            maxTokens: 1000
        )
    }
}

private final class SpySelectiveRedactor: SelectiveRedactorProtocol {
    private(set) var redactCalled = false
    var lastRedactionReport: RedactionReport?

    func redact(_ text: String) throws -> String {
        redactCalled = true
        return "***REDACTED*** \(text)"
    }
}


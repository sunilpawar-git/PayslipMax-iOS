import XCTest
@testable import PayslipMax

final class DiagnosticsServiceRedactionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Ensure a clean slate
        DiagnosticsService.shared.reset()
        FeatureFlagManager.shared.resetFeature(.localDiagnostics)
        FeatureFlagManager.shared.toggleFeature(.localDiagnostics, enabled: true)
        waitUntilFlag(.localDiagnostics, isEnabled: true)
    }

    override func tearDown() {
        DiagnosticsService.shared.reset()
        FeatureFlagManager.shared.resetFeature(.localDiagnostics)
        super.tearDown()
    }

    func testExportBundleContainsNoPIIFields() throws {
        // Given: representative events
        let decision = ExtractionDecision(
            pageCount: 5,
            estimatedSizeBytes: 1_024_000,
            contentComplexity: "mixed",
            hasScannedContent: true,
            availableMemoryMB: 2048,
            estimatedMemoryNeedMB: 512,
            memoryPressureRatio: 0.25,
            processorCoreCount: 6,
            selectedStrategy: "StreamingPDF+OCRFallback",
            confidence: 0.82,
            reasoning: "Large pages, moderate OCR likelihood, device memory ok",
            useParallelProcessing: true,
            useAdaptiveBatching: true,
            maxConcurrentOperations: 3,
            memoryThresholdMB: 800,
            preprocessText: true
        )
        DiagnosticsService.shared.recordExtractionDecision(decision)

        let agg = ParseTelemetryAggregate(
            attempts: 3,
            successRate: 0.66,
            averageProcessingTimeSec: 6.4,
            fastestParserName: "PCDATableParserV1",
            fastestParserTimeSec: 4.1,
            mostReliableParserName: "HeuristicParser",
            mostReliableParserSuccessRate: 0.75
        )
        DiagnosticsService.shared.recordParseTelemetryAggregate(agg)
        // Allow async queue to flush
        waitUntilEventsCount(atLeast: 2)

        // When: export bundle
        guard let data = DiagnosticsService.shared.exportBundle() else {
            return XCTFail("Expected diagnostics bundle data")
        }

        // Then: schema snapshot contains only expected keys, and no obvious PII markers
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        // Spot-check for PII-like fields that should never appear (use precise tokens)
        let forbiddenPIIFragments = [
            "accountNumber", "pan", "aadhaar", "ssn", "email", "phoneNumber",
            "addressLine", "firstName", "lastName", "fullName"
        ]
        for fragment in forbiddenPIIFragments {
            XCTAssertFalse(jsonString.contains(fragment), "Diagnostics export should not contain PII fragment: \(fragment)")
        }

        // Verify minimal schema presence
        XCTAssertTrue(jsonString.contains("\"version\""))
        XCTAssertTrue(jsonString.contains("\"createdAt\""))
        XCTAssertTrue(jsonString.contains("\"events\""))
    }

    // MARK: - Helpers
    private func waitUntilFlag(_ feature: Feature, isEnabled expected: Bool, timeout: TimeInterval = 2.0) {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if FeatureFlagManager.shared.isEnabled(feature) == expected { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    private func waitUntilEventsCount(atLeast minCount: Int, timeout: TimeInterval = 2.0) {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if let data = DiagnosticsService.shared.exportBundle(),
               let bundle = try? JSONDecoder().decode(DiagnosticsBundle.self, from: data),
               bundle.events.count >= minCount {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }
}



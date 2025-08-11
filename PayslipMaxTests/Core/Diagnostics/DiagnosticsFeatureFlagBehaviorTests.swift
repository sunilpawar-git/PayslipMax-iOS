import XCTest
@testable import PayslipMax

final class DiagnosticsFeatureFlagBehaviorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DiagnosticsService.shared.reset()
        FeatureFlagManager.shared.resetFeature(.localDiagnostics)
    }

    override func tearDown() {
        DiagnosticsService.shared.reset()
        FeatureFlagManager.shared.resetFeature(.localDiagnostics)
        super.tearDown()
    }

    func testDiagnosticsDisabled_NoEventsRecorded() {
        // Given: diagnostics feature off
        FeatureFlagManager.shared.toggleFeature(.localDiagnostics, enabled: false)
        // Wait until flag is applied
        waitUntilFlag(.localDiagnostics, isEnabled: false)

        DiagnosticsService.shared.recordExtractionDecision(ExtractionDecision(
            pageCount: 1,
            estimatedSizeBytes: 100,
            contentComplexity: "simple",
            hasScannedContent: false,
            availableMemoryMB: 1024,
            estimatedMemoryNeedMB: 128,
            memoryPressureRatio: 0.1,
            processorCoreCount: 4,
            selectedStrategy: "Simple",
            confidence: 1.0,
            reasoning: "",
            useParallelProcessing: false,
            useAdaptiveBatching: false,
            maxConcurrentOperations: 1,
            memoryThresholdMB: 256,
            preprocessText: false
        ))

        let data = DiagnosticsService.shared.exportBundle()
        // Expect either nil or empty events array
        if let data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let bundle = try? decoder.decode(DiagnosticsBundle.self, from: data)
            XCTAssertEqual(bundle?.events.count, 0, "No events should be recorded when feature is disabled")
        } else {
            XCTAssertNil(data)
        }
    }

    func testDiagnosticsEnabled_EventsAreRecorded() throws {
        // Given: diagnostics feature on
        FeatureFlagManager.shared.toggleFeature(.localDiagnostics, enabled: true)
        waitUntilFlag(.localDiagnostics, isEnabled: true)

        DiagnosticsService.shared.recordParseTelemetryAggregate(ParseTelemetryAggregate(
            attempts: 2,
            successRate: 1.0,
            averageProcessingTimeSec: 1.2,
            fastestParserName: nil,
            fastestParserTimeSec: nil,
            mostReliableParserName: nil,
            mostReliableParserSuccessRate: nil
        ))

        // Wait for async append to complete
        waitUntilEventsCount(atLeast: 1)

        guard let data = DiagnosticsService.shared.exportBundle() else {
            return XCTFail("Expected diagnostics bundle data when enabled")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(DiagnosticsBundle.self, from: data)
        XCTAssertGreaterThan(bundle.events.count, 0, "Events should be recorded when feature is enabled")
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



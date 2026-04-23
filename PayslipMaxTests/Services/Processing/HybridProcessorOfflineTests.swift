import XCTest
@testable import PayslipMax

/// Tests for HybridPayslipProcessor behavior when offline mode is enabled.
/// Verifies: cloud LLM is blocked, confidence thresholds are relaxed,
/// on-device LLM is still attempted, and guarded fallback is offline-safe.
final class HybridProcessorOfflineTests: XCTestCase {

    private var mockRegex: MockPayslipProcessor!
    private var mockSettings: MockLLMSettingsService!
    private var mockLLM: MockLLMService!
    private var mockDiag: MockParsingDiagnosticsService!
    private var mockOnDevice: MockOnDeviceLLMService!
    private var offlineService: OfflineModeService!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockRegex = MockPayslipProcessor()
        mockSettings = MockLLMSettingsService()
        mockLLM = MockLLMService()
        mockDiag = MockParsingDiagnosticsService()
        mockOnDevice = MockOnDeviceLLMService()
        defaults = UserDefaults(suiteName: "HybridOfflineTests")!
        defaults.removePersistentDomain(forName: "HybridOfflineTests")
        offlineService = OfflineModeService(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "HybridOfflineTests")
        mockRegex = nil
        mockSettings = nil
        mockLLM = nil
        mockDiag = nil
        mockOnDevice = nil
        offlineService = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Cloud LLM Blocking

    func test_offlineMode_blocksCloudLLM_evenWhenLLMEnabled() async throws {
        offlineService.isOfflineModeEnabled = true
        mockSettings.isLLMEnabled = true

        let sut = makeProcessor()
        mockRegex.resultToReturn = makeLowQualityItem()
        setupMockLLMResponse()

        let result = try await sut.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex", "Cloud LLM should be blocked in offline mode")
        XCTAssertNil(mockLLM.lastRequest, "Cloud LLM should not be called in offline mode")
    }

    func test_onlineMode_allowsCloudLLM() async throws {
        offlineService.isOfflineModeEnabled = false
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = false

        let sut = makeProcessor(onDevice: nil)
        mockRegex.resultToReturn = makeLowQualityItem()
        setupMockLLMResponse()

        let result = try await sut.processPayslip(from: "text")

        XCTAssertEqual(result.source, "LLM (mock)")
    }

    // MARK: - On-Device LLM Still Works Offline

    func test_offlineMode_stillTriesOnDeviceLLM() async throws {
        offlineService.isOfflineModeEnabled = true
        mockSettings.isLLMEnabled = true
        mockSettings.useAsBackupOnly = false
        mockOnDevice.mockResult = MockOnDeviceLLMService.makeDefaultResult()

        let sut = makeProcessor()
        mockRegex.resultToReturn = makeLowQualityItem()

        let result = try await sut.processPayslip(from: "text")

        XCTAssertTrue(result.credits > 0, "On-device LLM should produce a valid result")
    }

    // MARK: - Relaxed Confidence in Offline Mode

    func test_offlineMode_moderateQualityRegex_returnsRegexWithoutLLM() async throws {
        offlineService.isOfflineModeEnabled = true
        mockSettings.isLLMEnabled = true

        let sut = makeProcessor(onDevice: nil)
        mockRegex.resultToReturn = makeModerateQualityItem()
        setupMockLLMResponse()

        let result = try await sut.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex")
        XCTAssertNil(mockLLM.lastRequest, "Moderate quality regex should be trusted in offline mode")
    }

    // MARK: - Guarded Fallback Offline Safety

    func test_offlineMode_guardedFallback_skipsCloudLLM() async throws {
        offlineService.isOfflineModeEnabled = true
        mockSettings.isLLMEnabled = true

        let sut = makeProcessor(onDevice: nil)
        let item = PayslipItem(
            month: "AUG", year: 2025,
            credits: 86953, debits: 58252,
            dsop: 2220, tax: 0,
            earnings: ["DA": 1800, "MSP": 1800],
            deductions: ["AGIF": 1088, "DSOP": 2220],
            source: "Regex"
        )
        item.metadata["anchors.present"] = "true"
        item.metadata["anchors.isNetDerived"] = "false"
        mockRegex.resultToReturn = item
        setupMockLLMResponse()

        let result = try await sut.processPayslip(from: "text")

        XCTAssertEqual(result.source, "Regex")
        XCTAssertNil(mockLLM.lastRequest, "Guarded fallback should NOT use cloud LLM in offline mode")
    }

    func test_offlineMode_guardedFallback_usesOnDeviceLLMIfAvailable() async throws {
        offlineService.isOfflineModeEnabled = true
        mockSettings.isLLMEnabled = true
        mockOnDevice.mockResult = MockOnDeviceLLMService.makeDefaultResult()

        let sut = makeProcessor()
        let item = PayslipItem(
            month: "AUG", year: 2025,
            credits: 86953, debits: 58252,
            dsop: 2220, tax: 0,
            earnings: ["DA": 1800, "MSP": 1800],
            deductions: ["AGIF": 1088, "DSOP": 2220],
            source: "Regex"
        )
        item.metadata["anchors.present"] = "true"
        item.metadata["anchors.isNetDerived"] = "false"
        mockRegex.resultToReturn = item

        let result = try await sut.processPayslip(from: "text")

        XCTAssertTrue(result.credits > 0, "Guarded fallback should use on-device in offline mode")
        XCTAssertNil(mockLLM.lastRequest)
    }

    // MARK: - Helpers

    private func makeProcessor(
        onDevice: MockOnDeviceLLMService? = nil
    ) -> HybridPayslipProcessor {
        let device = onDevice ?? mockOnDevice
        return HybridPayslipProcessor(
            regexProcessor: mockRegex,
            settings: mockSettings,
            llmFactory: { [weak self] config in
                guard let self else { return nil }
                return LLMPayslipParser(
                    service: self.mockLLM,
                    anonymizer: MockPayslipAnonymizer()
                )
            },
            onDeviceService: device,
            offlineModeService: offlineService,
            diagnosticsService: mockDiag
        )
    }

    private func makeLowQualityItem() -> PayslipItem {
        PayslipItem(
            month: "JAN", year: 2025,
            credits: 0, debits: 0,
            dsop: 0, tax: 0,
            earnings: [:], deductions: [:],
            source: "Regex"
        )
    }

    private func makeModerateQualityItem() -> PayslipItem {
        PayslipItem(
            month: "JAN", year: 2025,
            credits: 100000, debits: 30000,
            dsop: 10000, tax: 5000,
            earnings: ["BPAY": 60000, "DA": 40000],
            deductions: ["DSOP": 10000, "ITAX": 5000, "AGIF": 15000],
            source: "Regex"
        )
    }

    private func setupMockLLMResponse() {
        mockLLM.mockResponse = """
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
    }
}

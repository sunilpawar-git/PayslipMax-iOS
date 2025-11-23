//
//  LLMSettingsViewModelTests.swift
//  PayslipMaxTests
//
//  Tests for LLMSettingsViewModel
//

import XCTest
@testable import PayslipMax

@MainActor
final class LLMSettingsViewModelTests: XCTestCase {

    var viewModel: LLMSettingsViewModel!
    var mockSettings: MockLLMSettingsService!
    var mockRateLimiter: MockLLMRateLimiter!

    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockLLMSettingsService()
        mockRateLimiter = MockLLMRateLimiter()
        viewModel = LLMSettingsViewModel(settingsService: mockSettings, rateLimiter: mockRateLimiter)
    }

    override func tearDown() {
        viewModel = nil
        mockSettings = nil
        mockRateLimiter = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_LoadsSettingsFromService() {
        mockSettings.isLLMEnabled = true
        mockSettings.selectedProvider = .gemini
        mockSettings.useAsBackupOnly = false

        let vm = LLMSettingsViewModel(settingsService: mockSettings)

        XCTAssertTrue(vm.isLLMEnabled)
        XCTAssertEqual(vm.selectedProvider, .gemini)
        XCTAssertFalse(vm.useAsBackupOnly)
    }

    func testInit_LoadsUsageStats() async {
        mockRateLimiter.hourlyCount = 3
        mockRateLimiter.yearlyCount = 10

        let vm = LLMSettingsViewModel(settingsService: mockSettings, rateLimiter: mockRateLimiter)

        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        await vm.refreshUsageStats()

        XCTAssertEqual(vm.callsThisHour, 3)
        XCTAssertEqual(vm.callsThisYear, 10)
    }

    // MARK: - Save Settings Tests

    func testSaveSettings_UpdatesService() async {
        viewModel.isLLMEnabled = true
        viewModel.selectedProvider = .gemini
        viewModel.useAsBackupOnly = false

        await viewModel.saveSettings()

        XCTAssertTrue(mockSettings.isLLMEnabled)
        XCTAssertEqual(mockSettings.selectedProvider, .gemini)
        XCTAssertFalse(mockSettings.useAsBackupOnly)
    }

    // MARK: - Usage Stats Tests

    func testRefreshUsageStats_UpdatesProperties() async {
        mockRateLimiter.hourlyCount = 5
        mockRateLimiter.yearlyCount = 25

        await viewModel.refreshUsageStats()

        XCTAssertEqual(viewModel.callsThisHour, 5)
        XCTAssertEqual(viewModel.callsThisYear, 25)
        XCTAssertEqual(viewModel.remainingCallsYearly, 25) // 50 - 25
    }

    // MARK: - Privacy Info Tests

    func testShowPrivacyInfo_Toggle() {
        XCTAssertFalse(viewModel.showPrivacyInfo)

        viewModel.showPrivacyInfo = true
        XCTAssertTrue(viewModel.showPrivacyInfo)

        viewModel.showPrivacyInfo = false
        XCTAssertFalse(viewModel.showPrivacyInfo)
    }
}

// MARK: - Mocks

class MockLLMRateLimiter: LLMRateLimiterProtocol {
    var hourlyCount = 0
    var yearlyCount = 0

    func canMakeRequest() async -> Bool { return true }
    func recordRequest() async {}
    func timeUntilNextRequest() async -> TimeInterval? { return nil }
    func remainingRequestsThisHour() async -> Int { return 5 - hourlyCount }
    func remainingRequestsThisYear() async -> Int { return 50 - yearlyCount }
    func resetLimits() async {}

    func getHourlyCallCount() async -> Int { return hourlyCount }
    func getYearlyCallCount() async -> Int { return yearlyCount }
}

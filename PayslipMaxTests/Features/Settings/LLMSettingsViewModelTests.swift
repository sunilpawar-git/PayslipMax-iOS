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

    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockLLMSettingsService()
        viewModel = LLMSettingsViewModel(settingsService: mockSettings)
    }

    override func tearDown() {
        viewModel = nil
        mockSettings = nil
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

    func testInit_LoadsAPIKeyForCurrentProvider() {
        mockSettings.apiKey = "test-key-123"
        mockSettings.selectedProvider = .openai

        let vm = LLMSettingsViewModel(settingsService: mockSettings)

        XCTAssertEqual(vm.apiKey, "test-key-123")
    }

    // MARK: - API Key Validation Tests

    func testValidateAPIKey_EmptyKey_ReturnsFalse() {
        viewModel.apiKey = ""

        XCTAssertFalse(viewModel.validateAPIKey())
        XCTAssertEqual(viewModel.validationMessage, "API key cannot be empty")
    }

    func testValidateAPIKey_OpenAI_InvalidPrefix_ReturnsFalse() {
        viewModel.selectedProvider = .openai
        viewModel.apiKey = "invalid-key-123456789012345"

        XCTAssertFalse(viewModel.validateAPIKey())
        XCTAssertEqual(viewModel.validationMessage, "OpenAI API keys should start with 'sk-'")
    }

    func testValidateAPIKey_OpenAI_TooShort_ReturnsFalse() {
        viewModel.selectedProvider = .openai
        viewModel.apiKey = "sk-short"

        XCTAssertFalse(viewModel.validateAPIKey())
        XCTAssertEqual(viewModel.validationMessage, "OpenAI API key appears too short")
    }

    func testValidateAPIKey_OpenAI_Valid_ReturnsTrue() {
        viewModel.selectedProvider = .openai
        viewModel.apiKey = "sk-1234567890123456789012345678901234567890"

        XCTAssertTrue(viewModel.validateAPIKey())
        XCTAssertNil(viewModel.validationMessage)
    }

    func testValidateAPIKey_Gemini_TooShort_ReturnsFalse() {
        viewModel.selectedProvider = .gemini
        viewModel.apiKey = "short"

        XCTAssertFalse(viewModel.validateAPIKey())
        XCTAssertEqual(viewModel.validationMessage, "Gemini API key appears too short")
    }

    func testValidateAPIKey_Gemini_Valid_ReturnsTrue() {
        viewModel.selectedProvider = .gemini
        viewModel.apiKey = "AIzaSy1234567890123456789012345678901"

        XCTAssertTrue(viewModel.validateAPIKey())
        XCTAssertNil(viewModel.validationMessage)
    }

    func testValidateAPIKey_Anthropic_ReturnsFalse() {
        viewModel.selectedProvider = .anthropic
        viewModel.apiKey = "anthropic-key-12345678901234567890"

        XCTAssertFalse(viewModel.validateAPIKey())
        XCTAssertEqual(viewModel.validationMessage, "Anthropic is not yet supported")
    }

    // MARK: - Save Settings Tests

    func testSaveSettings_UpdatesService() async {
        viewModel.isLLMEnabled = true
        viewModel.selectedProvider = .gemini
        viewModel.useAsBackupOnly = false
        viewModel.apiKey = "test-gemini-key-12345678901234"

        await viewModel.saveSettings()

        XCTAssertTrue(mockSettings.isLLMEnabled)
        XCTAssertEqual(mockSettings.selectedProvider, .gemini)
        XCTAssertFalse(mockSettings.useAsBackupOnly)
        XCTAssertEqual(mockSettings.apiKey, "test-gemini-key-12345678901234")
    }

    func testSaveSettings_EmptyAPIKey_DoesNotSave() async {
        viewModel.apiKey = ""
        let initialKey = mockSettings.apiKey

        await viewModel.saveSettings()

        // Since apiKey is empty, setAPIKey should not be called, so mock's apiKey should remain unchanged
        XCTAssertEqual(mockSettings.apiKey, initialKey)
    }

    // MARK: - Provider Change Tests

    func testProviderChange_LoadsNewAPIKey() {
        //Mock returns same key for all providers currently - test that key is loaded
        mockSettings.apiKey = "test-key"
        viewModel.selectedProvider = .openai

        // Changing provider should trigger key load
        mockSettings.selectedProvider = .gemini
        viewModel.selectedProvider = .gemini

        // Key should be loaded (even if same key because mock doesn't distinguish)
        XCTAssertEqual(viewModel.apiKey, "test-key")
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

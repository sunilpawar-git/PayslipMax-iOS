//
//  LLMSettingsServiceTests.swift
//  PayslipMaxTests
//
//  Tests for LLMSettingsService
//

import XCTest
@testable import PayslipMax

final class LLMSettingsServiceTests: XCTestCase {

    var settingsService: LLMSettingsService!
    var mockKeychain: MockSecureStorage!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        // Use a unique suite name for isolated testing
        let suiteName = "com.payslipmax.tests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        mockKeychain = MockSecureStorage()

        settingsService = LLMSettingsService(
            userDefaults: userDefaults,
            keychain: mockKeychain
        )
    }

    override func tearDown() {
        // Clean up
        if let suiteName = userDefaults.dictionaryRepresentation().keys.first {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        settingsService = nil
        mockKeychain = nil
        userDefaults = nil
        super.tearDown()
    }

    // MARK: - UserDefaults Tests

    func testIsLLMEnabled_DefaultIsFalse() {
        XCTAssertFalse(settingsService.isLLMEnabled)
    }

    func testIsLLMEnabled_SetAndGet() {
        settingsService.isLLMEnabled = true
        XCTAssertTrue(settingsService.isLLMEnabled)

        settingsService.isLLMEnabled = false
        XCTAssertFalse(settingsService.isLLMEnabled)
    }

    func testSelectedProvider_DefaultIsGemini() {
        XCTAssertEqual(settingsService.selectedProvider, .gemini)
    }

    func testSelectedProvider_SetAndGet() {
        // Test default is Gemini (tested in separate test)
        // Test setting to Mock provider
        settingsService.selectedProvider = .mock
        XCTAssertEqual(settingsService.selectedProvider, .mock)

        // Test setting back to Gemini
        settingsService.selectedProvider = .gemini
        XCTAssertEqual(settingsService.selectedProvider, .gemini)
    }

    func testUseAsBackupOnly_DefaultIsTrue() {
        XCTAssertTrue(settingsService.useAsBackupOnly)
    }

    func testUseAsBackupOnly_SetAndGet() {
        settingsService.useAsBackupOnly = false
        XCTAssertFalse(settingsService.useAsBackupOnly)

        settingsService.useAsBackupOnly = true
        XCTAssertTrue(settingsService.useAsBackupOnly)
    }

    // MARK: - API Key Tests (Centralized)

    func testGetAPIKey_MockProvider_ReturnsMockKey() {
        let key = settingsService.getAPIKey(for: .mock)
        XCTAssertEqual(key, "mock_api_key")
    }

    func testSetAPIKey_IsNoOp() throws {
        // Should not throw and should log warning (not verifiable here but ensures no crash)
        try settingsService.setAPIKey("some-key", for: .gemini)
    }

    // MARK: - Configuration Tests

    func testGetConfiguration_LLMDisabled_ReturnsNil() {
        settingsService.isLLMEnabled = false
        XCTAssertNil(settingsService.getConfiguration())
    }

    func testGetConfiguration_Mock_Success() throws {
        settingsService.isLLMEnabled = true
        settingsService.selectedProvider = .mock

        let config = settingsService.getConfiguration()

        XCTAssertNotNil(config)
        XCTAssertEqual(config?.provider, .mock)
        XCTAssertEqual(config?.apiKey, "mock")
        XCTAssertEqual(config?.model, "mock")
    }
}

// MARK: - Mock Secure Storage

class MockSecureStorage: SecureStorageProtocol {
    private var storage: [String: Data] = [:]

    func saveData(key: String, data: Data) throws {
        storage[key] = data
    }

    func getData(key: String) throws -> Data? {
        return storage[key]
    }

    func saveString(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw NSError(domain: "MockError", code: -1)
        }
        try saveData(key: key, data: data)
    }

    func getString(key: String) throws -> String? {
        guard let data = try getData(key: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteItem(key: String) throws {
        storage.removeValue(forKey: key)
    }
}

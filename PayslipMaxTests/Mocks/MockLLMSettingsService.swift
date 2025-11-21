//
//  MockLLMSettingsService.swift
//  PayslipMaxTests
//
//  Mock implementation of LLMSettingsServiceProtocol
//

import Foundation
@testable import PayslipMax

final class MockLLMSettingsService: LLMSettingsServiceProtocol {
    var isLLMEnabled: Bool = false
    var selectedProvider: LLMProvider = .mock
    var useAsBackupOnly: Bool = true
    var apiKey: String? = "mock_key"

    func getAPIKey(for provider: LLMProvider) -> String? { return apiKey }
    func setAPIKey(_ key: String, for provider: LLMProvider) throws { apiKey = key }

    func getConfiguration() -> LLMConfiguration? {
        guard isLLMEnabled else { return nil }
        return LLMConfiguration(
            provider: selectedProvider,
            apiKey: apiKey ?? "",
            model: "mock",
            temperature: 0,
            maxTokens: 100
        )
    }
}

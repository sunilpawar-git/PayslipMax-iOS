//
//  LLMSettingsService.swift
//  PayslipMax
//
//  Manages configuration and secrets for LLM services
//

import Foundation
import OSLog

/// Protocol for managing LLM settings
protocol LLMSettingsServiceProtocol: AnyObject {
    var isLLMEnabled: Bool { get set }
    var selectedProvider: LLMProvider { get set }
    var useAsBackupOnly: Bool { get set }

    /// Securely stores/retrieves API key
    func getAPIKey(for provider: LLMProvider) -> String?
    func setAPIKey(_ key: String, for provider: LLMProvider) throws

    /// Returns full configuration for the selected provider
    func getConfiguration() -> LLMConfiguration?
}

/// Implementation of LLMSettingsService using UserDefaults and Keychain
final class LLMSettingsService: LLMSettingsServiceProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let keychain: SecureStorageProtocol
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Settings")

    // Keys for UserDefaults
    private enum Keys {
        static let isLLMEnabled = "llm_enabled"
        static let selectedProvider = "llm_provider"
        static let useAsBackupOnly = "llm_backup_only"
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard, keychain: SecureStorageProtocol) {
        self.userDefaults = userDefaults
        self.keychain = keychain
    }

    // MARK: - LLMSettingsServiceProtocol

    var isLLMEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isLLMEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.isLLMEnabled) }
    }

    var selectedProvider: LLMProvider {
        get {
            guard let string = userDefaults.string(forKey: Keys.selectedProvider),
                  let provider = LLMProvider(rawValue: string) else {
                return .openai // Default
            }
            return provider
        }
        set { userDefaults.set(newValue.rawValue, forKey: Keys.selectedProvider) }
    }

    var useAsBackupOnly: Bool {
        get {
            // Default to true (safer)
            if userDefaults.object(forKey: Keys.useAsBackupOnly) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.useAsBackupOnly)
        }
        set { userDefaults.set(newValue, forKey: Keys.useAsBackupOnly) }
    }

    func getAPIKey(for provider: LLMProvider) -> String? {
        do {
            return try keychain.getString(key: apiKeyKey(for: provider))
        } catch {
            logger.error("Failed to retrieve API key: \(error.localizedDescription)")
            return nil
        }
    }

    func setAPIKey(_ key: String, for provider: LLMProvider) throws {
        try keychain.saveString(key: apiKeyKey(for: provider), value: key)
    }

    func getConfiguration() -> LLMConfiguration? {
        guard isLLMEnabled else { return nil }

        let provider = selectedProvider
        guard let apiKey = getAPIKey(for: provider), !apiKey.isEmpty else {
            logger.warning("LLM enabled but no API key found for \(provider.rawValue)")
            return nil
        }

        switch provider {
        case .openai:
            return LLMConfiguration(
                provider: .openai,
                apiKey: apiKey,
                model: "gpt-4o-mini",
                temperature: 0.0,
                maxTokens: 1000
            )
        case .gemini:
            return LLMConfiguration(
                provider: .gemini,
                apiKey: apiKey,
                model: "gemini-1.5-flash",
                temperature: 0.0,
                maxTokens: 1000
            )
        case .anthropic:
            // Not implemented yet
            return nil
        case .mock:
             return LLMConfiguration(
                provider: .mock,
                apiKey: "mock",
                model: "mock",
                temperature: 0,
                maxTokens: 100
             )
        }
    }

    // MARK: - Helpers

    private func apiKeyKey(for provider: LLMProvider) -> String {
        return "llm_api_key_\(provider.rawValue)"
    }
}

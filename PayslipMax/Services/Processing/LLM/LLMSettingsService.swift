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
                return .gemini // Default to Gemini (primary provider)
            }

            // Migration: Force Gemini if OpenAI is selected (OpenAI support removed)
            if provider == .openai {
                logger.info("Migrating provider from OpenAI to Gemini (OpenAI removed from APIKeys)")
                self.selectedProvider = .gemini // Write new value
                return .gemini
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

    /// Get API key for the specified provider (centralized approach)
    /// - Parameter provider: The LLM provider
    /// - Returns: The API key from centralized configuration, or nil if not configured
    func getAPIKey(for provider: LLMProvider) -> String? {
        switch provider {
        case .gemini:
            let key = APIKeys.geminiAPIKey
            return APIKeys.isGeminiConfigured ? key : nil

        case .openai:
            let key = APIKeys.openAIAPIKey
            return APIKeys.isOpenAIConfigured ? key : nil

        case .anthropic:
            // Not implemented yet
            return nil

        case .mock:
            return "mock_api_key"
        }
    }

    /// Set API key (deprecated - centralized keys are now used)
    /// - Parameters:
    ///   - key: The API key (ignored in centralized mode)
    ///   - provider: The provider (ignored in centralized mode)
    /// - Note: This method is kept for backward compatibility but does nothing.
    ///         API keys are now managed in Config/APIKeys.swift
    func setAPIKey(_ key: String, for provider: LLMProvider) throws {
        logger.warning("setAPIKey called but centralized API keys are now used. Edit Config/APIKeys.swift instead.")
        // Do nothing - keys are centralized now
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
                model: "gemini-2.5-flash-lite",
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
    // Note: apiKeyKey() helper removed - using centralized API keys now
}

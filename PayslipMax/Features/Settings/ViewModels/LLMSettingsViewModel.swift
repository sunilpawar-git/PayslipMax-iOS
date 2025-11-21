//
//  LLMSettingsViewModel.swift
//  PayslipMax
//
//  ViewModel for LLM settings UI
//

import Foundation
import Combine
import OSLog

/// Protocol for LLM settings view model
@MainActor
protocol LLMSettingsViewModelProtocol: ObservableObject {
    var isLLMEnabled: Bool { get set }
    var selectedProvider: LLMProvider { get set }
    var apiKey: String { get set }
    var useAsBackupOnly: Bool { get set }
    var showPrivacyInfo: Bool { get set }
    var validationMessage: String? { get set }
    var isSaving: Bool { get }

    func saveSettings() async
    func validateAPIKey() -> Bool
}

/// ViewModel for managing LLM settings
@MainActor
final class LLMSettingsViewModel: LLMSettingsViewModelProtocol {

    // MARK: - Published Properties

    @Published var isLLMEnabled: Bool {
        didSet {
            if isLLMEnabled != oldValue {
                Task { await saveSettings() }
            }
        }
    }

    @Published var selectedProvider: LLMProvider {
        didSet {
            if selectedProvider != oldValue {
                // Load API key for new provider
                loadAPIKey(for: selectedProvider)
                Task { await saveSettings() }
            }
        }
    }

    @Published var apiKey: String = "" {
        didSet {
            validationMessage = nil
        }
    }

    @Published var useAsBackupOnly: Bool {
        didSet {
            if useAsBackupOnly != oldValue {
                Task { await saveSettings() }
            }
        }
    }

    @Published var showPrivacyInfo: Bool = false
    @Published var validationMessage: String?
    @Published var isSaving: Bool = false

    // MARK: - Dependencies

    private let settingsService: LLMSettingsServiceProtocol
    private let logger = os.Logger(subsystem: "com.payslipmax.settings", category: "LLM")

    // MARK: - Initialization

    init(settingsService: LLMSettingsServiceProtocol) {
        self.settingsService = settingsService

        // Load initial state from service
        self.isLLMEnabled = settingsService.isLLMEnabled
        self.selectedProvider = settingsService.selectedProvider
        self.useAsBackupOnly = settingsService.useAsBackupOnly

        // Load API key for current provider
        loadAPIKey(for: selectedProvider)

        logger.info("LLMSettingsViewModel initialized")
    }

    // MARK: - Public Methods

    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        // Save boolean settings (immediate)
        settingsService.isLLMEnabled = isLLMEnabled
        settingsService.selectedProvider = selectedProvider
        settingsService.useAsBackupOnly = useAsBackupOnly

        // Save API key to Keychain
        if !apiKey.isEmpty {
            do {
                try settingsService.setAPIKey(apiKey, for: selectedProvider)
                logger.info("API key saved for provider: \(self.selectedProvider.rawValue)")
                validationMessage = nil
            } catch {
                logger.error("Failed to save API key: \(error.localizedDescription)")
                validationMessage = "Failed to save API key securely"
            }
        }
    }

    func validateAPIKey() -> Bool {
        // Basic validation
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "API key cannot be empty"
            return false
        }

        // Provider-specific validation
        switch selectedProvider {
        case .openai:
            if !apiKey.hasPrefix("sk-") {
                validationMessage = "OpenAI API keys should start with 'sk-'"
                return false
            }
            if apiKey.count < 20 {
                validationMessage = "OpenAI API key appears too short"
                return false
            }

        case .gemini:
            if apiKey.count < 20 {
                validationMessage = "Gemini API key appears too short"
                return false
            }

        case .anthropic:
            validationMessage = "Anthropic is not yet supported"
            return false

        case .mock:
            // Mock provider for testing - always valid
            break
        }

        validationMessage = nil
        return true
    }

    // MARK: - Private Methods

    private func loadAPIKey(for provider: LLMProvider) {
        if let key = settingsService.getAPIKey(for: provider) {
            apiKey = key
        } else {
            apiKey = ""
        }
    }
}

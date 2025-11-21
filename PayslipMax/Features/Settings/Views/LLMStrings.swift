//
//  LLMStrings.swift
//  PayslipMax
//
//  Localized strings for LLM features
//

import Foundation

enum LLMStrings {
    // MARK: - Settings
    static let settingsTitle = "AI PARSING (EXPERIMENTAL)"
    static let enableTitle = "AI-Powered Parsing"
    static let enableSubtitle = "Use AI to improve accuracy"
    static let providerTitle = "AI Provider"
    static let apiKeyTitle = "API Key"
    static let apiKeyPlaceholder = "Enter %@ API key"
    static let backupModeTitle = "Use as Backup Only"
    static let backupModeSubtitle = "Only use AI if standard parsing fails"
    static let privacyTitle = "Privacy & Security"
    static let privacySubtitle = "How your data is protected"
    static let saveAPIKey = "Save API Key"
    static let configured = "Configured"
    static let notConfigured = "Not configured"

    // MARK: - Privacy Info
    static let privacySheetTitle = "Privacy Information"
    static let whatIsSentTitle = "What Data is Sent?"
    static let whatIsNotSentTitle = "What is NOT Sent?"
    static let howItWorksTitle = "How It Works"
    static let providerPrivacyTitle = "AI Provider Privacy"
    static let apiKeySecurityTitle = "API Key Security"
    static let apiKeySecurityBody = "Your API key is stored securely in the iOS Keychain and never leaves your device."
    static let providerPrivacyBody = "Anonymized data is processed by your selected AI provider (OpenAI or Google). Please review their privacy policies:"

    // MARK: - Validation
    static let emptyAPIKey = "API key cannot be empty"
    static let invalidOpenAIKey = "OpenAI API keys should start with 'sk-'"
    static let shortOpenAIKey = "OpenAI API key appears too short"
    static let shortGeminiKey = "Gemini API key appears too short"
    static let anthropicNotSupported = "Anthropic is not yet supported"
    static let saveFailed = "Failed to save API key securely"
}

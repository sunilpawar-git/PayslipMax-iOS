//
//  APIKeys.swift
//  PayslipMax
//
//  Centralized API key management
//  ⚠️ CRITICAL: Copy this to APIKeys.swift and fill in your keys!
//  DO NOT COMMIT APIKeys.swift - it's gitignored for security!
//

import Foundation

struct APIKeys {
    // MARK: - Gemini Configuration (Primary Provider)

    /// Gemini API Key - Get yours at: https://makersuite.google.com/app/apikey
    /// Set via environment variable: export GEMINI_API_KEY="your_key_here"
    static let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "YOUR_GEMINI_API_KEY_HERE"

    /// Check if Gemini is properly configured
    static var isGeminiConfigured: Bool {
        return !geminiAPIKey.isEmpty &&
               geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" &&
               geminiAPIKey.hasPrefix("AIza")
    }

    // MARK: - OpenAI Removed
    // OpenAI integration removed - using Gemini only

    static let openAIAPIKey = ""
    static var isOpenAIConfigured: Bool { false }
}

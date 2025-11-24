//
//  LLMModels.swift
//  PayslipMax
//
//  Data models for LLM interactions
//

import Foundation

/// Supported LLM Providers
public enum LLMProvider: String, Codable, CaseIterable {
    case gemini
    case mock // For testing
}

/// Configuration for LLM Service
public struct LLMConfiguration {
    let provider: LLMProvider
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int

    static let defaultGemini = LLMConfiguration(
        provider: .gemini,
        apiKey: "", // To be injected
        model: "gemini-2.5-flash-lite",
        temperature: 0.0,
        maxTokens: 1000
    )
}

/// Request sent to LLM
public struct LLMRequest {
    let prompt: String
    let systemPrompt: String?
    let jsonMode: Bool

    public init(prompt: String, systemPrompt: String? = nil, jsonMode: Bool = true) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.jsonMode = jsonMode
    }
}

/// Response from LLM
public struct LLMResponse {
    let content: String
    let usage: LLMUsage?
}

/// Token usage statistics
public struct LLMUsage {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

/// Errors that can occur during LLM interaction
enum LLMError: Error, LocalizedError {
    case invalidConfiguration
    case invalidAPIKey
    case networkError(Error)
    case decodingError(Error)
    case apiError(code: Int, message: String)
    case emptyResponse
    case unauthorized
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid LLM configuration"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .emptyResponse:
            return "Received empty response from LLM"
        case .unauthorized:
            return "Unauthorized: Check your API key"
        case .rateLimited:
            return "Rate limit exceeded"
        }
    }
}

//
//  LLMPricingConfiguration.swift
//  PayslipMax
//
//  Configuration for LLM provider pricing
//

import Foundation

/// Configuration for LLM pricing per provider
struct LLMPricingConfiguration: Codable {

    /// Gemini pricing configuration
    var gemini: ProviderPricing

    /// OpenAI pricing configuration
    var openai: ProviderPricing

    /// USD to INR conversion rate
    var usdToINR: Double

    /// Last updated timestamp
    var lastUpdated: Date

    // MARK: - Defaults

    /// Default pricing configuration (November 2024)
    /// Note: Gemini 2.5 Flash Lite pricing (approximate)
    /// Pricing as of November 2024
    static let `default` = LLMPricingConfiguration(
        gemini: ProviderPricing(
            inputPer1M: 0.10,    // $0.10/1M input tokens
            outputPer1M: 0.40    // $0.40/1M output tokens (2.5 Flash Lite)
        ),
        openai: ProviderPricing(
            inputPer1M: 0.15,    // $0.15/1M tokens
            outputPer1M: 0.60    // $0.60/1M tokens
        ),
        usdToINR: 83.5,
        lastUpdated: Date()
    )

    // MARK: - Persistence

    private static let userDefaultsKey = "llm_pricing_configuration"

    /// Load pricing configuration from UserDefaults, or use default if not found
    static func load() -> LLMPricingConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(LLMPricingConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    /// Save pricing configuration to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}

/// Pricing for a specific LLM provider
struct ProviderPricing: Codable {
    /// Cost per 1 million input tokens (USD)
    var inputPer1M: Double

    /// Cost per 1 million output tokens (USD)
    var outputPer1M: Double
}

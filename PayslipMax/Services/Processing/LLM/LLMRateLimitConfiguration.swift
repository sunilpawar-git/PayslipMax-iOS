//
//  LLMRateLimitConfiguration.swift
//  PayslipMax
//
//  Configuration for LLM rate limiting
//

import Foundation

/// Configuration for LLM rate limiting
struct LLMRateLimitConfiguration: Codable {

    /// Maximum LLM calls allowed per hour
    var maxCallsPerHour: Int

    /// Maximum LLM calls allowed per year
    var maxCallsPerYear: Int

    /// Minimum delay between LLM calls (in seconds)
    var minDelaySeconds: TimeInterval

    /// Whether rate limiting is enabled
    var isEnabled: Bool

    // MARK: - Defaults

    /// Default rate limit configuration
    /// NOTE: Rate limiting disabled for development. Re-enable for production.
    static let `default` = LLMRateLimitConfiguration(
        maxCallsPerHour: 999999,      // Unlimited for development
        maxCallsPerYear: 999999,       // Unlimited for development
        minDelaySeconds: 0,            // No delay for development
        isEnabled: false               // DISABLED for development
    )

    // MARK: - Persistence

    private static let userDefaultsKey = "llm_rate_limit_configuration"

    /// Load rate limit configuration from UserDefaults, or use default if not found
    static func load() -> LLMRateLimitConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(LLMRateLimitConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    /// Save rate limit configuration to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}

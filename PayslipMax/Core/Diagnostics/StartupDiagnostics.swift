//
//  StartupDiagnostics.swift
//  PayslipMax
//
//  Created for Phase 2: Development Infrastructure
//  Logs critical configuration at startup
//

import Foundation
import OSLog
import UIKit

/// Service to log critical configuration details at startup
@MainActor
final class StartupDiagnostics {

    private static let logger = os.Logger(subsystem: "com.payslipmax", category: "Startup")

    /// Logs current build configuration and environment details
    static func logConfiguration() {
        // Only run diagnostics in Debug builds or if explicitly enabled
        guard BuildConfiguration.isDebug else { return }

        logger.info("🔍 STARTUP DIAGNOSTICS")
        logger.info("==================================================")

        // 1. Build Environment
        logger.info("🛠️  Build Environment: DEBUG")
        logger.info("📱 Device: \(UIDevice.current.name) (\(UIDevice.current.systemName) \(UIDevice.current.systemVersion))")

        // 2. LLM Configuration
        let llmService = DIContainer.shared.makeLLMSettingsService()
        logger.info("🤖 LLM Enabled: \(llmService.isLLMEnabled)")
        logger.info("🔑 LLM Provider: \(llmService.selectedProvider.rawValue)")

        let rateLimitConfig = LLMRateLimitConfiguration.default
        logger.info("⚡ Rate Limiting: \(rateLimitConfig.isEnabled ? "ENABLED" : "DISABLED")")
        logger.info("   - Max/Hour: \(rateLimitConfig.maxCallsPerHour)")
        logger.info("   - Max/Year: \(rateLimitConfig.maxCallsPerYear)")

        // 3. Feature Flags
        logger.info("🚩 Feature Flags:")
        logger.info("   - Enhanced Dashboard: \(FeatureFlagConfiguration.shared.getDefaultState(for: .enhancedDashboard))")
        logger.info("   - Military Insights: \(FeatureFlagConfiguration.shared.getDefaultState(for: .militaryInsights))")

        // 4. Security
        logger.info("🔒 Security:")
        logger.info("   - Backend Proxy: \(BuildConfiguration.useBackendProxy ? "ENABLED" : "DISABLED")")

        logger.info("==================================================")
    }
}

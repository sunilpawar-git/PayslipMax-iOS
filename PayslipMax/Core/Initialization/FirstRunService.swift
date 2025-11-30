//
//  FirstRunService.swift
//  PayslipMax
//
//  Created for Phase 2: Development Infrastructure
//  Handles one-time setup on first app launch
//

import Foundation
import OSLog

/// Protocol for first-run initialization service
@MainActor
protocol FirstRunServiceProtocol {
    func performFirstRunSetupIfNeeded()
}

/// Service to handle first-run initialization logic
@MainActor
final class FirstRunService: FirstRunServiceProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let logger = os.Logger(subsystem: "com.payslipmax", category: "FirstRun")

    private enum Keys {
        static let hasLaunchedBefore = "app_has_launched_before"
        static let appVersion = "app_version_on_first_launch"
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Performs setup only on the very first launch of the app
    func performFirstRunSetupIfNeeded() {
        guard !hasLaunchedBefore else {
            logger.info("Not first launch, skipping initialization")
            return
        }

        logger.info("🚀 First launch detected - initializing defaults")

        // Set configuration defaults
        initializeLLMDefaults()
        initializeFeatureFlagDefaults()
        initializeAnalyticsDefaults()

        // Mark as launched
        userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
        userDefaults.set(appVersion, forKey: Keys.appVersion)

        logger.info("✅ First run initialization complete")
    }

    // MARK: - Private Helpers

    private var hasLaunchedBefore: Bool {
        userDefaults.bool(forKey: Keys.hasLaunchedBefore)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func initializeLLMDefaults() {
        // LLM defaults are now handled by BuildConfiguration in LLMSettingsService
        // But we can explicitly set them here if needed for persistence
        let llmService = DIContainer.shared.makeLLMSettingsService()

        // Force the default from BuildConfiguration to be persisted
        llmService.isLLMEnabled = BuildConfiguration.llmEnabledByDefault

        logger.debug("Initialized LLM defaults: Enabled=\(BuildConfiguration.llmEnabledByDefault)")
    }

    private func initializeFeatureFlagDefaults() {
        // Feature flags are currently hardcoded in FeatureFlagConfiguration
        // Future: Set dynamic feature flags here
        logger.debug("Initialized Feature Flag defaults")
    }

    private func initializeAnalyticsDefaults() {
        // Analytics defaults
        logger.debug("Initialized Analytics defaults")
    }
}

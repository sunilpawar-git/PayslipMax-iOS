import Foundation

/// Manages the configuration for feature flags, including default states and remote configuration.
class FeatureFlagConfiguration {
    /// Singleton instance of the configuration.
    static let shared = FeatureFlagConfiguration()

    /// Current default state for each feature.
    private var defaultStates: [Feature: Bool] = [
        // Core Features - Permanently enabled (hard-coded in implementation)
        // These flags are kept in config for UI compatibility but are always true
        .optimizedMilitaryParsing: true,
        .parallelizedTextExtraction: true,
        .enhancedPatternMatching: true,
        .simplifiedPayslipParsing: true,  // Simplified parser (10 essential fields vs 243 codes)
        .universalParsing: false,  // Universal parser with gradual rollout (controlled by UniversalParsingFeatureFlag)

        // UI Features - Permanently enabled (hard-coded in implementation)
        .enhancedDashboard: true,
        .militaryInsights: true,
        .pdfAnnotation: false,  // Not yet ready for production

        // Analytics Features - Permanently enabled (hard-coded in AnalyticsManager)
        .enhancedAnalytics: true,
        .dataAggregation: false,  // Requires explicit opt-in

        // Experimental Features - Disabled by default
        .aiCategorization: false,
        .smartCapture: false,
        .cloudBackup: false
    ]

    /// URL for remote configuration file.
    private let remoteConfigURL: URL? = URL(string: "https://api.payslipmax.com/configuration/feature-flags")

    /// Last time the configuration was refreshed.
    private var lastRefreshTime: Date?

    /// Category for logging.
    private let logCategory = "FeatureFlagConfiguration"

    /// Private initializer to enforce singleton pattern.
    private init() {
        loadLocalConfiguration()
    }

    /// Loads configuration from local storage.
    private func loadLocalConfiguration() {
        guard let data = UserDefaults.standard.data(forKey: "FeatureFlagConfiguration"),
              let storedStates = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return
        }

        for (key, value) in storedStates {
            if let feature = Feature(rawValue: key) {
                defaultStates[feature] = value
            }
        }

        Logger.info("Loaded feature flag configuration from local storage", category: logCategory)
    }

    /// Saves the current configuration to local storage.
    private func saveLocalConfiguration() {
        var storedStates: [String: Bool] = [:]

        for (feature, enabled) in defaultStates {
            storedStates[feature.rawValue] = enabled
        }

        if let data = try? JSONEncoder().encode(storedStates) {
            UserDefaults.standard.set(data, forKey: "FeatureFlagConfiguration")
            Logger.info("Saved feature flag configuration to local storage", category: logCategory)
        } else {
            Logger.error("Failed to save feature flag configuration", category: logCategory)
        }
    }

    /// Gets the default state for a feature.
    /// - Parameter feature: The feature to get the state for.
    /// - Returns: The default state of the feature.
    func getDefaultState(for feature: Feature) -> Bool {
        // Special handling for universal parsing - use dedicated feature flag
        if feature == .universalParsing {
            return UniversalParsingFeatureFlag.isEnabled()
        }

        return defaultStates[feature] ?? false
    }

    /// Sets the default state for a feature.
    /// - Parameters:
    ///   - feature: The feature to set the state for.
    ///   - enabled: Whether the feature should be enabled by default.
    func setDefaultState(for feature: Feature, enabled: Bool) {
        defaultStates[feature] = enabled
        saveLocalConfiguration()
    }

    /// Refreshes the configuration from the remote source.
    /// - Parameter completion: A closure to call when the refresh is complete, with a boolean indicating success.
    func refreshFromRemote(completion: @escaping (Bool) -> Void) {
        guard let url = remoteConfigURL else {
            Logger.error("Remote configuration URL is not set", category: logCategory)
            completion(false)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                Logger.error("Error refreshing feature flag configuration: \(error.localizedDescription)", category: self.logCategory)
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                Logger.error("Invalid response from feature flag configuration endpoint", category: self.logCategory)
                completion(false)
                return
            }

            do {
                let remoteStates = try JSONDecoder().decode([String: Bool].self, from: data)

                for (key, value) in remoteStates {
                    if let feature = Feature(rawValue: key) {
                        self.defaultStates[feature] = value
                    }
                }

                self.saveLocalConfiguration()
                self.lastRefreshTime = Date()

                Logger.info("Successfully refreshed feature flag configuration from remote", category: self.logCategory)
                completion(true)
            } catch {
                Logger.error("Failed to decode feature flag configuration: \(error.localizedDescription)", category: self.logCategory)
                completion(false)
            }
        }

        task.resume()
    }

    /// Gets the time of the last configuration refresh.
    /// - Returns: The date of the last refresh, or `nil` if the configuration has never been refreshed.
    func getLastRefreshTime() -> Date? {
        return lastRefreshTime
    }
}

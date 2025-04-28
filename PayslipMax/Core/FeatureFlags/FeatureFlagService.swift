import Foundation

/// Main service that provides feature flag functionality.
class FeatureFlagService: FeatureFlagProtocol {
    /// Singleton instance of the service.
    static let shared = FeatureFlagService()
    
    /// The configuration to use for default feature states.
    private let configuration: FeatureFlagConfiguration
    
    /// Dictionary of overrides for feature flags.
    private var overrides: [Feature: Bool] = [:]
    
    /// Dictionary of user-specific overrides for feature flags.
    private var userOverrides: [String: [Feature: Bool]] = [:]
    
    /// Category for logging.
    private let logCategory = "FeatureFlagService"
    
    /// The queue to use for thread-safe access to overrides.
    private let queue = DispatchQueue(label: "com.payslipmax.featureflags", attributes: .concurrent)
    
    /// Initializes a new feature flag service with the given configuration.
    /// - Parameter configuration: The configuration to use for default feature states.
    init(configuration: FeatureFlagConfiguration = FeatureFlagConfiguration.shared) {
        self.configuration = configuration
        loadOverrides()
    }
    
    /// Checks if a feature is enabled.
    /// - Parameter feature: The feature to check.
    /// - Returns: `true` if the feature is enabled, otherwise `false`.
    func isEnabled(_ feature: Feature) -> Bool {
        var result = false
        
        queue.sync {
            // Check if there's an override for this feature
            if let override = overrides[feature] {
                result = override
                return
            }
            
            // Otherwise, use the default state from configuration
            result = configuration.getDefaultState(for: feature)
        }
        
        return result
    }
    
    /// Checks if a feature is enabled for a specific user.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - userID: The ID of the user to check for.
    /// - Returns: `true` if the feature is enabled for the user, otherwise `false`.
    func isEnabled(_ feature: Feature, for userID: String) -> Bool {
        var result = false
        
        queue.sync {
            // Check if there's a user-specific override for this feature
            if let userFeatureOverrides = userOverrides[userID],
               let override = userFeatureOverrides[feature] {
                result = override
                return
            }
            
            // Check if there's a global override for this feature
            if let override = overrides[feature] {
                result = override
                return
            }
            
            // Otherwise, use the default state from configuration
            result = configuration.getDefaultState(for: feature)
        }
        
        return result
    }
    
    /// Overrides the state of a feature flag.
    /// - Parameters:
    ///   - feature: The feature to override.
    ///   - enabled: Whether the feature should be enabled or disabled.
    func setOverride(_ feature: Feature, enabled: Bool) {
        queue.async(flags: .barrier) {
            self.overrides[feature] = enabled
            self.saveOverrides()
            Logger.info("Set override for feature '\(feature.rawValue)' to \(enabled)", category: self.logCategory)
        }
    }
    
    /// Sets a user-specific override for a feature flag.
    /// - Parameters:
    ///   - feature: The feature to override.
    ///   - enabled: Whether the feature should be enabled or disabled.
    ///   - userID: The ID of the user to set the override for.
    func setUserOverride(_ feature: Feature, enabled: Bool, for userID: String) {
        queue.async(flags: .barrier) {
            var userFeatureOverrides = self.userOverrides[userID] ?? [:]
            userFeatureOverrides[feature] = enabled
            self.userOverrides[userID] = userFeatureOverrides
            self.saveOverrides()
            Logger.info("Set user override for feature '\(feature.rawValue)' to \(enabled) for user \(userID)", category: self.logCategory)
        }
    }
    
    /// Clears any override for a feature flag, returning it to its default state.
    /// - Parameter feature: The feature to clear the override for.
    func clearOverride(_ feature: Feature) {
        queue.async(flags: .barrier) {
            self.overrides.removeValue(forKey: feature)
            self.saveOverrides()
            Logger.info("Cleared override for feature '\(feature.rawValue)'", category: self.logCategory)
        }
    }
    
    /// Clears all feature flag overrides.
    func clearAllOverrides() {
        queue.async(flags: .barrier) {
            self.overrides.removeAll()
            self.saveOverrides()
            Logger.info("Cleared all feature overrides", category: self.logCategory)
        }
    }
    
    /// Clears a user-specific override for a feature flag.
    /// - Parameters:
    ///   - feature: The feature to clear the override for.
    ///   - userID: The ID of the user to clear the override for.
    func clearUserOverride(_ feature: Feature, for userID: String) {
        queue.async(flags: .barrier) {
            if var userFeatureOverrides = self.userOverrides[userID] {
                userFeatureOverrides.removeValue(forKey: feature)
                
                if userFeatureOverrides.isEmpty {
                    self.userOverrides.removeValue(forKey: userID)
                } else {
                    self.userOverrides[userID] = userFeatureOverrides
                }
                
                self.saveOverrides()
                Logger.info("Cleared user override for feature '\(feature.rawValue)' for user \(userID)", category: self.logCategory)
            }
        }
    }
    
    /// Clears all overrides for a specific user.
    /// - Parameter userID: The ID of the user to clear all overrides for.
    func clearAllUserOverrides(for userID: String) {
        queue.async(flags: .barrier) {
            self.userOverrides.removeValue(forKey: userID)
            self.saveOverrides()
            Logger.info("Cleared all user overrides for user \(userID)", category: self.logCategory)
        }
    }
    
    /// Refreshes the feature flag configuration from the remote source.
    /// - Parameter completion: A closure to call when the refresh is complete, with a boolean indicating success.
    func refreshConfiguration(completion: @escaping (Bool) -> Void) {
        configuration.refreshFromRemote(completion: completion)
    }
    
    /// Loads overrides from local storage.
    private func loadOverrides() {
        queue.async(flags: .barrier) {
            // Load global overrides
            if let data = UserDefaults.standard.data(forKey: "FeatureFlagOverrides"),
               let storedOverrides = try? JSONDecoder().decode([String: Bool].self, from: data) {
                for (key, value) in storedOverrides {
                    if let feature = Feature(rawValue: key) {
                        self.overrides[feature] = value
                    }
                }
                Logger.info("Loaded feature flag overrides from local storage", category: self.logCategory)
            }
            
            // Load user-specific overrides
            if let data = UserDefaults.standard.data(forKey: "FeatureFlagUserOverrides"),
               let storedUserOverrides = try? JSONDecoder().decode([String: [String: Bool]].self, from: data) {
                for (userID, featureOverrides) in storedUserOverrides {
                    var userFeatureOverrides: [Feature: Bool] = [:]
                    
                    for (key, value) in featureOverrides {
                        if let feature = Feature(rawValue: key) {
                            userFeatureOverrides[feature] = value
                        }
                    }
                    
                    if !userFeatureOverrides.isEmpty {
                        self.userOverrides[userID] = userFeatureOverrides
                    }
                }
                Logger.info("Loaded feature flag user overrides from local storage", category: self.logCategory)
            }
        }
    }
    
    /// Saves overrides to local storage.
    private func saveOverrides() {
        queue.async {
            // Save global overrides
            var storedOverrides: [String: Bool] = [:]
            for (feature, enabled) in self.overrides {
                storedOverrides[feature.rawValue] = enabled
            }
            
            if let data = try? JSONEncoder().encode(storedOverrides) {
                UserDefaults.standard.set(data, forKey: "FeatureFlagOverrides")
            }
            
            // Save user-specific overrides
            var storedUserOverrides: [String: [String: Bool]] = [:]
            for (userID, featureOverrides) in self.userOverrides {
                var storedFeatureOverrides: [String: Bool] = [:]
                
                for (feature, enabled) in featureOverrides {
                    storedFeatureOverrides[feature.rawValue] = enabled
                }
                
                storedUserOverrides[userID] = storedFeatureOverrides
            }
            
            if let data = try? JSONEncoder().encode(storedUserOverrides) {
                UserDefaults.standard.set(data, forKey: "FeatureFlagUserOverrides")
            }
        }
    }
} 
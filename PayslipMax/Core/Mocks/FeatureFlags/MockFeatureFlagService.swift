import Foundation

/// Mock implementation of FeatureFlagProtocol for testing purposes.
///
/// This mock service provides controllable behavior for testing feature flag functionality
/// without requiring actual feature flag configurations or external dependencies.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockFeatureFlagService: FeatureFlagProtocol {
    
    // MARK: - Properties
    
    /// Controls the default return value for feature flag checks
    var defaultEnabled: Bool = false
    
    /// Dictionary to override specific feature flags
    var featureOverrides: [Feature: Bool] = [:]
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        defaultEnabled = false
        featureOverrides = [:]
        shouldFail = false
    }
    
    // MARK: - FeatureFlagProtocol Implementation
    
    func isEnabled(_ feature: Feature) -> Bool {
        if shouldFail {
            return false
        }
        
        // Check if there's a specific override for this feature
        if let override = featureOverrides[feature] {
            return override
        }
        
        // Return default value
        return defaultEnabled
    }
    
    func isEnabled(_ feature: Feature, for userId: String) -> Bool {
        // For simplicity, delegate to the basic isEnabled method
        return isEnabled(feature)
    }
    
    func setOverride(_ feature: Feature, enabled: Bool) {
        featureOverrides[feature] = enabled
    }
    
    func clearOverride(_ feature: Feature) {
        featureOverrides.removeValue(forKey: feature)
    }
    
    func clearAllOverrides() {
        featureOverrides = [:]
    }
    
    func refreshConfiguration(completion: @escaping (Bool) -> Void) {
        // For testing, always succeed immediately
        completion(true)
    }
}

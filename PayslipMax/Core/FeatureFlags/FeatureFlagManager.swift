import Foundation
import SwiftUI

/// Provides a simplified interface for checking feature flags and controlling feature toggling in the UI.
class FeatureFlagManager {
    /// Singleton instance of the manager.
    static let shared = FeatureFlagManager()
    
    /// The feature flag service to use.
    private let featureFlagService: FeatureFlagService
    
    /// Category for logging.
    private let logCategory = "FeatureFlagManager"
    
    /// Initializes a new feature flag manager with the given service.
    /// - Parameter featureFlagService: The feature flag service to use.
    init(featureFlagService: FeatureFlagService = FeatureFlagService.shared) {
        self.featureFlagService = featureFlagService
    }
    
    /// Checks if a feature is enabled.
    /// - Parameter feature: The feature to check.
    /// - Returns: `true` if the feature is enabled, otherwise `false`.
    func isEnabled(_ feature: Feature) -> Bool {
        return featureFlagService.isEnabled(feature)
    }
    
    /// Evaluates whether code should be executed based on a feature flag.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - action: The closure to execute if the feature is enabled.
    func when(_ feature: Feature, action: () -> Void) {
        if isEnabled(feature) {
            action()
        }
    }
    
    /// Evaluates whether code should be executed based on a feature flag, with an else branch.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - action: The closure to execute if the feature is enabled.
    ///   - elseAction: The closure to execute if the feature is disabled.
    func when(_ feature: Feature, action: () -> Void, else elseAction: () -> Void) {
        if isEnabled(feature) {
            action()
        } else {
            elseAction()
        }
    }
    
    /// Returns one of two values based on a feature flag.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - trueValue: The value to return if the feature is enabled.
    ///   - falseValue: The value to return if the feature is disabled.
    /// - Returns: Either `trueValue` or `falseValue` depending on the feature state.
    func select<T>(_ feature: Feature, trueValue: T, falseValue: T) -> T {
        return isEnabled(feature) ? trueValue : falseValue
    }
    
    /// Refreshes the feature flag configuration from the remote source.
    /// - Parameter completion: A closure to call when the refresh is complete, with a boolean indicating success.
    func refreshConfiguration(completion: @escaping (Bool) -> Void = { _ in }) {
        featureFlagService.refreshConfiguration(completion: completion)
    }
    
    /// Enables or disables a feature flag for testing purposes.
    /// This only affects the current instance and is not persisted.
    /// - Parameters:
    ///   - feature: The feature to toggle.
    ///   - enabled: Whether the feature should be enabled or disabled.
    func toggleFeature(_ feature: Feature, enabled: Bool) {
        featureFlagService.setOverride(feature, enabled: enabled)
        Logger.info("Feature '\(feature.rawValue)' toggled \(enabled ? "ON" : "OFF")", category: logCategory)
    }
    
    /// Resets a feature flag to its default state for testing purposes.
    /// - Parameter feature: The feature to reset.
    func resetFeature(_ feature: Feature) {
        featureFlagService.clearOverride(feature)
        Logger.info("Feature '\(feature.rawValue)' reset to default state", category: logCategory)
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Shows this view only if the specified feature is enabled.
    /// - Parameter feature: The feature that must be enabled for the view to be shown.
    /// - Returns: Either this view or an empty view, depending on the feature state.
    func featureEnabled(_ feature: Feature) -> some View {
        return Group {
            if FeatureFlagManager.shared.isEnabled(feature) {
                self
            } else {
                EmptyView()
            }
        }
    }
    
    /// Shows this view only if the specified feature is disabled.
    /// - Parameter feature: The feature that must be disabled for the view to be shown.
    /// - Returns: Either this view or an empty view, depending on the feature state.
    func featureDisabled(_ feature: Feature) -> some View {
        return Group {
            if !FeatureFlagManager.shared.isEnabled(feature) {
                self
            } else {
                EmptyView()
            }
        }
    }
    
    /// Conditionally applies a modifier based on a feature flag.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - transform: The modifier to apply if the feature is enabled.
    /// - Returns: This view with the modifier applied if the feature is enabled, otherwise this view without the modifier.
    func featureConditional<T: View>(_ feature: Feature, transform: (Self) -> T) -> some View {
        return Group {
            if FeatureFlagManager.shared.isEnabled(feature) {
                transform(self)
            } else {
                self
            }
        }
    }
} 
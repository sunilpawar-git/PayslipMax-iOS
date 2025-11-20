import Foundation
import UIKit

/// Feature flag for Universal Parsing System migration
/// Allows gradual rollout with instant rollback capability
struct UniversalParsingFeatureFlag {

    // MARK: - Configuration Keys

    private static let rolloutPercentageKey = "universalParsingRolloutPercentage"
    private static let forceEnableKey = "forceUniversalParsing"
    private static let forceDisableKey = "disableUniversalParsing"

    // MARK: - Properties

    /// Percentage of users to enable universal parsing (0-100)
    static var rolloutPercentage: Int {
        UserDefaults.standard.integer(forKey: rolloutPercentageKey)
    }

    /// Force enable for testing (overrides percentage)
    static var forceEnable: Bool {
        UserDefaults.standard.bool(forKey: forceEnableKey)
    }

    /// Force disable for emergency rollback
    static var forceDisable: Bool {
        UserDefaults.standard.bool(forKey: forceDisableKey)
    }

    // MARK: - Public Methods

    /// Determines if universal parsing should be used
    /// - Returns: True if universal parsing should be enabled for this device
    static func isEnabled() -> Bool {
        // Emergency kill switch - highest priority
        if forceDisable {
            print("[UniversalParsingFeatureFlag] Universal parsing DISABLED (force disable)")
            return false
        }

        // Testing override - second priority
        if forceEnable {
            print("[UniversalParsingFeatureFlag] Universal parsing ENABLED (force enable)")
            return true
        }

        // Gradual rollout based on percentage - default behavior
        let percentage = rolloutPercentage
        guard percentage > 0 else {
            print("[UniversalParsingFeatureFlag] Universal parsing DISABLED (0% rollout)")
            return false
        }

        // Use device identifier for consistent bucketing
        // Same device always gets same decision for given percentage
        let deviceHash = abs(UIDevice.current.identifierForVendor?.hashValue ?? 0)
        let userBucket = deviceHash % 100
        let isEnabled = userBucket < percentage

        print("[UniversalParsingFeatureFlag] Universal parsing \(isEnabled ? "ENABLED" : "DISABLED") (bucket: \(userBucket), rollout: \(percentage)%)")
        return isEnabled
    }

    /// Sets the rollout percentage for gradual deployment
    /// - Parameter percentage: Percentage of users (0-100)
    static func setRolloutPercentage(_ percentage: Int) {
        let clampedPercentage = max(0, min(100, percentage))
        UserDefaults.standard.set(clampedPercentage, forKey: rolloutPercentageKey)
        print("[UniversalParsingFeatureFlag] Rollout percentage set to \(clampedPercentage)%")
    }

    /// Enables universal parsing for this device (testing only)
    static func enableForTesting() {
        UserDefaults.standard.set(true, forKey: forceEnableKey)
        print("[UniversalParsingFeatureFlag] Force enabled for testing")
    }

    /// Disables universal parsing for this device (emergency rollback)
    static func disableForEmergency() {
        UserDefaults.standard.set(true, forKey: forceDisableKey)
        print("[UniversalParsingFeatureFlag] Force disabled (emergency)")
    }

    /// Resets all flags to default state
    static func reset() {
        UserDefaults.standard.removeObject(forKey: rolloutPercentageKey)
        UserDefaults.standard.removeObject(forKey: forceEnableKey)
        UserDefaults.standard.removeObject(forKey: forceDisableKey)
        print("[UniversalParsingFeatureFlag] All flags reset to defaults")
    }
}

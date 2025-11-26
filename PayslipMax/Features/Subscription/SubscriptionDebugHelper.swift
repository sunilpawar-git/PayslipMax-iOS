import Foundation

/// Helper for managing subscription debug features
/// ONLY available in DEBUG builds
enum SubscriptionDebugHelper {
    /// Key for storing debug override status
    private static let debugOverrideKey = "debug_subscription_override"

    /// Check if subscription bypass is enabled
    static var isBypassEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: debugOverrideKey)
        #else
        return false
        #endif
    }

    /// Enable or disable subscription bypass
    /// - Parameter enabled: Whether bypass should be active
    static func setBypass(_ enabled: Bool) {
        #if DEBUG
        UserDefaults.standard.set(enabled, forKey: debugOverrideKey)
        print("Subscription Debug Bypass: \(enabled ? "ENABLED" : "DISABLED")")
        #endif
    }
}

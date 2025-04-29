import Foundation

/// A stub implementation of Firebase analytics for feature flag-based toggling
class FirebaseAnalyticsProvider {
    /// Shared instance for singleton access
    static let shared = FirebaseAnalyticsProvider()
    
    /// Category for logging
    private let logCategory = "FirebaseAnalyticsProvider"
    
    /// Private initializer to enforce singleton pattern
    private init() {
        Logger.info("Initialized Firebase Analytics Provider (Stub)", category: logCategory)
    }
    
    /// Logs an event with the specified name and parameters
    /// - Parameters:
    ///   - name: The name of the event to log
    ///   - parameters: Optional parameters to include with the event
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Logger.info("Analytics event: \(name) \(parameters ?? [:])", category: logCategory)
    }
    
    /// Sets a user property to the given value
    /// - Parameters:
    ///   - value: The value to set the user property to
    ///   - name: The name of the user property to set
    func setUserProperty(_ value: String?, forName name: String) {
        Logger.info("Set user property: \(name) = \(value ?? "nil")", category: logCategory)
    }
    
    /// Sets the user ID for the current user
    /// - Parameter userID: The ID to set for the current user
    func setUserID(_ userID: String?) {
        Logger.info("Set user ID: \(userID ?? "nil")", category: logCategory)
    }
} 
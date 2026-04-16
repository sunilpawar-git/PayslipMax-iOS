import Foundation

/// Protocol for Firebase Analytics Provider to enable dependency injection
protocol FirebaseAnalyticsProviderProtocol: AnalyticsProvider {
    /// Logs an event with the specified name and parameters
    func logEvent(_ name: String, parameters: [String: Any]?)

    /// Sets a user property to the given value
    func setUserProperty(_ value: String?, forName name: String)

    /// Sets the user ID for the current user
    func setUserID(_ userID: String?)

    /// Logs the start of a timed event
    func beginTimedEvent(_ name: String, parameters: [String: Any]?)

    /// Logs the end of a timed event
    func endTimedEvent(_ name: String, parameters: [String: Any]?)
}

/// A stub implementation of Firebase analytics for feature flag-based toggling
/// Now supports both singleton and dependency injection patterns
class FirebaseAnalyticsProvider: FirebaseAnalyticsProviderProtocol {
    /// Shared instance for singleton access
    static let shared = FirebaseAnalyticsProvider()

    /// Category for logging
    private let logCategory = "FirebaseAnalyticsProvider"

    /// Active timed events
    private var activeTimedEvents: Set<String> = []

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Optional dependencies (none required for this service)
    init(dependencies: [String: Any] = [:]) {
        Logger.info("Initialized Firebase Analytics Provider (DI-ready)", category: logCategory)
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    /// Logs an event with the specified name and parameters
    /// - Parameters:
    ///   - name: The name of the event to log
    ///   - parameters: Optional parameters to include with the event
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // In a real implementation, this would call Firebase Analytics SDK
        // FirebaseAnalytics.logEvent(name, parameters: parameters)
        Logger.info("Analytics event: \(name) \(parameters ?? [:])", category: logCategory)
    }

    /// Sets a user property to the given value
    /// - Parameters:
    ///   - value: The value to set the user property to
    ///   - name: The name of the user property to set
    func setUserProperty(_ value: String?, forName name: String) {
        // In a real implementation, this would call Firebase Analytics SDK
        // FirebaseAnalytics.setUserProperty(value, forName: name)
        Logger.info("Set user property: \(name) = \(value ?? "nil")", category: logCategory)
    }

    /// Sets the user ID for the current user
    /// - Parameter userID: The ID to set for the current user
    func setUserID(_ userID: String?) {
        // In a real implementation, this would call Firebase Analytics SDK
        // FirebaseAnalytics.setUserID(userID)
        Logger.info("Set user ID: \(userID ?? "nil")", category: logCategory)
    }

    /// Logs the start of a timed event
    /// - Parameters:
    ///   - name: The name of the timed event to start
    ///   - parameters: Optional parameters to include with the event
    func beginTimedEvent(_ name: String, parameters: [String: Any]? = nil) {
        // In a real implementation, this would call Firebase Analytics SDK
        // to start a timed event or track the start time
        activeTimedEvents.insert(name)
        Logger.info("Begin timed event: \(name) \(parameters ?? [:])", category: logCategory)
    }

    /// Logs the end of a timed event
    /// - Parameters:
    ///   - name: The name of the timed event to end
    ///   - parameters: Optional additional parameters to include with the event
    func endTimedEvent(_ name: String, parameters: [String: Any]? = nil) {
        // In a real implementation, this would call Firebase Analytics SDK
        // to end a timed event and calculate the duration
        if activeTimedEvents.contains(name) {
            activeTimedEvents.remove(name)
            Logger.info("End timed event: \(name) \(parameters ?? [:])", category: logCategory)
        } else {
            Logger.warning("Attempted to end timed event that wasn't started: \(name)", category: logCategory)
        }
    }

}

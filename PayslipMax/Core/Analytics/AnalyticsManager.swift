import Foundation

/// The central analytics manager that coordinates multiple analytics providers
class AnalyticsManager: AnalyticsProtocol, AnalyticsManagerProtocol {
    /// Shared instance for singleton access
    static let shared = AnalyticsManager(singleton: true)

    /// Category for logging
    private let logCategory = "AnalyticsManager"

    /// List of registered analytics providers
    private var providers: [AnalyticsProvider] = []

    /// Timer storage for timed events
    private var eventTimers: [String: Date] = [:]

    /// Flag indicating whether analytics is enabled
    /// Note: enhancedAnalytics flag is always enabled, hard-coded for simplicity
    private var isEnabled: Bool {
        return true  // Always enabled (was: FeatureFlagManager.shared.isEnabled(.enhancedAnalytics))
    }

    /// Public initializer for dependency injection
    init() {
        Logger.info("Initialized Analytics Manager", category: logCategory)
    }

    /// Private initializer for singleton pattern (deprecated - use public init for DI)
    private convenience init(singleton: Bool) {
        self.init()
    }

    /// Registers an analytics provider with the manager
    /// - Parameter provider: The provider to register
    func registerProvider(_ provider: AnalyticsProvider) {
        providers.append(provider)
        Logger.info("Registered analytics provider: \(type(of: provider))", category: logCategory)
    }

    /// Logs an event with the specified name and parameters
    /// - Parameters:
    ///   - name: The name of the event to log
    ///   - parameters: Optional parameters to include with the event
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        for provider in providers {
            provider.logEvent(name, parameters: parameters)
        }

        Logger.debug("Analytics event logged: \(name) \(parameters ?? [:])", category: logCategory)
    }

    /// Sets a user property to the given value
    /// - Parameters:
    ///   - value: The value to set the user property to
    ///   - name: The name of the user property to set
    func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled else { return }

        for provider in providers {
            provider.setUserProperty(value, forName: name)
        }

        Logger.debug("Analytics user property set: \(name) = \(value ?? "nil")", category: logCategory)
    }

    /// Sets the user ID for the current user
    /// - Parameter userID: The ID to set for the current user
    func setUserID(_ userID: String?) {
        guard isEnabled else { return }

        for provider in providers {
            provider.setUserID(userID)
        }

        Logger.debug("Analytics user ID set: \(userID ?? "nil")", category: logCategory)
    }

    /// Begins tracking a timed event
    /// - Parameters:
    ///   - name: The name of the event to track
    ///   - parameters: Optional parameters to include with the event
    func beginTimedEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        eventTimers[name] = Date()

        for provider in providers {
            provider.beginTimedEvent(name, parameters: parameters)
        }

        Logger.debug("Analytics timed event started: \(name)", category: logCategory)
    }

    /// Ends tracking a timed event and logs it
    /// - Parameters:
    ///   - name: The name of the event to end
    ///   - parameters: Optional additional parameters to include with the event
    func endTimedEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        var finalParameters = parameters ?? [:]

        if let startTime = eventTimers[name] {
            let elapsed = Date().timeIntervalSince(startTime)
            finalParameters["duration_ms"] = Int(elapsed * 1000)
            eventTimers.removeValue(forKey: name)
        }

        for provider in providers {
            provider.endTimedEvent(name, parameters: finalParameters)
        }

        Logger.debug("Analytics timed event ended: \(name), duration: \(finalParameters["duration_ms"] ?? "unknown")", category: logCategory)
    }

    /// Clears all registered providers
    /// Used primarily for testing
    func reset() {
        providers.removeAll()
        eventTimers.removeAll()
        Logger.info("Analytics Manager reset", category: logCategory)
    }
}

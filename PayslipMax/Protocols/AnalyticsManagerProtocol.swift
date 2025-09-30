import Foundation

/// Protocol for analytics management
protocol AnalyticsManagerProtocol {
    /// Registers an analytics provider
    /// - Parameter provider: The provider to register
    func registerProvider(_ provider: AnalyticsProvider)

    /// Logs an event with the specified name and parameters
    /// - Parameters:
    ///   - name: The name of the event to log
    ///   - parameters: Optional parameters to include with the event
    func logEvent(_ name: String, parameters: [String: Any]?)

    /// Sets a user property to the given value
    /// - Parameters:
    ///   - value: The value to set the user property to
    ///   - name: The name of the user property to set
    func setUserProperty(_ value: String?, forName name: String)

    /// Sets the user ID for the current user
    /// - Parameter userID: The ID to set for the current user
    func setUserID(_ userID: String?)

    /// Begins tracking a timed event
    /// - Parameters:
    ///   - name: The name of the event to track
    ///   - parameters: Optional parameters to include with the event
    func beginTimedEvent(_ name: String, parameters: [String: Any]?)

    /// Ends tracking a timed event and logs it
    /// - Parameters:
    ///   - name: The name of the event to end
    ///   - parameters: Optional additional parameters to include with the event
    func endTimedEvent(_ name: String, parameters: [String: Any]?)

    /// Clears all registered providers (used for testing)
    func reset()
}

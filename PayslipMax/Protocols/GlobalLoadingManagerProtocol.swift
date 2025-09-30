import Foundation

/// Protocol for global loading state management
@MainActor
protocol GlobalLoadingManagerProtocol: ObservableObject {
    /// Whether any loading operation is currently active
    var isLoading: Bool { get }

    /// Current loading message
    var loadingMessage: String { get }

    /// Whether a transition is in progress
    var isTransitioning: Bool { get }

    /// Starts a loading operation
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation
    ///   - message: Loading message to display
    func startLoading(operationId: String, message: String)

    /// Stops a loading operation
    /// - Parameter operationId: Unique identifier for the operation
    func stopLoading(operationId: String)

    /// Begins a tab transition
    /// - Parameter duration: Duration of the transition in seconds
    func beginTransition(duration: TimeInterval)

    /// Ends the current transition
    func endTransition()

    /// Checks if a specific operation is loading
    /// - Parameter operationId: Operation identifier to check
    /// - Returns: True if the operation is loading
    func isOperationLoading(_ operationId: String) -> Bool

    /// Stops all loading operations
    func stopAllLoading()
}

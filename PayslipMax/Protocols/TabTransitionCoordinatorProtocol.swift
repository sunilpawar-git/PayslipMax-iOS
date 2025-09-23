import Foundation

/// Protocol for coordinating tab transitions and managing tab state
@MainActor
protocol TabTransitionCoordinatorProtocol: ObservableObject {
    /// The currently selected tab index
    var selectedTab: Int { get set }

    /// Whether a tab transition is currently in progress
    var isTransitioning: Bool { get }

    /// The previous tab index
    var previousTab: Int { get }

    /// Transitions to a new tab with animation and state management
    /// - Parameters:
    ///   - newTab: The index of the tab to transition to
    ///   - animated: Whether to animate the transition
    func transitionToTab(_ newTab: Int, animated: Bool)

    /// Forces a transition to a tab without animation
    /// - Parameter tabIndex: The index of the tab to switch to
    func forceTransitionToTab(_ tabIndex: Int)

    /// Cancels any ongoing transition
    func cancelTransition()

    /// Checks if a tab transition is allowed
    /// - Parameter tabIndex: The index of the tab to check
    /// - Returns: True if transition is allowed
    func canTransitionToTab(_ tabIndex: Int) -> Bool

    /// Gets the tab name for a given index
    /// - Parameter index: The tab index
    /// - Returns: The tab name
    func tabName(for index: Int) -> String
}

import SwiftUI
import Combine

/// Coordinates tab transitions and manages state during tab changes
@MainActor
final class TabTransitionCoordinator: TabTransitionCoordinatorProtocol {

    // MARK: - Singleton Instance
    static let shared = TabTransitionCoordinator(singleton: true)

    // MARK: - Published Properties

    /// The currently selected tab index
    @Published var selectedTab: Int = 0

    /// Whether a tab transition is currently in progress
    @Published private(set) var isTransitioning = false

    /// The previous tab index (useful for transition logic)
    @Published private(set) var previousTab: Int = 0

    // MARK: - Dependencies

    /// Tab configuration service
    private let tabConfiguration: TabConfiguration

    /// Tab transition handler service
    private var transitionHandler: TabTransitionHandlerProtocol?

    /// Router integration service
    private lazy var routerIntegration: TabRouterIntegration = {
        TabRouterIntegration(coordinator: self)
    }()

    // MARK: - Initialization Dependencies (for DI)
    private let injectedTabConfiguration: TabConfiguration?
    private let injectedTransitionHandler: TabTransitionHandlerProtocol?

    // MARK: - Private Properties

    /// Timer for transition duration management
    private var transitionTimer: Timer?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Public initializer for dependency injection
    init(tabConfiguration: TabConfiguration? = nil, transitionHandler: TabTransitionHandlerProtocol? = nil) {
        self.injectedTabConfiguration = tabConfiguration
        self.injectedTransitionHandler = transitionHandler
        self.tabConfiguration = tabConfiguration ?? TabConfiguration()
        self.transitionHandler = transitionHandler ?? TabTransitionHandler()
        setupTabSelectionMonitoring()
    }

    /// Private initializer for singleton pattern (deprecated - use public init for DI)
    private convenience init(singleton: Bool) {
        self.init()
    }

    // MARK: - Public Methods

    /// Switches to a specific tab with proper coordination
    /// - Parameters:
    ///   - tabIndex: The index of the tab to switch to
    ///   - animated: Whether to animate the transition
    ///   - completion: Optional completion handler
    func switchToTab(
        _ tabIndex: Int,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard tabIndex != selectedTab else {
            completion?()
            return
        }

        guard tabConfiguration.isValidTabIndex(tabIndex) else {
            print("⚠️ TabTransitionCoordinator: Invalid tab index \(tabIndex)")
            return
        }

        beginTransition(from: selectedTab, to: tabIndex, animated: animated, completion: completion)
    }

    /// Gets the transition configuration for a specific tab pair
    /// - Parameters:
    ///   - fromTab: Source tab index
    ///   - toTab: Destination tab index
    /// - Returns: Transition configuration
    func getTransitionConfig(from fromTab: Int, to toTab: Int) -> TransitionConfiguration {
        return tabConfiguration.getTransitionConfig(from: fromTab, to: toTab)
    }

    /// Checks if transitioning to a tab should trigger data refresh
    /// - Parameter tabIndex: The tab index to check
    /// - Returns: True if refresh should be triggered
    func shouldRefreshOnTransition(to tabIndex: Int) -> Bool {
        return tabConfiguration.shouldRefreshOnTransition(to: tabIndex)
    }

    // MARK: - Private Methods

    /// Sets up monitoring of tab selection changes
    private func setupTabSelectionMonitoring() {
        $selectedTab
            .removeDuplicates()
            .sink { [weak self] newTab in
                self?.handleTabChange(to: newTab)
            }
            .store(in: &cancellables)
    }

    /// Handles tab change logic
    /// - Parameter newTab: The new tab index
    private func handleTabChange(to newTab: Int) {
        guard newTab != previousTab else { return }

        let oldTab = previousTab
        previousTab = newTab

        print("🏷️ TabTransitionCoordinator: Tab changed from \(oldTab) to \(newTab)")

        // Handle specific tab transition logic
        Task { @MainActor in
            await transitionHandler?.handleSpecificTabTransition(from: oldTab, to: newTab)
        }
    }

    /// Begins a transition between tabs
    /// - Parameters:
    ///   - fromTab: Source tab index
    ///   - toTab: Destination tab index
    ///   - animated: Whether to animate
    ///   - completion: Optional completion handler
    private func beginTransition(
        from fromTab: Int,
        to toTab: Int,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        // Don't start a new transition if one is already in progress
        guard !isTransitioning else {
            completion?()
            return
        }

        print("🔄 TabTransitionCoordinator: Beginning transition from tab \(fromTab) to \(toTab)")

        isTransitioning = true

        // Get transition configuration
        let config = getTransitionConfig(from: fromTab, to: toTab)

        // Handle transition-specific logic
        Task { @MainActor in
            await transitionHandler?.handleSpecificTabTransition(from: fromTab, to: toTab)
        }

        // Set the new tab
        selectedTab = toTab

        // Handle post-transition logic
        let transitionDuration = animated ? config.duration : 0.0
        transitionTimer?.invalidate()
        transitionTimer = Timer.scheduledTimer(withTimeInterval: transitionDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endTransition(config: config, completion: completion)
            }
        }
    }

    /// Ends the current transition
    /// - Parameters:
    ///   - config: The transition configuration
    ///   - completion: Optional completion handler
    private func endTransition(config: TransitionConfiguration, completion: (() -> Void)?) {
        print("✅ TabTransitionCoordinator: Transition completed")

        isTransitioning = false
        transitionTimer?.invalidate()
        transitionTimer = nil

        // Transition completed successfully

        // Execute post-transition actions
        if config.refreshDataOnCompletion {
            Task { @MainActor in
                await transitionHandler?.handleDataRefresh(
                    for: selectedTab,
                    isTransitioning: isTransitioning,
                    shouldRefresh: { [weak self] tabIndex in
                        self?.shouldRefreshOnTransition(to: tabIndex) ?? false
                    }
                )
            }
        }

        completion?()
    }

    // MARK: - Protocol Implementation

    /// Transitions to a new tab with animation and state management
    /// - Parameters:
    ///   - newTab: The index of the tab to transition to
    ///   - animated: Whether to animate the transition
    func transitionToTab(_ newTab: Int, animated: Bool = true) {
        switchToTab(newTab, animated: animated, completion: nil)
    }

    /// Forces a transition to a tab without animation
    /// - Parameter tabIndex: The index of the tab to switch to
    func forceTransitionToTab(_ tabIndex: Int) {
        switchToTab(tabIndex, animated: false, completion: nil)
    }

    /// Cancels any ongoing transition
    func cancelTransition() {
        if isTransitioning {
            // Create a default config for cancellation
            let defaultConfig = tabConfiguration.getTransitionConfig(from: selectedTab, to: selectedTab)
            endTransition(config: defaultConfig, completion: nil)
        }
    }

    /// Checks if a tab transition is allowed
    /// - Parameter tabIndex: The index of the tab to check
    /// - Returns: True if transition is allowed
    func canTransitionToTab(_ tabIndex: Int) -> Bool {
        return tabConfiguration.isValidTabIndex(tabIndex)
    }

    /// Gets the tab name for a given index
    /// - Parameter index: The tab index
    /// - Returns: The tab name
    func tabName(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Payslips"
        case 2: return "Insights"
        case 3: return "Settings"
        default: return "Tab \(index)"
        }
    }

}


// MARK: - Integration with Existing Code

extension TabTransitionCoordinator {
    /// Convenience method for integration with existing NavRouter
    func integrateWithRouter(_ router: NavRouter) {
        routerIntegration.integrateWithRouter(router)
    }
}

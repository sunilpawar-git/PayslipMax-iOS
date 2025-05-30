import SwiftUI
import Combine

/// Coordinates tab transitions and manages state during tab changes
@MainActor
final class TabTransitionCoordinator: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = TabTransitionCoordinator()
    
    // MARK: - Published Properties
    
    /// The currently selected tab index
    @Published var selectedTab: Int = 0
    
    /// Whether a tab transition is currently in progress
    @Published private(set) var isTransitioning = false
    
    /// The previous tab index (useful for transition logic)
    @Published private(set) var previousTab: Int = 0
    
    // MARK: - Private Properties
    
    /// Global loading manager reference
    private let loadingManager = GlobalLoadingManager.shared
    
    /// Global overlay system reference
    private let overlaySystem = GlobalOverlaySystem.shared
    
    /// Timer for transition duration management
    private var transitionTimer: Timer?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Tab configuration
    private let tabConfiguration: TabConfiguration
    
    // MARK: - Initialization
    
    private init() {
        self.tabConfiguration = TabConfiguration()
        setupTabSelectionMonitoring()
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
        handleSpecificTabTransition(from: oldTab, to: newTab)
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
        
        // Notify global loading manager about transition
        loadingManager.beginTransition(duration: animated ? 0.35 : 0.0)
        
        // Get transition configuration
        let config = getTransitionConfig(from: fromTab, to: toTab)
        
        // Dismiss overlays if needed
        if config.dismissOverlaysOnTransition {
            overlaySystem.dismissAllDismissibleOverlays()
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
        
        // Notify global loading manager that transition ended
        loadingManager.endTransition()
        
        // Execute post-transition actions
        if config.refreshDataOnCompletion {
            handleDataRefresh(for: selectedTab)
        }
        
        completion?()
    }
    
    /// Handles specific tab transition logic
    /// - Parameters:
    ///   - fromTab: Source tab index
    ///   - toTab: Destination tab index
    private func handleSpecificTabTransition(from fromTab: Int, to toTab: Int) {
        // Handle transition from Home to Payslips (the main problematic transition)
        if fromTab == 0 && toTab == 1 {
            handleHomeToPayslipsTransition()
        }
        
        // Handle transition from Payslips to Home
        if fromTab == 1 && toTab == 0 {
            handlePayslipsToHomeTransition()
        }
        
        // Handle other specific transitions as needed
    }
    
    /// Handles the Home to Payslips transition specifically
    private func handleHomeToPayslipsTransition() {
        print("🏠➡️📄 TabTransitionCoordinator: Home to Payslips transition")
        
        // Stop any Home-related loading operations
        loadingManager.stopLoading(operationId: "home_recent_payslips")
        loadingManager.stopLoading(operationId: "home_data_load")
        
        // Prepare for Payslips data load (but don't trigger notification cascade)
        // The PayslipsView will handle its own data loading in onAppear
    }
    
    /// Handles the Payslips to Home transition specifically
    private func handlePayslipsToHomeTransition() {
        print("📄➡️🏠 TabTransitionCoordinator: Payslips to Home transition")
        
        // Stop any Payslips-related loading operations
        loadingManager.stopLoading(operationId: "payslips_load")
        loadingManager.stopLoading(operationId: "payslips_refresh")
    }
    
    /// Handles data refresh for a specific tab
    /// - Parameter tabIndex: The tab index to refresh
    private func handleDataRefresh(for tabIndex: Int) {
        // Only refresh if configured to do so and not during transitions
        guard !isTransitioning && shouldRefreshOnTransition(to: tabIndex) else { return }
        
        switch tabIndex {
        case 1: // Payslips tab
            // Post a delayed notification to avoid conflicts with onAppear
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                PayslipEvents.notifyRefreshRequired()
            }
        default:
            break
        }
    }
}

// MARK: - Supporting Types

/// Configuration for tab behavior and transitions
private struct TabConfiguration {
    private let tabCount = 4 // Home, Payslips, Insights, Settings
    
    /// Checks if a tab index is valid
    /// - Parameter index: The tab index to validate
    /// - Returns: True if valid
    func isValidTabIndex(_ index: Int) -> Bool {
        return index >= 0 && index < tabCount
    }
    
    /// Gets transition configuration for a tab pair
    /// - Parameters:
    ///   - fromTab: Source tab
    ///   - toTab: Destination tab
    /// - Returns: Transition configuration
    func getTransitionConfig(from fromTab: Int, to toTab: Int) -> TransitionConfiguration {
        // Special handling for problematic transitions
        if (fromTab == 0 && toTab == 1) || (fromTab == 1 && toTab == 0) {
            return TransitionConfiguration(
                duration: 0.35,
                dismissOverlaysOnTransition: true,
                refreshDataOnCompletion: false // Let views handle their own refresh
            )
        }
        
        // Default configuration
        return TransitionConfiguration(
            duration: 0.25,
            dismissOverlaysOnTransition: false,
            refreshDataOnCompletion: false
        )
    }
    
    /// Determines if a tab should refresh data on transition
    /// - Parameter tabIndex: The tab index
    /// - Returns: True if refresh should happen
    func shouldRefreshOnTransition(to tabIndex: Int) -> Bool {
        switch tabIndex {
        case 1: // Payslips tab - let it handle its own refresh
            return false
        default:
            return false
        }
    }
}

/// Configuration for a specific transition
struct TransitionConfiguration {
    let duration: TimeInterval
    let dismissOverlaysOnTransition: Bool
    let refreshDataOnCompletion: Bool
}

// MARK: - Integration with Existing Code

extension TabTransitionCoordinator {
    /// Convenience method for integration with existing NavRouter
    func integrateWithRouter(_ router: NavRouter) {
        // Sync router's selectedTab with coordinator
        router.$selectedTab
            .removeDuplicates()
            .sink { [weak self] newTab in
                if self?.selectedTab != newTab {
                    self?.selectedTab = newTab
                }
            }
            .store(in: &cancellables)
        
        // Sync coordinator's selectedTab with router
        $selectedTab
            .removeDuplicates()
            .sink { newTab in
                if router.selectedTab != newTab {
                    router.selectedTab = newTab
                }
            }
            .store(in: &cancellables)
    }
} 
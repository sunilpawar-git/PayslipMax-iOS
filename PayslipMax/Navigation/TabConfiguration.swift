import Foundation

/// Configuration for tab behavior and transitions
struct TabConfiguration {
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

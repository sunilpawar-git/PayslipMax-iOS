import Foundation

/// Service responsible for handling specific tab transition logic
protocol TabTransitionHandlerProtocol {
    func handleSpecificTabTransition(from fromTab: Int, to toTab: Int)
    func handleDataRefresh(for tabIndex: Int, isTransitioning: Bool, shouldRefresh: (Int) -> Bool) async
}

/// Service responsible for handling specific tab transition logic
@MainActor
class TabTransitionHandler: TabTransitionHandlerProtocol {

    // MARK: - Dependencies

    private let loadingManager: GlobalLoadingManager
    private let overlaySystem: GlobalOverlaySystem

    init(
        loadingManager: GlobalLoadingManager = .shared,
        overlaySystem: GlobalOverlaySystem = .shared
    ) {
        self.loadingManager = loadingManager
        self.overlaySystem = overlaySystem
    }

    /// Handles specific tab transition logic
    /// - Parameters:
    ///   - fromTab: Source tab index
    ///   - toTab: Destination tab index
    func handleSpecificTabTransition(from fromTab: Int, to toTab: Int) {
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

    /// Handles data refresh for a specific tab
    /// - Parameters:
    ///   - tabIndex: The tab index to refresh
    ///   - isTransitioning: Whether a transition is currently in progress
    ///   - shouldRefresh: Closure to determine if refresh should happen
    func handleDataRefresh(for tabIndex: Int, isTransitioning: Bool, shouldRefresh: (Int) -> Bool) async {
        // Only refresh if configured to do so and not during transitions
        guard !isTransitioning && shouldRefresh(tabIndex) else { return }

        switch tabIndex {
        case 1: // Payslips tab
            // Post a delayed notification to avoid conflicts with onAppear
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await PayslipEvents.notifyRefreshRequired()
        default:
            break
        }
    }

    // MARK: - Private Transition Methods

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
}

import SwiftUI
import Combine

/// Service responsible for integrating TabTransitionCoordinator with NavRouter
@MainActor
class TabRouterIntegration {

    // MARK: - Dependencies

    private let coordinator: TabTransitionCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: TabTransitionCoordinator) {
        self.coordinator = coordinator
    }

    /// Integrates the coordinator with a NavRouter
    /// - Parameter router: The NavRouter to integrate with
    func integrateWithRouter(_ router: NavRouter) {
        // Sync router's selectedTab with coordinator
        router.$selectedTab
            .removeDuplicates()
            .sink { [weak self] newTab in
                if self?.coordinator.selectedTab != newTab {
                    self?.coordinator.selectedTab = newTab
                }
            }
            .store(in: &cancellables)

        // Sync coordinator's selectedTab with router
        coordinator.$selectedTab
            .removeDuplicates()
            .sink { newTab in
                if router.selectedTab != newTab {
                    router.selectedTab = newTab
                }
            }
            .store(in: &cancellables)
    }

    /// Cleans up all subscriptions
    func cleanup() {
        cancellables.removeAll()
    }
}

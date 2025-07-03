
import Foundation

@MainActor
class HomeViewNavigation {
    private let navigationCoordinator: HomeNavigationCoordinator

    init(navigationCoordinator: HomeNavigationCoordinator) {
        self.navigationCoordinator = navigationCoordinator
    }

    func navigateToPayslipDetail(for payslipItem: PayslipItem) {
        navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
    }

    func showManualEntry() {
        navigationCoordinator.showManualEntry()
    }
}

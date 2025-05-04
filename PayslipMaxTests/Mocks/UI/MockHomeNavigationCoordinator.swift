import Foundation
@testable import PayslipMax

class MockHomeNavigationCoordinator: HomeNavigationCoordinatorProtocol {
    var navigateToAddPayslipCallCount = 0
    var navigateToInsightsCallCount = 0
    var navigateToSettingsCallCount = 0
    
    func navigateToAddPayslip() {
        navigateToAddPayslipCallCount += 1
    }
    
    func navigateToInsights() {
        navigateToInsightsCallCount += 1
    }
    
    func navigateToSettings() {
        navigateToSettingsCallCount += 1
    }
    
    func reset() {
        navigateToAddPayslipCallCount = 0
        navigateToInsightsCallCount = 0
        navigateToSettingsCallCount = 0
    }
} 
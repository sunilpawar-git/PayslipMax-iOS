import Foundation
import SwiftUI
@testable import Payslip_Max

class MockHomeNavigationCoordinator: HomeNavigationCoordinator {
    var navigateToPayslipDetailCallCount = 0
    var navigateToAllPayslipsCallCount = 0
    var navigateToPayslipUploadCallCount = 0
    var navigateToSettingsCallCount = 0
    var lastPayslipNavigatedTo: PayslipItem?
    
    override func navigateToPayslipDetail(payslip: PayslipItem) {
        navigateToPayslipDetailCallCount += 1
        lastPayslipNavigatedTo = payslip
    }
    
    override func navigateToAllPayslips() {
        navigateToAllPayslipsCallCount += 1
    }
    
    override func navigateToPayslipUpload() {
        navigateToPayslipUploadCallCount += 1
    }
    
    override func navigateToSettings() {
        navigateToSettingsCallCount += 1
    }
    
    func reset() {
        navigateToPayslipDetailCallCount = 0
        navigateToAllPayslipsCallCount = 0
        navigateToPayslipUploadCallCount = 0
        navigateToSettingsCallCount = 0
        lastPayslipNavigatedTo = nil
    }
} 
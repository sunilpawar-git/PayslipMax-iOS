import SwiftUI

/// Helper for navigation to payslip-related screens
struct PayslipNavigation {
    /// Returns a PayslipDetailView for a given payslip with standard view model
    @MainActor
    static func detailView(for payslip: any PayslipItemProtocol) -> some View {
        let viewModel = PayslipDetailViewModel(
            payslip: payslip,
            securityService: DIContainer.shared.securityService,
            dataService: DIContainer.shared.dataService
        )
        return PayslipDetailView(viewModel: viewModel)
    }
    
    /// Returns a PayslipDetailView for a given payslip with simplified view model
    @MainActor
    static func simplifiedDetailView(for payslip: any PayslipItemProtocol) -> some View {
        let viewModel = SimplifiedPayslipDetailViewModel(
            payslip: payslip,
            securityService: DIContainer.shared.securityService,
            dataService: DIContainer.shared.dataService
        )
        return PayslipDetailView(viewModel: viewModel)
    }
} 
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
        let viewModel = PayslipDetailViewModel(
            payslip: payslip,
            securityService: DIContainer.shared.securityService,
            dataService: DIContainer.shared.dataService
        )
        return PayslipDetailView(viewModel: viewModel)
    }
    
    /// Creates a navigation container that navigates to a payslip detail view when isActive becomes true
    @MainActor
    static func createPayslipNavigationContainer(
        isActive: Binding<Bool>,
        payslip: PayslipItem?
    ) -> some View {
        Group {
            if let payslip = payslip {
                // Use the modern NavigationLink API
                NavigationLink(
                    value: payslip,
                    label: { EmptyView() }
                )
                .opacity(0)
                .navigationDestination(for: PayslipItem.self) { item in
                    detailView(for: item)
                }
                .onChange(of: isActive.wrappedValue) { oldValue, newValue in
                    // This simulates the isActive binding of the old API
                    if !newValue && isActive.wrappedValue {
                        isActive.wrappedValue = false
                    }
                }
            } else {
                // Empty placeholder when no payslip is available
                EmptyView()
                    .onChange(of: isActive.wrappedValue) { oldValue, newValue in
                        if newValue {
                            // If somehow isActive becomes true when no payslip exists,
                            // reset it to false
                            isActive.wrappedValue = false
                        }
                    }
            }
        }
    }
} 
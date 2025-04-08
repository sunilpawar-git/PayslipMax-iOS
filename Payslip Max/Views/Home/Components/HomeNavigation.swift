import SwiftUI

/// Extracts navigation-related modifiers from HomeView to improve code organization
struct HomeNavigation: ViewModifier {
    @ObservedObject var viewModel: HomeViewModel
    
    func body(content: Content) -> some View {
        content
            .background(
                PayslipNavigation.createPayslipNavigationContainer(
                    isActive: Binding(
                        get: { viewModel.navigationCoordinator.navigateToNewPayslip },
                        set: { newValue in 
                            if !newValue {
                                viewModel.navigationCoordinator.navigateToNewPayslip = false
                            }
                        }
                    ),
                    payslip: viewModel.navigationCoordinator.newlyAddedPayslip
                )
            )
    }
}

extension View {
    func homeNavigation(viewModel: HomeViewModel) -> some View {
        self.modifier(HomeNavigation(viewModel: viewModel))
    }
} 
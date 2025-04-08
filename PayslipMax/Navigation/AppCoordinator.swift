import SwiftUI
import PDFKit

/// Coordinator that manages all navigation in the app
@MainActor
class AppCoordinator: ObservableObject {
    // Navigation state
    @Published var path = NavigationPath()
    @Published var sheet: AppDestination?
    @Published var fullScreenCover: AppDestination?
    @Published var selectedTab: Int = 0
    
    // Tab destinations for easy reference
    let tabDestinations: [AppDestination] = [.home, .payslips, .insights, .settings]
    
    // MARK: - Navigation methods
    
    /// Navigate to a destination by pushing it onto the navigation stack
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }
    
    /// Navigate back one level
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// Navigate back to the root of the current stack
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    /// Present a destination as a sheet
    func presentSheet(_ destination: AppDestination?) {
        self.sheet = destination
    }
    
    /// Dismiss the currently presented sheet
    func dismissSheet() {
        self.sheet = nil
    }
    
    /// Present a destination as a full-screen cover
    func presentFullScreen(_ destination: AppDestination?) {
        self.fullScreenCover = destination
    }
    
    /// Dismiss the currently presented full-screen cover
    func dismissFullScreen() {
        self.fullScreenCover = nil
    }
    
    /// Switch to a specific tab
    func switchTab(to index: Int) {
        guard index >= 0 && index < tabDestinations.count else { return }
        selectedTab = index
        // Reset navigation stack when switching tabs
        navigateToRoot()
    }
    
    // MARK: - Convenience methods
    
    /// Show payslip details
    func showPayslipDetail(payslip: PayslipItem) {
        navigate(to: .payslipDetail(payslip: payslip))
    }
    
    /// Show add payslip sheet
    func showAddPayslip() {
        presentSheet(.addPayslip)
    }
    
    /// Show PDF preview
    func showPDFPreview(document: PDFDocument) {
        presentSheet(.pdfPreview(document: document))
    }
    
    /// Show PIN setup
    func showPINSetup() {
        presentSheet(.pinSetup)
    }
    
    /// Show scanner
    func showScanner() {
        presentFullScreen(.scanner)
    }
} 
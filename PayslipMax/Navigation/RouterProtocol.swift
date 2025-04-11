import SwiftUI
import PDFKit

/// Defines the navigation capabilities required by the app
@MainActor
protocol RouterProtocol: ObservableObject {
    // MARK: - State Properties (for SwiftUI bindings)
    
    /// Navigation path for the Home tab
    var homeStack: NavigationPath { get set }
    /// Navigation path for the Payslips tab
    var payslipsStack: NavigationPath { get set }
    /// Navigation path for the Insights tab
    var insightsStack: NavigationPath { get set }
    /// Navigation path for the Settings tab
    var settingsStack: NavigationPath { get set }
    
    /// Currently presented sheet destination
    var sheetDestination: AppNavigationDestination? { get set } // Use new enum
    /// Currently presented full screen cover destination
    var fullScreenDestination: AppNavigationDestination? { get set } // Use new enum
    
    /// Index of the currently selected tab
    var selectedTab: Int { get set }
    
    // MARK: - Navigation Methods
    
    /// Navigates to a destination within the currently active tab stack.
    /// - Parameter destination: The destination to navigate to.
    func navigate(to destination: AppNavigationDestination) // Use new enum
    
    /// Switches to the specified tab and optionally navigates to a destination within that tab's stack.
    /// - Parameters:
    ///   - tab: The index of the tab to switch to.
    ///   - destination: An optional destination to navigate to after switching tabs.
    func switchTab(to tab: Int, destination: AppNavigationDestination?) // Use new enum
    
    /// Pops the top view from the currently active navigation stack.
    func navigateBack()
    
    /// Pops all views from the currently active navigation stack, returning to the root view of the tab.
    func navigateToRoot()
    
    /// Presents a sheet modally.
    /// - Parameter destination: The destination to present in the sheet.
    func presentSheet(_ destination: AppNavigationDestination) // Use new enum
    
    /// Dismisses the currently presented sheet.
    func dismissSheet()
    
    /// Presents a full-screen cover.
    /// - Parameter destination: The destination to present in the full-screen cover.
    func presentFullScreen(_ destination: AppNavigationDestination) // Use new enum
    
    /// Dismisses the currently presented full-screen cover.
    func dismissFullScreen()
    
    // MARK: - Convenience Methods (Optional but Recommended)
    
    /// Convenience method to navigate to a specific payslip detail view.
    /// - Parameter id: The UUID of the payslip item.
    func showPayslipDetail(id: UUID)
    
    /// Convenience method to present a PDF document preview.
    /// - Parameter document: The PDF document to preview.
    func showPDFPreview(document: PDFDocument)
    
    /// Convenience method to present the Add Payslip flow.
    func showAddPayslip()
    
    // Add other convenience methods as needed (e.g., showPinSetup, showScanner)
} 
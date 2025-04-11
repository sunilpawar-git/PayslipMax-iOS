import SwiftUI
import PDFKit

/// Protocol defining the capabilities required for navigation routing.
/// This protocol is primarily used for:
/// - Documenting the navigation capabilities
/// - Creating mock implementations for testing
/// - Providing a common interface for components that need routing capabilities
///
/// Note: Due to SwiftUI limitations with protocol types, use concrete NavRouter
/// directly in SwiftUI views with @StateObject or @EnvironmentObject.
@MainActor
protocol RouterProtocol: ObservableObject {
    // Navigation path stacks for each tab
    var homeStack: NavigationPath { get set }
    var payslipsStack: NavigationPath { get set }
    var insightsStack: NavigationPath { get set }
    var settingsStack: NavigationPath { get set }
    
    // Modal presentations
    var sheetDestination: NavDestination? { get set }
    var fullScreenDestination: NavDestination? { get set }
    
    // Current tab selection
    var selectedTab: Int { get set }
    
    // Core navigation methods
    func navigate(to destination: NavDestination)
    func switchTab(to tab: Int, destination: NavDestination?)
    func navigateBack()
    func navigateToRoot()
    
    // Modal presentation methods
    func presentSheet(_ destination: NavDestination)
    func dismissSheet()
    func presentFullScreen(_ destination: NavDestination)
    func dismissFullScreen()
    
    // Convenience methods for common navigation patterns
    func showPayslipDetail(id: UUID)
    func showPDFPreview(document: PDFDocument)
    func showAddPayslip()
    
    // Deep linking
    func handleDeepLink(_ url: URL)
} 
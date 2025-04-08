import SwiftUI
import PDFKit

/// Navigation destination enum with associated values
enum NavDestination: Identifiable, Hashable {
    // Tab destinations
    case home
    case payslips
    case insights 
    case settings
    
    // Detail destinations
    case payslipDetail(id: UUID)
    case pdfPreview(document: PDFDocument)
    case privacyPolicy
    case termsOfService
    case changePin
    case addPayslip
    case scanner
    
    // Identifiable conformance
    var id: String {
        switch self {
        case .home: return "home"
        case .payslips: return "payslips"
        case .insights: return "insights"
        case .settings: return "settings"
        case .payslipDetail(let id): return "payslip-\(id.uuidString)"
        case .pdfPreview: return "pdf-preview"
        case .privacyPolicy: return "privacy-policy"
        case .termsOfService: return "terms-of-service"
        case .changePin: return "change-pin"
        case .addPayslip: return "add-payslip"
        case .scanner: return "scanner"
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NavDestination, rhs: NavDestination) -> Bool {
        lhs.id == rhs.id
    }
}

/// Router class for managing navigation
@MainActor
class NavRouter: ObservableObject {
    // Navigation stacks for each tab
    @Published var homeStack = NavigationPath()
    @Published var payslipsStack = NavigationPath()
    @Published var insightsStack = NavigationPath()
    @Published var settingsStack = NavigationPath()
    
    // Modal presentations
    @Published var sheetDestination: NavDestination?
    @Published var fullScreenDestination: NavDestination?
    
    // Current tab selection
    @Published var selectedTab = 0
    
    // MARK: - Navigation Methods
    
    /// Navigate to destination in the current tab
    func navigate(to destination: NavDestination) {
        switch selectedTab {
        case 0: homeStack.append(destination)
        case 1: payslipsStack.append(destination)
        case 2: insightsStack.append(destination)
        case 3: settingsStack.append(destination)
        default: break
        }
    }
    
    /// Switch tab and optionally navigate
    func switchTab(to tab: Int, destination: NavDestination? = nil) {
        selectedTab = tab
        
        if let destination = destination {
            navigate(to: destination)
        }
    }
    
    /// Pop the active stack
    func navigateBack() {
        switch selectedTab {
        case 0: if !homeStack.isEmpty { homeStack.removeLast() }
        case 1: if !payslipsStack.isEmpty { payslipsStack.removeLast() }
        case 2: if !insightsStack.isEmpty { insightsStack.removeLast() }
        case 3: if !settingsStack.isEmpty { settingsStack.removeLast() }
        default: break
        }
    }
    
    /// Reset the active stack
    func navigateToRoot() {
        switch selectedTab {
        case 0: homeStack = NavigationPath()
        case 1: payslipsStack = NavigationPath()
        case 2: insightsStack = NavigationPath()
        case 3: settingsStack = NavigationPath()
        default: break
        }
    }
    
    /// Present a sheet
    func presentSheet(_ destination: NavDestination) {
        sheetDestination = destination
    }
    
    /// Dismiss the sheet
    func dismissSheet() {
        sheetDestination = nil
    }
    
    /// Present fullscreen cover
    func presentFullScreen(_ destination: NavDestination) {
        fullScreenDestination = destination
    }
    
    /// Dismiss fullscreen cover
    func dismissFullScreen() {
        fullScreenDestination = nil
    }
    
    // MARK: - Convenience Methods
    
    /// Show a payslip detail
    func showPayslipDetail(id: UUID) {
        navigate(to: .payslipDetail(id: id))
    }
    
    /// Show PDF preview
    func showPDFPreview(document: PDFDocument) {
        presentSheet(.pdfPreview(document: document))
    }
    
    /// Show add payslip
    func showAddPayslip() {
        presentSheet(.addPayslip)
    }
} 
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
class NavRouter: RouterProtocol {
    // Navigation state
    private let state: NavigationState
    
    // Published properties required by RouterProtocol
    @Published var homeStack: NavigationPath {
        didSet { state.homeStack = homeStack }
    }
    
    @Published var payslipsStack: NavigationPath {
        didSet { state.payslipsStack = payslipsStack }
    }
    
    @Published var insightsStack: NavigationPath {
        didSet { state.insightsStack = insightsStack }
    }
    
    @Published var settingsStack: NavigationPath {
        didSet { state.settingsStack = settingsStack }
    }
    
    @Published var sheetDestination: NavDestination? {
        didSet { state.sheetDestination = sheetDestination }
    }
    
    @Published var fullScreenDestination: NavDestination? {
        didSet { state.fullScreenDestination = fullScreenDestination }
    }
    
    @Published var selectedTab: Int {
        didSet { state.selectedTab = selectedTab }
    }
    
    // MARK: - Initialization
    
    init(state: NavigationState? = nil) {
        // Use provided state or create a new one
        self.state = state ?? NavigationState()
        
        // Initialize published properties from state
        self.homeStack = self.state.homeStack
        self.payslipsStack = self.state.payslipsStack
        self.insightsStack = self.state.insightsStack
        self.settingsStack = self.state.settingsStack
        self.sheetDestination = self.state.sheetDestination
        self.fullScreenDestination = self.state.fullScreenDestination
        self.selectedTab = self.state.selectedTab
        
        // Setup state observation
        setupStateObservation()
    }
    
    private func setupStateObservation() {
        // Observe state changes and update router's published properties
        // This would typically use Combine, but for simplicity we'll just
        // synchronize in each navigation method
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to destination in the current tab
    func navigate(to destination: NavDestination) {
        state.appendToActiveStack(destination)
        
        // Update the published property for SwiftUI
        switch selectedTab {
        case 0: homeStack = state.homeStack
        case 1: payslipsStack = state.payslipsStack
        case 2: insightsStack = state.insightsStack
        case 3: settingsStack = state.settingsStack
        default: break
        }
    }
    
    /// Switch tab and optionally navigate
    func switchTab(to tab: Int, destination: NavDestination? = nil) {
        selectedTab = tab
        state.selectedTab = tab
        
        if let destination = destination {
            navigate(to: destination)
        }
    }
    
    /// Pop the active stack
    func navigateBack() {
        state.removeLastFromActiveStack()
        
        // Update the published property for SwiftUI
        switch selectedTab {
        case 0: homeStack = state.homeStack
        case 1: payslipsStack = state.payslipsStack
        case 2: insightsStack = state.insightsStack
        case 3: settingsStack = state.settingsStack
        default: break
        }
    }
    
    /// Reset the active stack
    func navigateToRoot() {
        state.clearActiveStack()
        
        // Update the published property for SwiftUI
        switch selectedTab {
        case 0: homeStack = state.homeStack
        case 1: payslipsStack = state.payslipsStack
        case 2: insightsStack = state.insightsStack
        case 3: settingsStack = state.settingsStack
        default: break
        }
    }
    
    /// Present a sheet
    func presentSheet(_ destination: NavDestination) {
        sheetDestination = destination
        state.sheetDestination = destination
    }
    
    /// Dismiss the sheet
    func dismissSheet() {
        sheetDestination = nil
        state.sheetDestination = nil
    }
    
    /// Present fullscreen cover
    func presentFullScreen(_ destination: NavDestination) {
        fullScreenDestination = destination
        state.fullScreenDestination = destination
    }
    
    /// Dismiss fullscreen cover
    func dismissFullScreen() {
        fullScreenDestination = nil
        state.fullScreenDestination = nil
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
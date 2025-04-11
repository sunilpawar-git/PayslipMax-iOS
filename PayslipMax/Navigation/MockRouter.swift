import SwiftUI
import PDFKit

/// Mock router implementation for testing purposes
@MainActor
class MockRouter: ObservableObject, RouterProtocol {
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
    
    // Tracking for testing
    var navigateToDestinationCalled = false
    var lastDestination: NavDestination?
    var switchTabCalled = false
    var lastTabIndex: Int = -1
    var navigateBackCalled = false
    var navigateToRootCalled = false
    var presentSheetCalled = false
    var dismissSheetCalled = false
    var presentFullScreenCalled = false
    var dismissFullScreenCalled = false
    var showPayslipDetailCalled = false
    var lastPayslipId: UUID?
    var showPDFPreviewCalled = false
    var showAddPayslipCalled = false
    var handleDeepLinkCalled = false
    var lastDeepLinkURL: URL?
    
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
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: NavDestination) {
        navigateToDestinationCalled = true
        lastDestination = destination
        
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
    
    func switchTab(to tab: Int, destination: NavDestination? = nil) {
        switchTabCalled = true
        lastTabIndex = tab
        selectedTab = tab
        state.selectedTab = tab
        
        if let destination = destination {
            navigate(to: destination)
        }
    }
    
    func navigateBack() {
        navigateBackCalled = true
        
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
    
    func navigateToRoot() {
        navigateToRootCalled = true
        
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
    
    func presentSheet(_ destination: NavDestination) {
        presentSheetCalled = true
        lastDestination = destination
        sheetDestination = destination
        state.sheetDestination = destination
    }
    
    func dismissSheet() {
        dismissSheetCalled = true
        sheetDestination = nil
        state.sheetDestination = nil
    }
    
    func presentFullScreen(_ destination: NavDestination) {
        presentFullScreenCalled = true
        lastDestination = destination
        fullScreenDestination = destination
        state.fullScreenDestination = destination
    }
    
    func dismissFullScreen() {
        dismissFullScreenCalled = true
        fullScreenDestination = nil
        state.fullScreenDestination = nil
    }
    
    // MARK: - Convenience Methods
    
    func showPayslipDetail(id: UUID) {
        showPayslipDetailCalled = true
        lastPayslipId = id
        navigate(to: .payslipDetail(id: id))
    }
    
    func showPDFPreview(document: PDFDocument) {
        showPDFPreviewCalled = true
        presentSheet(.pdfPreview(document: document))
    }
    
    func showAddPayslip() {
        showAddPayslipCalled = true
        presentSheet(.addPayslip)
    }
    
    func handleDeepLink(_ url: URL) {
        handleDeepLinkCalled = true
        lastDeepLinkURL = url
        
        // Simple implementation for testing
        if url.path.lowercased() == "/home" {
            switchTab(to: 0)
        } else if url.path.lowercased() == "/payslips" {
            switchTab(to: 1)
        }
    }
    
    // MARK: - Reset for testing
    
    func resetTracking() {
        navigateToDestinationCalled = false
        lastDestination = nil
        switchTabCalled = false
        lastTabIndex = -1
        navigateBackCalled = false
        navigateToRootCalled = false
        presentSheetCalled = false
        dismissSheetCalled = false
        presentFullScreenCalled = false
        dismissFullScreenCalled = false
        showPayslipDetailCalled = false
        lastPayslipId = nil
        showPDFPreviewCalled = false
        showAddPayslipCalled = false
        handleDeepLinkCalled = false
        lastDeepLinkURL = nil
    }
} 
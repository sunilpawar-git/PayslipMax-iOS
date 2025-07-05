import SwiftUI
import PDFKit

/// Router class for managing navigation
@MainActor
class NavRouter: RouterProtocol {
    // Navigation state
    private let state: NavigationState
    
    // Published properties required by RouterProtocol
    var homeStack: NavigationPath { get { state.homeStack } set { state.homeStack = newValue } }
    var payslipsStack: NavigationPath { get { state.payslipsStack } set { state.payslipsStack = newValue } }
    var insightsStack: NavigationPath { get { state.insightsStack } set { state.insightsStack = newValue } }
    var settingsStack: NavigationPath { get { state.settingsStack } set { state.settingsStack = newValue } }
    
    @Published var sheetDestination: AppNavigationDestination? {
        didSet { state.sheetDestination = sheetDestination }
    }
    
    @Published var fullScreenDestination: AppNavigationDestination? {
        didSet { state.fullScreenDestination = fullScreenDestination }
    }
    
    @Published var selectedTab: Int {
        didSet { state.selectedTab = selectedTab }
    }
    
    // MARK: - Initialization
    
    init(state: NavigationState? = nil) {
        // Use provided state or create a new one
        let effectiveState = state ?? NavigationState()
        self.state = effectiveState
        
        // Initialize published properties from state
        // Stacks are implicitly handled by state reference
        self.sheetDestination = effectiveState.sheetDestination
        self.fullScreenDestination = effectiveState.fullScreenDestination
        self.selectedTab = effectiveState.selectedTab
        
        // Setup notification observer for tab switching
        setupNotificationObservers()
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Add observer for SwitchToPayslipsTab notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchToPayslipsTab),
            name: .switchToPayslipsTab,
            object: nil
        )
    }
    
    @objc private func handleSwitchToPayslipsTab() {
        // Switch to the Payslips tab (index 1)
        DispatchQueue.main.async {
            self.selectedTab = 1
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to destination in the current tab
    func navigate(to destination: AppNavigationDestination) {
        state.appendToActiveStack(destination)
        // Published stacks update automatically via state binding
    }
    
    /// Switch tab and optionally navigate
    func switchTab(to tab: Int, destination: AppNavigationDestination? = nil) {
        // Update local published property first to trigger UI update
        selectedTab = tab 
        // Then update the underlying state
        state.selectedTab = tab
        
        if let destination = destination {
            navigate(to: destination)
        }
    }
    
    /// Pop the active stack
    func navigateBack() {
        state.removeLastFromActiveStack()
        // Published stacks update automatically via state binding
    }
    
    /// Reset the active stack
    func navigateToRoot() {
        state.clearActiveStack()
        // Published stacks update automatically via state binding
    }
    
    /// Present a sheet
    func presentSheet(_ destination: AppNavigationDestination) {
        sheetDestination = destination
        state.sheetDestination = destination
    }
    
    /// Dismiss the sheet
    func dismissSheet() {
        sheetDestination = nil
        state.sheetDestination = nil
    }
    
    /// Present fullscreen cover
    func presentFullScreen(_ destination: AppNavigationDestination) {
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
    
    // Add convenience methods for other cases if needed
    func showScanner() {
        presentFullScreen(.scanner)
    }
    
    func showPinSetup() {
        presentSheet(.pinSetup)
    }
} 
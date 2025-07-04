import SwiftUI
import PDFKit

/// Unified navigation coordinator that replaces AppCoordinator and NavRouter
/// This is the single source of truth for all navigation in the app
@MainActor
class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    /// Currently selected tab index
    @Published var selectedTab: Int = 0
    
    /// Navigation stacks for each tab (separate stacks prevent cross-tab pollution)
    @Published var homeStack = NavigationPath()
    @Published var payslipsStack = NavigationPath()
    @Published var insightsStack = NavigationPath()
    @Published var settingsStack = NavigationPath()
    
    /// Currently presented sheet destination
    @Published var sheet: AppNavigationDestination?
    
    /// Currently presented full-screen cover destination
    @Published var fullScreenCover: AppNavigationDestination?
    
    // MARK: - Computed Properties
    
    /// Returns the currently active navigation stack
    var currentStack: NavigationPath {
        switch selectedTab {
        case 0: return homeStack
        case 1: return payslipsStack
        case 2: return insightsStack
        case 3: return settingsStack
        default: return homeStack
        }
    }
    
    /// Sets the current navigation stack
    private func setCurrentStack(_ newPath: NavigationPath) {
        switch selectedTab {
        case 0: homeStack = newPath
        case 1: payslipsStack = newPath
        case 2: insightsStack = newPath
        case 3: settingsStack = newPath
        default: homeStack = newPath
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchToPayslipsTab),
            name: .switchToPayslipsTab,
            object: nil
        )
    }
    
    @objc private func handleSwitchToPayslipsTab() {
        switchTab(to: 1)
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a destination within the currently active tab stack
    func navigate(to destination: AppNavigationDestination) {
        var stack = currentStack
        stack.append(destination)
        setCurrentStack(stack)
    }
    
    /// Switch to a specific tab and optionally navigate to a destination
    func switchTab(to index: Int, destination: AppNavigationDestination? = nil) {
        guard index >= 0 && index < 4 else { return }
        selectedTab = index
        if let destination = destination {
            navigate(to: destination)
        }
    }
    
    /// Pop the last view from the currently active navigation stack
    func navigateBack() {
        var stack = currentStack
        if !stack.isEmpty {
            stack.removeLast()
            setCurrentStack(stack)
        }
    }
    
    /// Pop all views from the currently active navigation stack
    func navigateToRoot() {
        setCurrentStack(NavigationPath())
    }
    
    /// Present a destination as a sheet
    func presentSheet(_ destination: AppNavigationDestination) {
        sheet = destination
    }
    
    /// Dismiss the currently presented sheet
    func dismissSheet() {
        sheet = nil
    }
    
    /// Present a destination as a full-screen cover
    func presentFullScreen(_ destination: AppNavigationDestination) {
        fullScreenCover = destination
    }
    
    /// Dismiss the currently presented full-screen cover
    func dismissFullScreen() {
        fullScreenCover = nil
    }
    
    // MARK: - Convenience Methods
    
    /// Navigate to a specific payslip detail view
    func showPayslipDetail(id: UUID) {
        navigate(to: .payslipDetail(id: id))
    }
    
    /// Present a PDF document preview
    func showPDFPreview(document: PDFDocument) {
        presentSheet(.pdfPreview(document: document))
    }
    
    /// Present the Add Payslip flow
    func showAddPayslip() {
        presentSheet(.addPayslip)
    }
    
    /// Present the scanner
    func showScanner() {
        presentFullScreen(.scanner)
    }
    
    /// Present PIN setup
    func showPinSetup() {
        presentSheet(.pinSetup)
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle deep links from URLs
    /// Returns true if the deep link was successfully handled
    func handleDeepLink(_ url: URL) -> Bool {
        // Extract components from the URL
        guard url.scheme == "payslipmax" else { return false }
        
        let path = url.host ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        
        switch path {
        case "home":
            switchTab(to: 0)
            return true
            
        case "payslips":
            switchTab(to: 1)
            return true
            
        case "insights":
            switchTab(to: 2)
            return true
            
        case "settings":
            switchTab(to: 3)
            return true
            
        case "upload":
            // Handle upload deep links (from QR codes)
            switchTab(to: 1)
            return true
            
        case "payslip":
            // Handle specific payslip deep links
            if let idString = queryItems.first(where: { $0.name == "id" })?.value,
               let payslipUUID = UUID(uuidString: idString) {
                switchTab(to: 1)
                showPayslipDetail(id: payslipUUID)
                return true
            }
            return false
            
        case "privacy":
            presentSheet(.privacyPolicy)
            return true
            
        case "terms":
            presentSheet(.termsOfService)
            return true
            
        case "web-uploads":
            switchTab(to: 3)
            navigate(to: .webUploads)
            return true
            
        default:
            return false
        }
    }
} 
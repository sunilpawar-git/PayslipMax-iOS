import SwiftUI
import PDFKit

/// Mock implementation of RouterProtocol for testing and previews.
@MainActor
class MockRouter: RouterProtocol {
    // MARK: - State Properties
    
    @Published var homeStack = NavigationPath()
    @Published var payslipsStack = NavigationPath()
    @Published var insightsStack = NavigationPath()
    @Published var settingsStack = NavigationPath()
    
    @Published var sheetDestination: AppNavigationDestination? // Use new enum
    @Published var fullScreenDestination: AppNavigationDestination? // Use new enum
    
    @Published var selectedTab: Int = 0
    
    // MARK: - Tracking Properties (for testing)
    
    var navigateCalledWith: AppNavigationDestination? // Use new enum
    var switchTabCalledWith: (tab: Int, destination: AppNavigationDestination?)? // Use new enum
    var navigateBackCallCount = 0
    var navigateToRootCallCount = 0
    var presentSheetCalledWith: AppNavigationDestination? // Use new enum
    var dismissSheetCallCount = 0
    var presentFullScreenCalledWith: AppNavigationDestination? // Use new enum
    var dismissFullScreenCallCount = 0
    var showPayslipDetailCalledWithId: UUID?
    var showPDFPreviewCalledWithDocument: PDFDocument?
    var showAddPayslipCallCount = 0
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Navigation Methods Implementation
    
    func navigate(to destination: AppNavigationDestination) { // Use new enum
        navigateCalledWith = destination
        // Simulate appending to the correct stack based on selectedTab
        switch selectedTab {
        case 0: homeStack.append(destination)
        case 1: payslipsStack.append(destination)
        case 2: insightsStack.append(destination)
        case 3: settingsStack.append(destination)
        default: break
        }
        print("[MockRouter] navigate(to: \(destination)) called. Current stack: \(activeStack)")
    }
    
    func switchTab(to tab: Int, destination: AppNavigationDestination?) { // Use new enum
        switchTabCalledWith = (tab, destination)
        selectedTab = tab
        if let dest = destination {
            navigate(to: dest)
        }
        print("[MockRouter] switchTab(to: \(tab), destination: \(destination?.id ?? "nil")) called.")
    }
    
    func navigateBack() {
        navigateBackCallCount += 1
        // Simulate popping from the correct stack
        switch selectedTab {
        case 0: if !homeStack.isEmpty { homeStack.removeLast() }
        case 1: if !payslipsStack.isEmpty { payslipsStack.removeLast() }
        case 2: if !insightsStack.isEmpty { insightsStack.removeLast() }
        case 3: if !settingsStack.isEmpty { settingsStack.removeLast() }
        default: break
        }
        print("[MockRouter] navigateBack() called. Count: \(navigateBackCallCount). Current stack: \(activeStack)")
    }
    
    func navigateToRoot() {
        navigateToRootCallCount += 1
        // Simulate clearing the correct stack
        switch selectedTab {
        case 0: homeStack = NavigationPath()
        case 1: payslipsStack = NavigationPath()
        case 2: insightsStack = NavigationPath()
        case 3: settingsStack = NavigationPath()
        default: break
        }
        print("[MockRouter] navigateToRoot() called. Count: \(navigateToRootCallCount)")
    }
    
    func presentSheet(_ destination: AppNavigationDestination) { // Use new enum
        presentSheetCalledWith = destination
        sheetDestination = destination
        print("[MockRouter] presentSheet(\(destination)) called.")
    }
    
    func dismissSheet() {
        dismissSheetCallCount += 1
        sheetDestination = nil
        print("[MockRouter] dismissSheet() called. Count: \(dismissSheetCallCount)")
    }
    
    func presentFullScreen(_ destination: AppNavigationDestination) { // Use new enum
        presentFullScreenCalledWith = destination
        fullScreenDestination = destination
        print("[MockRouter] presentFullScreen(\(destination)) called.")
    }
    
    func dismissFullScreen() {
        dismissFullScreenCallCount += 1
        fullScreenDestination = nil
        print("[MockRouter] dismissFullScreen() called. Count: \(dismissFullScreenCallCount)")
    }
    
    // MARK: - Convenience Methods Implementation
    
    func showPayslipDetail(id: UUID) {
        showPayslipDetailCalledWithId = id
        navigate(to: .payslipDetail(id: id)) // Use correct case
        print("[MockRouter] showPayslipDetail(id: \(id)) called.")
    }
    
    func showPDFPreview(document: PDFDocument) {
        showPDFPreviewCalledWithDocument = document
        presentSheet(.pdfPreview(document: document)) // Use correct case
        print("[MockRouter] showPDFPreview() called.")
    }
    
    func showAddPayslip() {
        showAddPayslipCallCount += 1
        presentSheet(.addPayslip) // Use correct case
        print("[MockRouter] showAddPayslip() called. Count: \(showAddPayslipCallCount)")
    }
    
    // MARK: - Helper for Testing
    
    /// Helper to get the currently active NavigationPath based on selectedTab
    private var activeStack: NavigationPath {
        switch selectedTab {
        case 0: return homeStack
        case 1: return payslipsStack
        case 2: return insightsStack
        case 3: return settingsStack
        default: return NavigationPath() // Should not happen
        }
    }
} 
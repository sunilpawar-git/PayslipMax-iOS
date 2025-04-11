import SwiftUI
import PDFKit

/// Manages the navigation state for the application
/// This class is responsible for maintaining the navigation paths and modal presentations
/// but doesn't contain any navigation logic
@MainActor
class NavigationState: ObservableObject {
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
    
    /// Returns the active stack based on the selected tab
    var activeStack: NavigationPath {
        switch selectedTab {
        case 0: return homeStack
        case 1: return payslipsStack
        case 2: return insightsStack
        case 3: return settingsStack
        default: return homeStack
        }
    }
    
    /// Appends a destination to the active stack
    func appendToActiveStack(_ destination: NavDestination) {
        switch selectedTab {
        case 0: homeStack.append(destination)
        case 1: payslipsStack.append(destination)
        case 2: insightsStack.append(destination)
        case 3: settingsStack.append(destination)
        default: break
        }
    }
    
    /// Removes the last item from the active stack
    func removeLastFromActiveStack() {
        switch selectedTab {
        case 0: if !homeStack.isEmpty { homeStack.removeLast() }
        case 1: if !payslipsStack.isEmpty { payslipsStack.removeLast() }
        case 2: if !insightsStack.isEmpty { insightsStack.removeLast() }
        case 3: if !settingsStack.isEmpty { settingsStack.removeLast() }
        default: break
        }
    }
    
    /// Clears the active stack
    func clearActiveStack() {
        switch selectedTab {
        case 0: homeStack = NavigationPath()
        case 1: payslipsStack = NavigationPath()
        case 2: insightsStack = NavigationPath()
        case 3: settingsStack = NavigationPath()
        default: break
        }
    }
    
    /// Resets all navigation state
    func reset() {
        homeStack = NavigationPath()
        payslipsStack = NavigationPath()
        insightsStack = NavigationPath()
        settingsStack = NavigationPath()
        sheetDestination = nil
        fullScreenDestination = nil
        selectedTab = 0
    }
} 
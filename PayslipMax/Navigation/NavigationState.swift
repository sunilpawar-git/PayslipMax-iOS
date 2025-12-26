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
    @Published var sheetDestination: AppNavigationDestination?
    @Published var fullScreenDestination: AppNavigationDestination?

    // Current tab selection
    @Published var selectedTab: Int = 0

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
    func appendToActiveStack(_ destination: AppNavigationDestination) {
        switch selectedTab {
        case 0: homeStack.append(destination)
        case 1: payslipsStack.append(destination)
        case 2: insightsStack.append(destination)
        case 3: settingsStack.append(destination)
        default: print("Warning: Trying to navigate on unknown tab index \(selectedTab)")
        }
    }

    /// Removes the last item from the active stack
    func removeLastFromActiveStack() {
        switch selectedTab {
        case 0: if !homeStack.isEmpty { homeStack.removeLast() }
        case 1: if !payslipsStack.isEmpty { payslipsStack.removeLast() }
        case 2: if !insightsStack.isEmpty { insightsStack.removeLast() }
        case 3: if !settingsStack.isEmpty { settingsStack.removeLast() }
        default: print("Warning: Trying to navigate back on unknown tab index \(selectedTab)")
        }
    }

    /// Clears the active stack
    func clearActiveStack() {
        switch selectedTab {
        case 0: homeStack = NavigationPath()
        case 1: payslipsStack = NavigationPath()
        case 2: insightsStack = NavigationPath()
        case 3: settingsStack = NavigationPath()
        default: print("Warning: Trying to navigate to root on unknown tab index \(selectedTab)")
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
        selectedTab = AppTab.home.rawValue
    }
}

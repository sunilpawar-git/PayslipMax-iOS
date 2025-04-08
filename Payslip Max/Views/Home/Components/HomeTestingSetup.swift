import SwiftUI

/// Extracts UI testing related code from HomeView to improve separation of concerns
struct HomeTestingSetup: ViewModifier {
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if isUITesting {
                    UITestingSetup.setupForUITesting()
                }
            }
    }
}

extension View {
    func homeTestingSetup() -> some View {
        self.modifier(HomeTestingSetup())
    }
} 
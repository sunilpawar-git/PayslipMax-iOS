import SwiftUI

/// Container view that manages splash screen display for all app flows
/// Decouples splash screen from authentication - shows for all users
struct SplashContainerView<Content: View>: View {
    @State private var showingSplash = true
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if showingSplash {
                SplashScreenView {
                    showingSplash = false
                }
            } else {
                content
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashContainerView {
        Text("Main App Content")
    }
} 
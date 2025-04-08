import SwiftUI
import SwiftData

/// This file contains preview helpers for MainTabView
struct MainTabViewPreview: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    MainTabViewPreview()
}

// Simple preview that doesn't require SwiftData
#Preview("Basic") {
    MainTabView()
}

// Dark mode preview
#Preview("Dark Mode") {
    MainTabView()
        .environment(\.colorScheme, .dark)
}

// Note: Device selection should be done through the Canvas UI
// rather than in code when using the #Preview macro
#Preview("More Options") {
    MainTabView()
} 
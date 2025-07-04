import SwiftUI
import SwiftData

/// This file contains preview helpers for UnifiedAppView
struct UnifiedAppViewPreview: View {
    var body: some View {
        UnifiedAppView()
    }
}

#Preview {
    UnifiedAppViewPreview()
}

// Simple preview that doesn't require SwiftData
#Preview("Basic") {
    UnifiedAppView()
}

// Dark mode preview
#Preview("Dark Mode") {
    UnifiedAppView()
        .preferredColorScheme(.dark)
}

// Note: Device selection should be done through the Canvas UI
// rather than in code when using the #Preview macro
#Preview("More Options") {
    UnifiedAppView()
} 
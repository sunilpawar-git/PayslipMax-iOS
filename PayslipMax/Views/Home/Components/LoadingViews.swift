import SwiftUI

/// A loading view with a progress indicator and text
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Processing...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .transition(.opacity)
        .accessibilityIdentifier("loading_overlay")
    }
}

/// A loading overlay with a shorter delay to prevent flashing for quick operations
struct LoadingOverlay: View {
    @State private var isVisible = false
    // A unique ID to help identify and reset the overlay properly
    let id = UUID()
    
    var body: some View {
        if isVisible {
            LoadingView()
                .animation(.easeIn(duration: 0.2), value: isVisible)
                .id("loading-\(id)")
                .onDisappear {
                    // Ensure we reset state when view disappears
                    isVisible = false
                }
        } else {
            Color.clear
                .onAppear {
                    // Only show loading indicator after a very short delay
                    // This prevents flashing for quick operations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        // Check if view is still mounted before showing
                        isVisible = true
                    }
                }
        }
    }
}

#Preview {
    LoadingOverlay()
} 
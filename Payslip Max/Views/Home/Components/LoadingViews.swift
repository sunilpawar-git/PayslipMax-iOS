import SwiftUI

/// A loading view with a progress indicator and text
struct LoadingView: View {
    @State private var shouldDismiss = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
        }
        .opacity(shouldDismiss ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: shouldDismiss)
        .onAppear {
            // Auto-dismiss after 3 seconds to prevent lingering
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                shouldDismiss = true
            }
        }
    }
}

/// A loading overlay with a delay to prevent flashing for quick operations
struct LoadingOverlay: View {
    @State private var isVisible = false
    
    var body: some View {
        if isVisible {
            LoadingView()
        } else {
            Color.clear
                .onAppear {
                    // Only show loading indicator after a short delay
                    // This prevents flashing for quick operations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isVisible = true
                    }
                }
        }
    }
}

#Preview {
    LoadingOverlay()
} 
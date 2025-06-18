import SwiftUI

/// Splash screen that displays financial quotes after authentication
/// Follows single responsibility principle - only handles quote display and timing
/// Now uses app's fintech color theme for consistency
struct SplashScreenView: View {
    @State private var currentQuote: SplashQuote
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    @Environment(\.colorScheme) private var colorScheme
    
    let onComplete: () -> Void
    
    /// Initialize with random quote
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        self._currentQuote = State(initialValue: SplashQuoteService.getRandomQuote())
    }
    
    var body: some View {
        ZStack {
            // Background gradient using app theme colors
            backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 32) {
                // App logo
                appLogo
                
                // Quote card with fintech design
                quoteCard
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            performEntryAnimation()
            startTimer()
        }
    }
    
    // MARK: - UI Components
    
    private var backgroundGradient: some View {
        // Deep blue background matching the image provided
        LinearGradient(
            gradient: Gradient(colors: [
                FintechColors.primaryBlue,
                FintechColors.primaryBlue.opacity(0.95),
                FintechColors.secondaryBlue.opacity(0.9)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var appLogo: some View {
        VStack(spacing: 16) {
            ZStack {
                // Clean white circular background matching your app's style
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                
                // Document icon - clean and prominent
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // App name with clean white text matching your design
            Text("PayslipMax")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.top, 80)
    }
    
    private var quoteCard: some View {
        ZStack {
            // Subtle card background that doesn't compete with the logo
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            // Quote content with clean typography
            VStack(spacing: 16) {
                // Quote text - clean and readable
                Text(currentQuote.text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                
                // Author with clean styling
                if let author = currentQuote.author {
                    Text("— \(author)")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .italic()
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Properties
    
    // MARK: - Animations & Timing
    
    private func performEntryAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            opacity = 1.0
            scale = 1.0
        }
    }
    
    private func startTimer() {
        Task {
            // Wait for 3 seconds using structured concurrency (no DispatchSemaphore!)
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            await MainActor.run {
                performExitAnimation()
            }
        }
    }
    
    private func performExitAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 0
            scale = 0.9
        }
        
        // Complete after animation finishes using structured concurrency
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView {
        print("Splash completed")
    }
} 
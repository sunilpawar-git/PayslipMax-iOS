import SwiftUI

/// Simplified quiz context card (gamification temporarily disabled)
struct QuizContextCard: View {
    @State private var showFullDetails = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Financial Quiz")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Test your financial knowledge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue.opacity(0.7))
            }
            
            // Simplified info message
            Text("Quiz functionality temporarily unavailable while implementing investment tips")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.05),
                            Color.green.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct QuizContextCard_Previews: PreviewProvider {
    static var previews: some View {
        QuizContextCard()
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
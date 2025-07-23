import SwiftUI

/// Simplified quiz section component for the Home screen (quiz temporarily disabled)
@MainActor
struct HomeQuizSection: View {
    let payslips: [AnyPayslip]
    @State private var showQuizSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clean header
            headerSection
            
            // Simplified description
            descriptionSection
            
            // Disabled action button
            disabledActionButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.05),
                            Color.purple.opacity(0.05)
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
    
    // MARK: - Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🧠 Financial Quiz")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Test your payslip knowledge")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue.opacity(0.7))
        }
    }
    
    private var descriptionSection: some View {
        Text("Quiz functionality is temporarily disabled while we implement the enhanced investment tips section.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
    }
    
    private var disabledActionButton: some View {
        Button(action: {
            // No action - disabled
        }) {
            HStack {
                Text("Coming Soon")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.6))
            )
        }
        .disabled(true)
    }
}

// MARK: - Preview

struct HomeQuizSection_Previews: PreviewProvider {
    static var previews: some View {
        HomeQuizSection(payslips: [])
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
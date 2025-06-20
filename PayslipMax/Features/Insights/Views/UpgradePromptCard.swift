import SwiftUI

// MARK: - Upgrade Prompt Card

struct UpgradePromptCard: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Premium icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                FintechColors.primaryBlue,
                                FintechColors.secondaryBlue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "crown.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Premium Insights")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text("Get AI-powered predictions, professional recommendations, and advanced analytics to maximize your financial potential.")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 8) {
                PremiumFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Predictions",
                    description: "Future income & savings projections"
                )
                
                PremiumFeatureRow(
                    icon: "person.badge.shield.checkmark",
                    title: "Expert Recommendations",
                    description: "Professional financial advice"
                )
                
                PremiumFeatureRow(
                    icon: "chart.bar.xaxis",
                    title: "Advanced Analytics",
                    description: "Industry benchmarks & comparisons"
                )
            }
            
            // CTA Button
            Button(action: action) {
                HStack {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            FintechColors.primaryBlue,
                            FintechColors.secondaryBlue
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Text("Starting from ₹99/month")
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(FintechColors.primaryBlue)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    UpgradePromptCard {
        print("Upgrade tapped")
    }
    .padding()
} 
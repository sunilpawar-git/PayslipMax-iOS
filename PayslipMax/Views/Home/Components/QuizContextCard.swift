import SwiftUI

/// Informational card that explains the quiz system and scoring mechanics
/// Helps users understand the gamification elements and motivates participation
struct QuizContextCard: View {
    @ObservedObject private var gamificationCoordinator = GamificationCoordinator.shared
    @State private var showFullDetails = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with expandable info
            headerSection
            
            // Quick stats
            if gamificationCoordinator.totalQuestionsAnswered > 0 {
                quickStatsSection
            }
            
            // Expandable details
            if showFullDetails {
                detailsSection
            } else {
                expandButton
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            FintechColors.primaryBlue.opacity(0.05),
                            FintechColors.premiumGold.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FintechColors.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.title3)
                    
                    Text("Knowledge Rewards")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
                
                Text("Learn about your payslip and earn stars!")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            Spacer()
            
            // Current star count badge
            starCountBadge
        }
    }
    
    private var starCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(FintechColors.premiumGold)
                .font(.title3)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(gamificationCoordinator.currentStarCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                    .contentTransition(.numericText())
                
                Text("stars")
                    .font(.caption2)
                    .foregroundColor(FintechColors.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FintechColors.premiumGold.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FintechColors.premiumGold.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: 20) {
            statItem(
                title: "Level",
                value: "\(gamificationCoordinator.currentLevel)",
                icon: "crown.fill",
                color: FintechColors.primaryBlue
            )
            
            statItem(
                title: "Accuracy",
                value: "\(Int(gamificationCoordinator.currentAccuracy))%",
                icon: "target",
                color: .green
            )
            
            if gamificationCoordinator.currentStreak > 0 {
                statItem(
                    title: "Streak",
                    value: "\(gamificationCoordinator.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
    
    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(FintechColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Expand Button
    
    private var expandButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFullDetails.toggle()
            }
        }) {
            HStack {
                Text("How it works")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.primaryBlue)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(FintechColors.primaryBlue)
                    .rotationEffect(.degrees(showFullDetails ? 180 : 0))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

#Preview {
    QuizContextCard()
        .padding()
        .background(Color(.systemBackground))
} 
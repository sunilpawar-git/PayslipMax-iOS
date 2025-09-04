import SwiftUI

/// Quiz results panel component with scores, metrics, and achievements
struct QuizResultsPanel: View {
    let results: QuizResults?
    let recentAchievements: [Achievement]
    
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(FintechColors.successGreen.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FintechColors.successGreen)
            }
            
            // Results summary
            if let results = results {
                VStack(spacing: 16) {
                    Text("Quiz Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Score display
                    VStack(spacing: 8) {
                        Text("\(results.correctAnswers)/\(results.totalQuestions)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.primaryBlue)
                        
                        Text("Questions Correct")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Performance metrics
                    HStack(spacing: 30) {
                        metricView("Accuracy", "\(Int(results.accuracyPercentage))%")
                        metricView("Grade", results.performanceGrade)
                        metricView("Points", "\(results.totalScore)")
                    }
                    
                    // Achievement celebration
                    if !recentAchievements.isEmpty {
                        achievementCelebrationView
                    }
                }
            }
            
            // Encouraging message instead of "Take Another Quiz"
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Good attempt at increasing financial literacy")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        Text("🔥")
                            .font(.title2)
                    }
                    
                    Text("Come back after you upload next payslip for fresh round of quiz questions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Button("Close") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(FintechColors.primaryBlue)
                .controlSize(.large)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func metricView(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.primaryBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var achievementCelebrationView: some View {
        VStack(spacing: 12) {
            Text("🎉 New Achievement!")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(recentAchievements.prefix(3), id: \.id) { achievement in
                HStack {
                    Image(systemName: achievement.iconName)
                        .foregroundColor(achievement.badgeColor)
                    
                    VStack(alignment: .leading) {
                        Text(achievement.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FintechColors.premiumGold.opacity(0.1))
        )
    }
}

// MARK: - Preview
#if DEBUG
struct QuizResultsPanel_Previews: PreviewProvider {
    static var previews: some View {
        QuizResultsPanel(
            results: QuizResults(
                totalQuestions: 5,
                correctAnswers: 4,
                totalScore: 8,
                totalPossibleScore: 10,
                timeTaken: 120.0,
                achievementsUnlocked: []
            ),
            recentAchievements: [],
            onClose: {}
        )
    }
}
#endif

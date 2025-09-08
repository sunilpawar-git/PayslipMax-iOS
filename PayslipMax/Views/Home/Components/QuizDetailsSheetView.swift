import SwiftUI

/// Dedicated view for displaying quiz details in a sheet
/// Extracted from HomeQuizSection to maintain file size limits
@MainActor
struct QuizDetailsSheetView: View {
    @ObservedObject private var gamificationCoordinator: GamificationCoordinator
    @Binding var showDetailsSheet: Bool

    init(gamificationCoordinator: GamificationCoordinator, showDetailsSheet: Binding<Bool>) {
        self.gamificationCoordinator = gamificationCoordinator
        self._showDetailsSheet = showDetailsSheet
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // How scoring works
                    scoringExplanationSection

                    // Progress details
                    progressDetailsSection

                    // Question types
                    questionTypesSection

                    // Debug section (for development)
                    if AppConstants.isDevelopmentMode {
                        debugSection
                    }
                }
                .padding()
            }
            .navigationTitle("Quiz Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDetailsSheet = false
                    }
                }
            }
        }
    }

    private var scoringExplanationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(FintechColors.premiumGold)
                    .font(.title2)

                Text("How Scoring Works")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("Earn stars by answering questions correctly. Higher difficulty questions give more stars!")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Detailed scoring rules
            VStack(spacing: 12) {
                QuizHelperViews.scoringRuleRow("Easy Questions", "+1 star", "Basic payslip understanding", .green, "checkmark.circle.fill")
                QuizHelperViews.scoringRuleRow("Medium Questions", "+2 stars", "Intermediate calculations", .orange, "star.leadinghalf.filled")
                QuizHelperViews.scoringRuleRow("Hard Questions", "+3 stars", "Advanced financial concepts", .red, "star.circle.fill")
                QuizHelperViews.scoringRuleRow("Wrong Answers", "-1 star", "Don't worry, keep learning!", .red, "minus.circle.fill")
            }
        }
    }

    private var progressDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                QuizHelperViews.progressInfoRow("Total Stars", "\(gamificationCoordinator.currentStarCount)")
                QuizHelperViews.progressInfoRow("Current Level", "\(gamificationCoordinator.currentLevel)")
                QuizHelperViews.progressInfoRow("Questions Answered", "\(gamificationCoordinator.totalQuestionsAnswered)")
                if gamificationCoordinator.totalQuestionsAnswered > 0 {
                    QuizHelperViews.progressInfoRow("Accuracy", "\(Int(gamificationCoordinator.currentAccuracy))%")
                    QuizHelperViews.progressInfoRow("Current Streak", "\(gamificationCoordinator.currentStreak)")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }

    private var questionTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Types")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Questions are personalized based on your uploaded payslips and cover:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    QuizHelperViews.bulletPoint("Income calculations and breakdowns")
                    QuizHelperViews.bulletPoint("Deduction analysis and explanations")
                    QuizHelperViews.bulletPoint("Tax calculations and withholdings")
                    QuizHelperViews.bulletPoint("Financial insights and trends")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }

    // MARK: - Debug Section (Development Only)

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Reset Quiz Progress") {
                gamificationCoordinator.resetProgress()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .frame(maxWidth: .infinity)

            Text("This will reset your stars to 0 and clear all progress")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.1))
        )
    }
}

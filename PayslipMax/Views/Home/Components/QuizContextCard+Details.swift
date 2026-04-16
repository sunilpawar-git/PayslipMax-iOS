import SwiftUI

// MARK: - Details Section

extension QuizContextCard {

    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            scoringSection

            benefitsSection

            progressSection
        }
    }

    // MARK: - Scoring Section

    var scoringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌟 How You Earn Stars")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)

            VStack(spacing: 6) {
                scoringRow("Easy questions", "+1 star", .green)
                scoringRow("Medium questions", "+2 stars", .orange)
                scoringRow("Hard questions", "+3 stars", .red)
                scoringRow("Wrong answers", "-1 star", .red)
            }
        }
    }

    func scoringRow(_ difficulty: String, _ reward: String, _ color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(difficulty)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)

            Spacer()

            Text(reward)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }

    // MARK: - Benefits Section

    var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Why Take Quizzes?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                benefitRow("Understand your payslip better")
                benefitRow("Learn about taxes and deductions")
                benefitRow("Track your financial literacy progress")
                benefitRow("Unlock achievements and badges")
            }
        }
    }

    func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .offset(y: 1)

            Text(text)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Progress Section

    var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📈 Your Progress")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)

            VStack(spacing: 6) {
                progressRow("Level up every 100 stars")
                progressRow("Maintain streaks for bonus rewards")
                progressRow("Questions get personalized to your data")
            }
        }
    }

    func progressRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(FintechColors.primaryBlue)
                .font(.caption)
                .offset(y: 1)

            Text(text)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
}

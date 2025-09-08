import SwiftUI

/// Quiz section component for the Home screen
/// Displays personalized payslip knowledge quiz with gamification elements
/// Refactored to maintain file size under 300 lines
@MainActor
struct HomeQuizSection: View {
    let payslips: [AnyPayslip]
    @State private var showQuizSheet = false
    @State private var showDetailsSheet = false
    @ObservedObject private var quizViewModel: QuizViewModel
    @ObservedObject private var gamificationCoordinator: GamificationCoordinator

    init(payslips: [AnyPayslip], quizViewModel: QuizViewModel? = nil, gamificationCoordinator: GamificationCoordinator? = nil) {
        self.payslips = payslips
        self.quizViewModel = quizViewModel ?? DIContainer.shared.makeQuizViewModel()
        // Use DI container for gamification coordinator
        self.gamificationCoordinator = gamificationCoordinator ?? DIContainer.shared.makeGamificationCoordinator()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clean header with minimal info
            headerSection

            // Simplified description
            descriptionSection

            // Primary action button
            primaryActionButton

            // Secondary options (compact)
            if !payslips.isEmpty {
                secondaryOptionsSection
            }
        }
        .padding()
        .background(FintechColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showQuizSheet) {
            QuizView(viewModel: quizViewModel)
        }
        .sheet(isPresented: $showDetailsSheet) {
            QuizDetailsSheetView(
                gamificationCoordinator: gamificationCoordinator,
                showDetailsSheet: $showDetailsSheet
            )
        }
        .onAppear {
            gamificationCoordinator.refreshData()
        }
    }

    // MARK: - Header Section (Clean)

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payslip Quiz")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)

                if gamificationCoordinator.totalQuestionsAnswered > 0 {
                    Text("Level \(gamificationCoordinator.currentLevel)")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                // Star count (cleaner display)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.subheadline)
                    Text("\(gamificationCoordinator.currentStarCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                        .contentTransition(.numericText())
                }

                // Info button - leads to details sheet
                Button(action: {
                    showDetailsSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.primaryBlue)
                }
            }
        }
    }

    // MARK: - Description Section (Simplified)

    private var descriptionSection: some View {
        Text("Test your payslip knowledge and earn stars!")
            .font(.subheadline)
            .foregroundColor(FintechColors.textSecondary)
    }

    // MARK: - Primary Action Button

    private var primaryActionButton: some View {
        Button(action: {
            Task {
                await startQuiz()
            }
        }) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Start Quiz")
                        .fontWeight(.semibold)

                    Text("5 questions • ~2 minutes")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [FintechColors.primaryBlue, FintechColors.secondaryBlue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(payslips.isEmpty)
    }

    // MARK: - Secondary Options (Compact)

    private var secondaryOptionsSection: some View {
        HStack(spacing: 12) {
            Button("Quick (3)") {
                Task {
                    await startQuiz(questionCount: 3)
                }
            }
            .buttonStyle(.bordered)
            .tint(FintechColors.primaryBlue)
            .controlSize(.small)

            Button("Challenge (10)") {
                Task {
                    await startQuiz(questionCount: 10, difficulty: .hard)
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .controlSize(.small)

            Spacer()

            // Compact streak indicator
            if gamificationCoordinator.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(gamificationCoordinator.currentStreak)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Helper Functions

    private func startQuiz(questionCount: Int = 5, difficulty: QuizDifficulty? = nil) async {
        await quizViewModel.startQuiz(
            questionCount: questionCount,
            difficulty: difficulty
        )
        showQuizSheet = true
    }
}

#Preview {
    HomeQuizSection(payslips: [])
        .padding()
}

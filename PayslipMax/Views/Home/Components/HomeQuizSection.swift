import SwiftUI

/// Quiz section component for the Home screen
/// Displays personalized payslip knowledge quiz with gamification elements
@MainActor
struct HomeQuizSection: View {
    let payslips: [AnyPayslip]
    @State private var showQuizSheet = false
    @State private var showDetailsSheet = false
    @StateObject private var quizViewModel = DIContainer.shared.makeQuizViewModel()
    @ObservedObject private var gamificationCoordinator = GamificationCoordinator.shared
    
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
            quizDetailsSheet
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
    
    // MARK: - Quiz Details Sheet (Contains all the previous clutter)
    
    private var quizDetailsSheet: some View {
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
                scoringRuleRow("Easy Questions", "+1 star", "Basic payslip understanding", .green, "checkmark.circle.fill")
                scoringRuleRow("Medium Questions", "+2 stars", "Intermediate calculations", .orange, "star.leadinghalf.filled")
                scoringRuleRow("Hard Questions", "+3 stars", "Advanced financial concepts", .red, "star.circle.fill")
                scoringRuleRow("Wrong Answers", "-1 star", "Don't worry, keep learning!", .red, "minus.circle.fill")
            }
        }
    }
    
    private var progressDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                progressInfoRow("Total Stars", "\(gamificationCoordinator.currentStarCount)")
                progressInfoRow("Current Level", "\(gamificationCoordinator.currentLevel)")
                progressInfoRow("Questions Answered", "\(gamificationCoordinator.totalQuestionsAnswered)")
                if gamificationCoordinator.totalQuestionsAnswered > 0 {
                    progressInfoRow("Accuracy", "\(Int(gamificationCoordinator.currentAccuracy))%")
                    progressInfoRow("Current Streak", "\(gamificationCoordinator.currentStreak)")
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
                    bulletPoint("Income calculations and breakdowns")
                    bulletPoint("Deduction analysis and explanations")
                    bulletPoint("Tax calculations and withholdings")
                    bulletPoint("Financial insights and trends")
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
    
    // MARK: - Helper Views
    
    private func scoringRuleRow(_ title: String, _ points: String, _ description: String, _ color: Color, _ iconName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(points)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    private func progressInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(FintechColors.primaryBlue)
                .fontWeight(.bold)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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

import SwiftUI

/// Quiz section component for the Home screen
/// Displays personalized payslip knowledge quiz with gamification elements
@MainActor
struct HomeQuizSection: View {
    let payslips: [AnyPayslip]
    @State private var showQuizSheet = false
    @State private var showScoringInfo = false
    @StateObject private var quizViewModel = DIContainer.shared.makeQuizViewModel()
    @ObservedObject private var gamificationCoordinator = GamificationCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with stars and info button
            headerSection
            
            // Context description
            contextSection
            
            // Scoring rules preview (expandable)
            scoringRulesSection
            
            // Action buttons
            actionButtonsSection
        }
        .padding()
        .background(FintechColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showQuizSheet) {
            QuizView(viewModel: quizViewModel)
        }
        .sheet(isPresented: $showScoringInfo) {
            scoringInfoSheet
        }
        .onAppear {
            // Refresh the gamification coordinator to ensure latest data
            gamificationCoordinator.refreshData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payslip Quiz")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                
                if gamificationCoordinator.totalQuestionsAnswered > 0 {
                    Text("Level \(gamificationCoordinator.currentLevel) • \(Int(gamificationCoordinator.currentAccuracy))% accuracy")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // Star count with animation
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.caption)
                    Text("\(gamificationCoordinator.currentStarCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FintechColors.premiumGold.opacity(0.15))
                )
                
                // Info button for scoring rules
                Button(action: {
                    showScoringInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
            }
        }
    }
    
    // MARK: - Context Section
    
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test your payslip knowledge and earn stars!")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
            
            if !payslips.isEmpty {
                Text("Questions will be based on your recent payslip data to help you understand your earnings better.")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .opacity(0.8)
            } else {
                Text("Upload a payslip first to get personalized questions about your financial data.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Scoring Rules Preview
    
    private var scoringRulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showScoringInfo = true
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.caption)
                    
                    Text("How Scoring Works")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.primaryBlue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(FintechColors.primaryBlue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick scoring preview
            HStack(spacing: 16) {
                scoringPreviewItem("Easy", "+1", .green)
                scoringPreviewItem("Medium", "+2", .orange)
                scoringPreviewItem("Hard", "+3", .red)
                scoringPreviewItem("Wrong", "-1", .red)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func scoringPreviewItem(_ difficulty: String, _ points: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(points)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(difficulty)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Main quiz button
            Button(action: {
                Task {
                    await startQuiz()
                }
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
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
                .padding()
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
            
            // Quick options
            HStack(spacing: 12) {
                Button("Quick (3)") {
                    Task {
                        await startQuiz(questionCount: 3)
                    }
                }
                .buttonStyle(.bordered)
                .tint(FintechColors.primaryBlue)
                .controlSize(.small)
                .disabled(payslips.isEmpty)
                
                Button("Challenge (10)") {
                    Task {
                        await startQuiz(questionCount: 10, difficulty: .hard)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .controlSize(.small)
                .disabled(payslips.isEmpty)
                
                Spacer()
                
                if gamificationCoordinator.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(gamificationCoordinator.currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Scoring Info Sheet
    
    private var scoringInfoSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(FintechColors.premiumGold)
                            .font(.title2)
                        
                        Text("Quiz Scoring System")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Earn stars by answering questions correctly. Higher difficulty questions give more stars!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Detailed scoring rules
                VStack(alignment: .leading, spacing: 16) {
                    scoringRuleCard("Easy Questions", "+1 star", "Basic payslip understanding", .green, "checkmark.circle.fill")
                    scoringRuleCard("Medium Questions", "+2 stars", "Intermediate calculations", .orange, "star.leadinghalf.filled")
                    scoringRuleCard("Hard Questions", "+3 stars", "Advanced financial concepts", .red, "star.circle.fill")
                    scoringRuleCard("Wrong Answers", "-1 star", "Don't worry, keep learning!", .red, "minus.circle.fill")
                }
                
                // Progress information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        progressInfoRow("Total Stars", "\(gamificationCoordinator.currentStarCount)")
                        progressInfoRow("Current Level", "\(gamificationCoordinator.currentLevel)")
                        progressInfoRow("Accuracy", "\(Int(gamificationCoordinator.currentAccuracy))%")
                        progressInfoRow("Current Streak", "\(gamificationCoordinator.currentStreak)")
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scoring Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showScoringInfo = false
                    }
                }
            }
        }
    }
    
    private func scoringRuleCard(_ title: String, _ points: String, _ description: String, _ color: Color, _ iconName: String) -> some View {
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
    
    // MARK: - Helper Functions
    
    private func startQuiz(questionCount: Int = 5, difficulty: QuizDifficulty? = nil) async {
        await quizViewModel.startQuiz(
            questionCount: questionCount,
            difficulty: difficulty
        )
        showQuizSheet = true
    }
    
    // Note: refreshQuizViewModel() removed - now using GamificationCoordinator.shared.refreshData()
}

#Preview {
    HomeQuizSection(payslips: [])
        .padding()
} 
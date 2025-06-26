import SwiftUI

/// Quiz view for financial literacy and payslip knowledge testing
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswer: String? = nil
    @State private var showExplanation = false
    @State private var isAnswerSubmitted = false
    @State private var showConfetti = false
    @State private var starAnimation = false
    @State private var previousStarCount = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button and progress
            headerSection
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else if viewModel.showResults {
                        resultsView
                    } else if let question = viewModel.currentQuestion {
                        questionView(question)
                    } else {
                        startQuizView
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .background(FintechColors.appBackground)
        .onAppear {
            previousStarCount = viewModel.userProgress.totalPoints
        }
        .onChange(of: viewModel.userProgress.totalPoints) { oldValue, newValue in
            if newValue != previousStarCount {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    starAnimation.toggle()
                }
                previousStarCount = newValue
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Financial Quiz")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(FintechColors.primaryBlue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Progress indicator
            if viewModel.hasActiveSession || viewModel.showResults {
                VStack(spacing: 8) {
                    HStack {
                        Text("Question \(viewModel.currentQuestionNumber) of \(viewModel.totalQuestions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(FintechColors.premiumGold)
                                .font(.caption)
                                .scaleEffect(starAnimation ? 1.3 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: starAnimation)
                            
                            Text("\(viewModel.userProgress.totalPoints)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(starAnimation ? FintechColors.premiumGold : FintechColors.textPrimary)
                                .scaleEffect(starAnimation ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: starAnimation)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FintechColors.premiumGold.opacity(starAnimation ? 0.2 : 0.0))
                                .animation(.easeInOut(duration: 0.3), value: starAnimation)
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    
                    ProgressView(value: viewModel.quizProgress)
                        .tint(FintechColors.primaryBlue)
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .background(.regularMaterial)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(FintechColors.primaryBlue)
            
            Text("Generating personalized questions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                Task {
                    await viewModel.startQuiz()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(FintechColors.primaryBlue)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    // MARK: - Start Quiz View
    
    private var startQuizView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(FintechColors.primaryBlue)
            
            VStack(spacing: 12) {
                Text("Ready to Test Your Knowledge?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Answer questions about your payslip data and earn points!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Scoring Rules Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                    Text("How Scoring Works")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Easy questions: +1 star")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Medium questions: +2 stars")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Hard questions: +3 stars")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Wrong answers: -1 star")
                            .font(.subheadline)
                    }
                }
                
                Text("Higher star count indicates better financial literacy about your payslips. Challenge yourself!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FintechColors.premiumGold.opacity(0.3), lineWidth: 1)
                    )
            )
            
            VStack(spacing: 12) {
                Button("Start Quiz") {
                    Task {
                        await viewModel.startQuiz(questionCount: 5)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(FintechColors.primaryBlue)
                .controlSize(.large)
                
                Button("Quick Quiz (3 Questions)") {
                    Task {
                        await viewModel.startQuiz(questionCount: 3)
                    }
                }
                .buttonStyle(.bordered)
                .tint(FintechColors.primaryBlue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    // MARK: - Question View
    
    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: 24) {
            // Question card
            VStack(alignment: .leading, spacing: 16) {
                // Difficulty badge
                HStack {
                    Label(question.difficulty.displayName, systemImage: question.difficulty.iconName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(question.difficulty.color.opacity(0.2))
                        .foregroundColor(question.difficulty.color)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("+\(question.pointsValue) pts")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.premiumGold)
                }
                
                Text(question.questionText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    answerOptionButton(option: option, correctAnswer: question.correctAnswer)
                }
            }
            
            // Show explanation after answer is submitted
            if showExplanation && isAnswerSubmitted {
                explanationView(question.explanation, correct: selectedAnswer == question.correctAnswer)
            }
            
            // Next button or completion
            if isAnswerSubmitted {
                VStack(spacing: 12) {
                    if viewModel.currentQuestionNumber < viewModel.totalQuestions {
                        Button("Next Question") {
                            nextQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(FintechColors.primaryBlue)
                        .controlSize(.large)
                    } else {
                        Button("Finish Quiz") {
                            viewModel.showResults = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(FintechColors.successGreen)
                        .controlSize(.large)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAnswerSubmitted)
        .animation(.easeInOut(duration: 0.3), value: showExplanation)
        .onAppear {
            // Check if this question already has an answer
            if let session = viewModel.currentSession,
               let existingAnswer = session.currentQuestionAnswer {
                selectedAnswer = existingAnswer
                isAnswerSubmitted = true
                showExplanation = true
            } else {
                // Reset state for a new question
                selectedAnswer = nil
                isAnswerSubmitted = false
                showExplanation = false
            }
        }
    }
    
    // MARK: - Answer Option Button
    
    private func answerOptionButton(option: String, correctAnswer: String) -> some View {
        Button(action: {
            guard !isAnswerSubmitted else { return }
            selectedAnswer = option
            submitAnswer(option)
        }) {
            HStack {
                Text(option)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Show checkmark/X after submission
                if isAnswerSubmitted {
                    if option == correctAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if option == selectedAnswer {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor(option: option, correctAnswer: correctAnswer))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonBorderColor(option: option, correctAnswer: correctAnswer), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAnswerSubmitted)
    }
    
    private func buttonBackgroundColor(option: String, correctAnswer: String) -> Color {
        if !isAnswerSubmitted {
            return selectedAnswer == option ? FintechColors.primaryBlue.opacity(0.1) : Color(UIColor.secondarySystemBackground)
        }
        
        if option == correctAnswer {
            return Color.green.opacity(0.2)
        } else if option == selectedAnswer {
            return Color.red.opacity(0.2)
        } else {
            return Color(UIColor.secondarySystemBackground)
        }
    }
    
    private func buttonBorderColor(option: String, correctAnswer: String) -> Color {
        if !isAnswerSubmitted {
            return selectedAnswer == option ? FintechColors.primaryBlue : Color.clear
        }
        
        if option == correctAnswer {
            return Color.green
        } else if option == selectedAnswer {
            return Color.red
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Explanation View
    
    private func explanationView(_ explanation: String, correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(correct ? .green : .red)
                
                Text(correct ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(correct ? .green : .red)
                
                Spacer()
                
                // Star feedback
                if let question = viewModel.currentQuestion {
                    HStack(spacing: 4) {
                        Image(systemName: correct ? "plus.circle.fill" : "minus.circle.fill")
                            .foregroundColor(correct ? .green : .red)
                            .font(.caption)
                        
                        Text(correct ? "+\(question.pointsValue)" : "-1")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(correct ? .green : .red)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(FintechColors.premiumGold)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((correct ? Color.green : Color.red).opacity(0.1))
                    )
                }
            }
            
            Text(explanation)
                .font(.body)
                .foregroundColor(.secondary)
                
            if !correct {
                Text("Don't worry! Keep practicing to improve your financial literacy.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((correct ? Color.green : Color.red).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((correct ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
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
            if let results = viewModel.lastResults {
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
                    if !viewModel.recentAchievements.isEmpty {
                        achievementCelebrationView
                    }
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Take Another Quiz") {
                    Task {
                        await viewModel.startQuiz(questionCount: 5)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(FintechColors.primaryBlue)
                .controlSize(.large)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(FintechColors.primaryBlue)
            }
        }
        .padding()
    }
    
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
            
            ForEach(viewModel.recentAchievements.prefix(3), id: \.id) { achievement in
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
    
    // MARK: - Helper Functions
    
    private func submitAnswer(_ answer: String) {
        guard !isAnswerSubmitted else { return }
        
        viewModel.submitAnswer(answer)
        isAnswerSubmitted = true
        
        // Show explanation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showExplanation = true
        }
    }
    
    private func nextQuestion() {
        // Advance to the next question in the quiz session
        viewModel.advanceToNextQuestion()
        
        // Clear current question UI state
        selectedAnswer = nil
        showExplanation = false
        isAnswerSubmitted = false
    }
}

// MARK: - Preview
#if DEBUG
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuizView(viewModel: QuizViewModel(
                quizGenerationService: DIContainer.shared.makeQuizGenerationService(),
                achievementService: DIContainer.shared.makeAchievementService()
            ))
        }
    }
}
#endif
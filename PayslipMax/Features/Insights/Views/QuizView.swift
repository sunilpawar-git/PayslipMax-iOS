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
            QuizProgressIndicator(
                currentQuestionNumber: viewModel.currentQuestionNumber,
                totalQuestions: viewModel.totalQuestions,
                quizProgress: viewModel.quizProgress,
                totalPoints: viewModel.userProgress.totalPoints,
                starAnimation: starAnimation,
                hasActiveSession: viewModel.hasActiveSession,
                showResults: viewModel.showResults,
                onClose: { dismiss() }
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else if viewModel.showResults {
                        QuizResultsPanel(
                            results: viewModel.lastResults,
                            recentAchievements: viewModel.recentAchievements,
                            onClose: { dismiss() }
                        )
                    } else if let question = viewModel.currentQuestion {
                        QuizQuestionCard(
                            question: question,
                            selectedAnswer: $selectedAnswer,
                            isAnswerSubmitted: $isAnswerSubmitted,
                            showExplanation: $showExplanation,
                            onSubmitAnswer: submitAnswer
                        )
                        
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
                    } else {
                        QuizStartView { questionCount in
                            Task {
                                await viewModel.startQuiz(questionCount: questionCount)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .background(FintechColors.appBackground)
        .onAppear {
            previousStarCount = viewModel.userProgress.totalPoints
            
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
        .onChange(of: viewModel.userProgress.totalPoints) { oldValue, newValue in
            if newValue != previousStarCount {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    starAnimation.toggle()
                }
                previousStarCount = newValue
            }
        }
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
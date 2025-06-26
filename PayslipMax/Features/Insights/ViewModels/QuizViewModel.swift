import Foundation
import SwiftUI
import Combine

/// ViewModel that manages quiz sessions and coordinates with the gamification system
@MainActor
class QuizViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentSession: QuizSession?
    @Published var showResults = false
    @Published var showQuizSheet = false
    @Published var lastResults: QuizResults?
    @Published var showAchievementCelebration = false
    
    // MARK: - Dependencies
    
    private let quizGenerationService: QuizGenerationService
    private let achievementService: AchievementService
    private let gamificationCoordinator = GamificationCoordinator.shared
    
    // MARK: - Initialization
    
    init(
        quizGenerationService: QuizGenerationService,
        achievementService: AchievementService
    ) {
        self.quizGenerationService = quizGenerationService
        self.achievementService = achievementService
    }
    
    // MARK: - Quiz Management
    
    /// Starts a new quiz with specified parameters
    func startQuiz(
        questionCount: Int = 5,
        difficulty: QuizDifficulty? = nil,
        focusArea: InsightType? = nil
    ) async {
        isLoading = true
        error = nil
        
        let questions = await quizGenerationService.generateQuiz(
            questionCount: questionCount,
            difficulty: difficulty
        )
        
        if questions.isEmpty {
            error = "Unable to generate quiz questions. Please ensure you have payslip data available."
            isLoading = false
            return
        }
        
        currentSession = QuizSession(questions: questions)
        isLoading = false
    }
    
    /// Submits an answer for the current question
    func submitAnswer(_ answer: String) {
        guard var session = currentSession else { return }
        
        let currentQuestion = session.currentQuestion
        session.submitAnswer(answer)
        
        // Record the answer for achievements using the shared coordinator
        if let question = currentQuestion {
            let isCorrect = question.correctAnswer == answer
            gamificationCoordinator.recordQuizAnswer(
                correct: isCorrect,
                points: isCorrect ? question.pointsValue : 0,
                category: question.relatedInsightType.rawValue,
                question: question
            )
        }
        
        currentSession = session
    }
    
    /// Advances to the next question in the quiz
    func advanceToNextQuestion() {
        guard var session = currentSession else { return }
        
        session.advanceToNextQuestion()
        currentSession = session
        
        // Check if quiz is complete after advancing
        if session.isComplete {
            completeQuiz()
        }
    }
    
    /// Completes the current quiz and shows results
    private func completeQuiz() {
        guard let session = currentSession else { return }
        
        lastResults = session.getResults()
        showResults = true
        
        // Check for achievement celebrations
        if !gamificationCoordinator.recentAchievements.isEmpty {
            showAchievementCelebration = true
        }
    }
    
    /// Restarts the quiz with the same parameters
    func restartQuiz() async {
        guard let session = currentSession else { return }
        
        showResults = false
        showQuizSheet = false
        showAchievementCelebration = false
        lastResults = nil
        currentSession = nil
        
        // Create new quiz with same question count
        await startQuiz(questionCount: session.questions.count)
        showQuizSheet = true
    }
    
    /// Dismisses the quiz sheet
    func dismissQuizSheet() {
        showQuizSheet = false
    }
    
    /// Presents the quiz sheet
    func presentQuizSheet() {
        showQuizSheet = true
    }
    
    /// Ends the current quiz session
    func endQuiz() {
        currentSession = nil
        showResults = false
        showQuizSheet = false
        showAchievementCelebration = false
        lastResults = nil
        error = nil
    }
    
    // MARK: - Computed Properties
    
    /// Current question being displayed
    var currentQuestion: QuizQuestion? {
        return currentSession?.currentQuestion
    }
    
    /// Progress through the current quiz (0.0 to 1.0)
    var quizProgress: Double {
        return currentSession?.progress ?? 0.0
    }
    
    /// Current question number (1-indexed)
    var currentQuestionNumber: Int {
        guard let session = currentSession else { return 0 }
        return session.currentQuestionIndex + 1
    }
    
    /// Total number of questions in current quiz
    var totalQuestions: Int {
        return currentSession?.questions.count ?? 0
    }
    
    /// Whether there is an active quiz session
    var hasActiveSession: Bool {
        return currentSession != nil && !showResults
    }
    
    /// Gets the user's current gamification progress
    var userProgress: UserGamificationProgress {
        return gamificationCoordinator.userProgress
    }
    
    /// Gets recently unlocked achievements
    var recentAchievements: [Achievement] {
        return gamificationCoordinator.recentAchievements
    }
    
    // MARK: - Achievement Integration
    
    /// Gets unlocked achievements for display
    func getUnlockedAchievements() -> [Achievement] {
        return gamificationCoordinator.getUnlockedAchievements()
    }
    
    /// Gets locked achievements with progress
    func getLockedAchievements() -> [Achievement] {
        return gamificationCoordinator.getLockedAchievements()
    }
    
    /// Gets progress for a specific achievement
    func getAchievementProgress(_ achievement: Achievement) -> Double {
        return gamificationCoordinator.getAchievementProgress(achievement)
    }
    
    /// Dismisses the achievement celebration
    func dismissAchievementCelebration() {
        showAchievementCelebration = false
    }
    
    // MARK: - Quiz Options
    
    /// Available difficulty options
    var availableDifficulties: [QuizDifficulty] {
        return QuizDifficulty.allCases
    }
    
    /// Available focus areas
    var availableFocusAreas: [InsightType] {
        return InsightType.allCases
    }
    
    /// Recommended question counts
    var recommendedQuestionCounts: [Int] {
        return [3, 5, 10, 15]
    }
    
    // MARK: - Analytics Support
    
    /// Gets analytics data for the completed quiz
    func getQuizAnalytics() -> [String: Any]? {
        guard let results = lastResults else { return nil }
        
        return [
            "total_questions": results.totalQuestions,
            "correct_answers": results.correctAnswers,
            "accuracy_percentage": results.accuracyPercentage,
            "total_score": results.totalScore,
            "time_taken_seconds": results.timeTaken,
            "performance_grade": results.performanceGrade,
            "is_perfect_score": results.isPerfectScore
        ]
    }
    
    /// Gets user's overall quiz performance stats
    func getOverallStats() -> [String: Any] {
        let progress = userProgress
        
        return [
            "total_questions_answered": progress.totalQuestionsAnswered,
            "total_correct_answers": progress.totalCorrectAnswers,
            "overall_accuracy": progress.accuracyPercentage,
            "current_streak": progress.currentStreak,
            "longest_streak": progress.longestStreak,
            "total_points": progress.totalPoints,
            "current_level": progress.level,
            "achievements_unlocked": progress.unlockedAchievements.count
        ]
    }
    
    // MARK: - Data Management
    
    /// Updates the payslip data for quiz generation
    func updatePayslipData(_ payslips: [PayslipItem]) async {
        // Update the quiz generation service with new payslip data
        await quizGenerationService.updatePayslipData(payslips)
    }
} 
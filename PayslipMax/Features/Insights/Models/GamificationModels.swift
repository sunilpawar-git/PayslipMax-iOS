import Foundation
import SwiftUI

// MARK: - Quiz Data Models

/// Represents a quiz question about the user's payslip data
struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let questionText: String
    let questionType: QuizQuestionType
    let options: [String] // For multiple choice
    let correctAnswer: String
    let explanation: String
    let difficulty: QuizDifficulty
    let relatedInsightType: InsightType
    let contextData: QuizContextData
    
    // Custom initializer to handle UUID generation
    init(
        id: UUID = UUID(),
        questionText: String,
        questionType: QuizQuestionType,
        options: [String],
        correctAnswer: String,
        explanation: String,
        difficulty: QuizDifficulty,
        relatedInsightType: InsightType,
        contextData: QuizContextData
    ) {
        self.id = id
        self.questionText = questionText
        self.questionType = questionType
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.difficulty = difficulty
        self.relatedInsightType = relatedInsightType
        self.contextData = contextData
    }
    
    /// Points awarded for correct answer
    var pointsValue: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

/// Types of quiz questions available
enum QuizQuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
    case numerical = "numerical"
    case comparison = "comparison"
    
    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse: return "True/False"
        case .numerical: return "Number Match"
        case .comparison: return "Compare Values"
        }
    }
}

/// Difficulty levels for quiz questions
enum QuizDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .easy: return "star.fill"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.circle.fill"
        }
    }
}

/// Context data used to generate personalized questions
struct QuizContextData: Codable {
    let userIncome: Double?
    let userTaxRate: Double?
    let userDSOPContribution: Double?
    let averageIncome: Double?
    let comparisonPeriod: String?
    let specificMonth: String?
    let calculationDetails: [String: Double]?
}

// MARK: - Achievement System

/// Represents an achievement the user can earn
struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let pointsReward: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    // Custom initializer to handle UUID generation
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        category: AchievementCategory,
        requirement: AchievementRequirement,
        pointsReward: Int,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.pointsReward = pointsReward
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
    
    var badgeColor: Color {
        switch category {
        case .quiz: return FintechColors.primaryBlue
        case .streak: return FintechColors.successGreen
        case .mastery: return FintechColors.premiumGold
        case .exploration: return FintechColors.secondaryBlue
        }
    }
}

/// Categories of achievements
enum AchievementCategory: String, Codable, CaseIterable {
    case quiz = "quiz"
    case streak = "streak"
    case mastery = "mastery"
    case exploration = "exploration"
    
    var displayName: String {
        switch self {
        case .quiz: return "Quiz Master"
        case .streak: return "Consistency"
        case .mastery: return "Subject Expert"
        case .exploration: return "Explorer"
        }
    }
}

/// Requirements for unlocking achievements
struct AchievementRequirement: Codable {
    let type: RequirementType
    let threshold: Int
    let category: String?
    
    enum RequirementType: String, Codable {
        case questionsAnswered = "questions_answered"
        case correctStreak = "correct_streak"
        case perfectQuiz = "perfect_quiz"
        case categoryMastery = "category_mastery"
        case totalPoints = "total_points"
    }
}

// MARK: - User Progress Tracking

/// Tracks user's gamification progress
struct UserGamificationProgress: Codable {
    var totalPoints: Int = 0
    var totalQuestionsAnswered: Int = 0
    var totalCorrectAnswers: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastQuizDate: Date?
    var unlockedAchievements: [UUID] = []
    var categoryStats: [String: CategoryStats] = [:]
    var level: Int {
        // Level calculation: every 100 points = 1 level
        return max(1, totalPoints / 100)
    }
    var accuracyPercentage: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return (Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)) * 100
    }
    
    mutating func recordAnswer(correct: Bool, points: Int, category: String) {
        totalQuestionsAnswered += 1
        lastQuizDate = Date()
        
        if correct {
            totalCorrectAnswers += 1
            totalPoints += points
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Apply penalty for wrong answer, but never go below 0 stars
            totalPoints = max(0, totalPoints - 1)
            currentStreak = 0
        }
        
        // Update category stats
        if categoryStats[category] == nil {
            categoryStats[category] = CategoryStats()
        }
        categoryStats[category]?.recordAnswer(correct: correct)
    }
}

/// Statistics for specific insight categories
struct CategoryStats: Codable {
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var masteryLevel: MasteryLevel = .beginner
    
    var accuracyPercentage: Double {
        guard questionsAnswered > 0 else { return 0 }
        return (Double(correctAnswers) / Double(questionsAnswered)) * 100
    }
    
    mutating func recordAnswer(correct: Bool) {
        questionsAnswered += 1
        if correct {
            correctAnswers += 1
        }
        updateMasteryLevel()
    }
    
    private mutating func updateMasteryLevel() {
        if questionsAnswered >= 20 && accuracyPercentage >= 90 {
            masteryLevel = .expert
        } else if questionsAnswered >= 10 && accuracyPercentage >= 75 {
            masteryLevel = .intermediate
        } else if questionsAnswered >= 5 && accuracyPercentage >= 60 {
            masteryLevel = .novice
        }
    }
}

/// User's mastery level in different categories
enum MasteryLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case novice = "novice"
    case intermediate = "intermediate"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .novice: return .blue
        case .intermediate: return .orange
        case .expert: return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "person.fill"
        case .novice: return "person.badge.plus"
        case .intermediate: return "person.2.fill"
        case .expert: return "crown.fill"
        }
    }
}

// MARK: - Quiz Session Management

/// Represents an active quiz session
struct QuizSession: Identifiable {
    let id: UUID
    let questions: [QuizQuestion]
    var currentQuestionIndex: Int = 0
    var userAnswers: [String] = []
    var startTime: Date = Date()
    var endTime: Date?
    var score: Int = 0
    
    // Custom initializer
    init(
        id: UUID = UUID(),
        questions: [QuizQuestion],
        currentQuestionIndex: Int = 0,
        userAnswers: [String] = [],
        startTime: Date = Date(),
        endTime: Date? = nil,
        score: Int = 0
    ) {
        self.id = id
        self.questions = questions
        self.currentQuestionIndex = currentQuestionIndex
        self.userAnswers = userAnswers
        self.startTime = startTime
        self.endTime = endTime
        self.score = score
    }
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var isComplete: Bool {
        return currentQuestionIndex >= questions.count
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var totalPossiblePoints: Int {
        return questions.reduce(0) { $0 + $1.pointsValue }
    }
    
    /// Records the user's answer for the current question
    mutating func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < questions.count else { return }
        
        // Ensure we have the right number of answers
        while userAnswers.count <= currentQuestionIndex {
            userAnswers.append("")
        }
        
        // Record the answer
        userAnswers[currentQuestionIndex] = answer
        
        // Add points if correct
        if let currentQ = currentQuestion, currentQ.correctAnswer == answer {
            score += currentQ.pointsValue
        }
    }
    
    /// Advances to the next question
    mutating func advanceToNextQuestion() {
        guard currentQuestionIndex < questions.count else { return }
        
        currentQuestionIndex += 1
        
        if isComplete {
            endTime = Date()
        }
    }
    
    /// Gets the user's answer for a specific question index
    func getUserAnswer(for questionIndex: Int) -> String? {
        guard questionIndex < userAnswers.count else { return nil }
        return userAnswers[questionIndex].isEmpty ? nil : userAnswers[questionIndex]
    }
    
    /// Gets the user's answer for the current question
    var currentQuestionAnswer: String? {
        return getUserAnswer(for: currentQuestionIndex)
    }
    
    func getResults() -> QuizResults {
        let correctAnswers = questions.enumerated().reduce(0) { count, pair in
            let (index, question) = pair
            let userAnswer = getUserAnswer(for: index)
            return count + (question.correctAnswer == userAnswer ? 1 : 0)
        }
        
        return QuizResults(
            totalQuestions: questions.count,
            correctAnswers: correctAnswers,
            totalScore: score,
            totalPossibleScore: totalPossiblePoints,
            timeTaken: endTime?.timeIntervalSince(startTime) ?? 0,
            achievementsUnlocked: []
        )
    }
}

/// Results of a completed quiz session
struct QuizResults {
    let totalQuestions: Int
    let correctAnswers: Int
    let totalScore: Int
    let totalPossibleScore: Int
    let timeTaken: TimeInterval
    let achievementsUnlocked: [Achievement]
    
    var accuracyPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return (Double(correctAnswers) / Double(totalQuestions)) * 100
    }
    
    var performanceGrade: String {
        switch accuracyPercentage {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    var isPerfectScore: Bool {
        return correctAnswers == totalQuestions
    }
} 
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

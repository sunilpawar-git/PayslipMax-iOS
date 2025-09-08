import Foundation
import SwiftUI

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

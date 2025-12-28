import Foundation
@testable import PayslipMax

/// Shared helpers for Quiz tests
enum QuizTestHelpers {
    static func createMockQuestions(count: Int, prefix: String = "Test") -> [QuizQuestion] {
        return (0..<count).map { index in
            QuizQuestion(
                id: UUID(),
                questionText: "\(prefix) question \(index)",
                questionType: .multipleChoice,
                options: ["A", "B", "C", "D"],
                correctAnswer: "A",
                explanation: "Test explanation",
                difficulty: .medium,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: 100000,
                    userTaxRate: 0.2,
                    userDSOPContribution: 5000,
                    averageIncome: 90000,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            )
        }
    }
}

// MARK: - Mock Classes

@MainActor
final class MockQuizDataLoader: QuizDataLoaderProtocol {
    var loadPayslipDataCalled = false
    var shouldThrowError = false

    func loadPayslipData() async throws {
        loadPayslipDataCalled = true
        if shouldThrowError {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
    }
}

@MainActor
final class MockPayslipQuestionGenerator: QuizPayslipQuestionGeneratorProtocol {
    var generateCalled = false
    var lastDifficulty: QuizDifficulty?
    var questionsToReturn: [QuizQuestion] = []

    func generatePayslipSpecificQuestions(
        maxCount: Int,
        difficulty: QuizDifficulty?
    ) async -> [QuizQuestion] {
        generateCalled = true
        lastDifficulty = difficulty
        return Array(questionsToReturn.prefix(maxCount))
    }
}

@MainActor
final class MockQuestionGenerator: QuizQuestionGeneratorProtocol {
    var generateCalled = false
    var questionsToReturn: [QuizQuestion] = []

    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        generateCalled = true
        return Array(questionsToReturn.prefix(maxCount))
    }
}

final class MockFallbackGenerator: QuizFallbackGeneratorProtocol {
    var generateCalled = false
    var questionsToReturn: [QuizQuestion] = []

    func generateFallbackQuestions(count: Int) -> [QuizQuestion] {
        generateCalled = true
        return Array(questionsToReturn.prefix(count))
    }
}

final class MockQuizUtility: QuizUtilityProtocol {
    func formatCurrencyForOptions(_ amount: Double) -> String {
        return "₹\(amount)"
    }

    func generateWrongCurrencyOptions(correct: Double) -> [String] {
        return ["₹\(correct * 0.8)", "₹\(correct * 1.2)", "₹\(correct * 0.5)"]
    }

    func shouldIncludeDifficulty(
        _ requested: QuizDifficulty?,
        _ questionDifficulty: QuizDifficulty
    ) -> Bool {
        guard let requested = requested else { return true }
        return requested == questionDifficulty
    }

    func chronologicalComparison(
        latest: (month: String, net: Double),
        previous: (month: String, net: Double)
    ) -> (String, String, Double, Double, Double) {
        let difference = latest.net - previous.net
        return (latest.month, previous.month, latest.net, previous.net, difference)
    }
}


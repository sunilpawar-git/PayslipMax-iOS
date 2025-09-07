//
//  QuizGenerationServiceProtocols.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation
import SwiftUI

/// Protocol defining the interface for quiz generation services
protocol QuizGenerationServiceProtocol {
    /// Generates a set of personalized quiz questions
    func generateQuiz(questionCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion]

    /// Updates the service with new payslip data for generating personalized questions
    func updatePayslipData(_ payslips: [any PayslipProtocol]) async
}

/// Protocol for question generation strategies
@MainActor
protocol QuizQuestionGeneratorProtocol {
    /// Generates questions based on the given parameters
    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion]
}

/// Protocol for payslip data loading operations
protocol QuizDataLoaderProtocol {
    /// Loads payslip data into the financial summary view model
    func loadPayslipData() async throws
}

/// Protocol for quiz utility operations
protocol QuizUtilityProtocol {
    /// Formats currency amount for quiz options
    func formatCurrencyForOptions(_ amount: Double) -> String

    /// Generates plausible wrong options for currency amounts
    func generateWrongCurrencyOptions(correct: Double) -> [String]

    /// Determines if a question difficulty should be included
    func shouldIncludeDifficulty(_ requested: QuizDifficulty?, _ questionDifficulty: QuizDifficulty) -> Bool

    /// Determines chronologically correct comparison order for date-based questions
    func chronologicalComparison(
        latest: (month: String, net: Double),
        previous: (month: String, net: Double)
    ) -> (String, String, Double, Double, Double)
}

/// Protocol for fallback question generation
protocol QuizFallbackGeneratorProtocol {
    /// Generates fallback questions when payslip data isn't available
    func generateFallbackQuestions(count: Int) -> [QuizQuestion]
}

/// Protocol for payslip-specific question generation
protocol QuizPayslipQuestionGeneratorProtocol {
    /// Generates payslip-specific questions with month references for clarity
    func generatePayslipSpecificQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion]
}

// Note: All quiz-related types (QuizQuestion, QuizDifficulty, QuizQuestionType,
// InsightType, QuizContextData) are defined in GamificationModels.swift

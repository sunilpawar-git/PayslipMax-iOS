//
//  QuizGenerationServiceCore.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Core implementation of the quiz generation service following protocol-based architecture
@MainActor
final class QuizGenerationServiceCore: QuizGenerationServiceProtocol {
    // MARK: - Dependencies

    private let dataLoader: QuizDataLoaderProtocol
    private let payslipQuestionGenerator: QuizPayslipQuestionGeneratorProtocol
    private let incomeQuestionGenerator: QuizQuestionGeneratorProtocol
    private let deductionQuestionGenerator: QuizQuestionGeneratorProtocol
    private let literacyQuestionGenerator: QuizQuestionGeneratorProtocol
    private let fallbackGenerator: QuizFallbackGeneratorProtocol
    private let utility: QuizUtilityProtocol

    // MARK: - Initialization

    /// Initializes the quiz generation service with all required dependencies
    /// - Parameters:
    ///   - dataLoader: Service for loading payslip data
    ///   - payslipQuestionGenerator: Generator for payslip-specific questions
    ///   - incomeQuestionGenerator: Generator for income-related questions
    ///   - deductionQuestionGenerator: Generator for deduction-related questions
    ///   - literacyQuestionGenerator: Generator for financial literacy questions
    ///   - fallbackGenerator: Generator for fallback questions
    ///   - utility: Utility functions for quiz generation
    init(
        dataLoader: QuizDataLoaderProtocol,
        payslipQuestionGenerator: QuizPayslipQuestionGeneratorProtocol,
        incomeQuestionGenerator: QuizQuestionGeneratorProtocol,
        deductionQuestionGenerator: QuizQuestionGeneratorProtocol,
        literacyQuestionGenerator: QuizQuestionGeneratorProtocol,
        fallbackGenerator: QuizFallbackGeneratorProtocol,
        utility: QuizUtilityProtocol
    ) {
        self.dataLoader = dataLoader
        self.payslipQuestionGenerator = payslipQuestionGenerator
        self.incomeQuestionGenerator = incomeQuestionGenerator
        self.deductionQuestionGenerator = deductionQuestionGenerator
        self.literacyQuestionGenerator = literacyQuestionGenerator
        self.fallbackGenerator = fallbackGenerator
        self.utility = utility
    }

    // MARK: - Public Interface

    /// Generates a set of personalized quiz questions
    /// - Parameters:
    ///   - questionCount: Number of questions to generate
    ///   - difficulty: Optional difficulty filter for questions
    /// - Returns: Array of quiz questions
    func generateQuiz(questionCount: Int = 5, difficulty: QuizDifficulty? = nil) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []

        do {
            // Load payslip data first
            try await dataLoader.loadPayslipData()

            // Generate payslip-specific questions for better user engagement
            let payslipSpecificQuestions = await payslipQuestionGenerator.generatePayslipSpecificQuestions(
                maxCount: 3,
                difficulty: difficulty
            )
            questions.append(contentsOf: payslipSpecificQuestions)

            print("QuizGenerationServiceCore: Generated \(payslipSpecificQuestions.count) payslip-specific questions")

            // Add other personalized questions
            let incomeQuestions = incomeQuestionGenerator.generateQuestions(maxCount: 3, difficulty: difficulty)
            let deductionQuestions = deductionQuestionGenerator.generateQuestions(maxCount: 3, difficulty: difficulty)
            let literacyQuestions = literacyQuestionGenerator.generateQuestions(maxCount: 2, difficulty: difficulty)

            questions.append(contentsOf: incomeQuestions)
            questions.append(contentsOf: deductionQuestions)
            questions.append(contentsOf: literacyQuestions)

            print("QuizGenerationServiceCore: Generated \(questions.count) personalized questions")

        } catch {
            print("QuizGenerationServiceCore: Error loading payslip data: \(error.localizedDescription)")
        }

        // Fill remaining slots with fallback questions
        let remaining = max(0, questionCount - questions.count)
        if remaining > 0 {
            let fallbackQuestions = fallbackGenerator.generateFallbackQuestions(count: remaining)
            questions.append(contentsOf: fallbackQuestions)
        }

        print("QuizGenerationServiceCore: Final question count: \(questions.count)")

        // Shuffle and return requested count
        return Array(questions.shuffled().prefix(questionCount))
    }

    /// Updates the service with new payslip data for generating personalized questions
    /// - Parameter payslips: New payslip data to update with
    func updatePayslipData(_ payslips: [any PayslipProtocol]) async {
        // This method updates the internal data sources when new payslip data is available
        // For now, this is handled through the ViewModels, but can be enhanced later
        // to cache payslip data locally within the service for better performance
        print("QuizGenerationServiceCore: Updating payslip data with \(payslips.count) payslips")
    }
}

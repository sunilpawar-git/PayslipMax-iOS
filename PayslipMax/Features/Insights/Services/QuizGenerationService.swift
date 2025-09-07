//
//  QuizGenerationService.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Service responsible for generating personalized quiz questions based on user's payslip data
/// This is the main composition root that orchestrates all quiz generation components
@MainActor
final class QuizGenerationService: QuizGenerationServiceProtocol {
    // MARK: - Dependencies

    private let coreService: QuizGenerationServiceCore

    // MARK: - Initialization

    /// Initializes the quiz generation service with required dependencies
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel for financial summary data
    ///   - trendAnalysisViewModel: ViewModel for trend analysis (reserved for future use)
    ///   - chartDataViewModel: ViewModel for chart data (reserved for future use)
    ///   - dataService: Data service for persistence operations
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        trendAnalysisViewModel: TrendAnalysisViewModel,
        chartDataViewModel: ChartDataViewModel,
        dataService: DataServiceProtocol
    ) {
        // Initialize utility functions
        let utility = QuizUtility()

        // Initialize data loader
        let dataLoader = QuizDataLoaderFactory.createDataLoader(
            financialSummaryViewModel: financialSummaryViewModel,
            dataService: dataService
        )

        // Initialize payslip-specific question generator
        let payslipQuestionGenerator = QuizPayslipQuestionGenerator(
            financialSummaryViewModel: financialSummaryViewModel,
            utility: utility
        )

        // Initialize legacy question generators for backward compatibility
        let incomeQuestionGenerator = IncomeQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)
        let deductionQuestionGenerator = DeductionQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)
        let financialLiteracyQuestionGenerator = FinancialLiteracyQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)

        // Initialize fallback question generator
        let fallbackGenerator = QuizFallbackGenerator()

        // Initialize core service with all components
        self.coreService = QuizGenerationServiceCore(
            dataLoader: dataLoader,
            payslipQuestionGenerator: payslipQuestionGenerator,
            incomeQuestionGenerator: incomeQuestionGenerator,
            deductionQuestionGenerator: deductionQuestionGenerator,
            literacyQuestionGenerator: financialLiteracyQuestionGenerator,
            fallbackGenerator: fallbackGenerator,
            utility: utility
        )
    }

    // MARK: - QuizGenerationServiceProtocol Implementation
    
    /// Generates a set of personalized quiz questions
    /// - Parameters:
    ///   - questionCount: Number of questions to generate
    ///   - difficulty: Optional difficulty filter
    /// - Returns: Array of quiz questions
    func generateQuiz(questionCount: Int = 5, difficulty: QuizDifficulty? = nil) async -> [QuizQuestion] {
        return await coreService.generateQuiz(questionCount: questionCount, difficulty: difficulty)
    }
    
    /// Updates the service with new payslip data for generating personalized questions
    /// - Parameter payslips: New payslip data to update with
    func updatePayslipData(_ payslips: [any PayslipProtocol]) async {
        await coreService.updatePayslipData(payslips)
    }
} 
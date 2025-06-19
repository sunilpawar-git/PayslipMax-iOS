import Foundation
import SwiftUI

/// Service responsible for generating personalized quiz questions based on user's payslip data
@MainActor
class QuizGenerationService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let trendAnalysisViewModel: TrendAnalysisViewModel
    private let chartDataViewModel: ChartDataViewModel
    
    // MARK: - Initialization
    
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        trendAnalysisViewModel: TrendAnalysisViewModel,
        chartDataViewModel: ChartDataViewModel
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.trendAnalysisViewModel = trendAnalysisViewModel
        self.chartDataViewModel = chartDataViewModel
    }
    
    // MARK: - Quiz Generation
    
    /// Generates a personalized quiz based on user's payslip data
    func generateQuiz(
        questionCount: Int = 5,
        difficulty: QuizDifficulty? = nil,
        focusArea: InsightType? = nil
    ) async -> [QuizQuestion] {
        
        var questions: [QuizQuestion] = []
        
        // Ensure we have payslip data to work with
        guard !financialSummaryViewModel.payslips.isEmpty else {
            return generateFallbackQuestions(count: questionCount)
        }
        
        // Generate questions based on different insight types
        let insightTypes: [InsightType] = focusArea != nil ? [focusArea!] : InsightType.allCases
        
        for insightType in insightTypes {
            let typeQuestions = generateQuestionsForInsightType(
                insightType,
                maxCount: questionCount / insightTypes.count + 1,
                difficulty: difficulty
            )
            questions.append(contentsOf: typeQuestions)
        }
        
        // Shuffle and limit to requested count
        return Array(questions.shuffled().prefix(questionCount))
    }
    
    // MARK: - Private Question Generation Methods
    
    /// Generates questions for a specific insight type
    private func generateQuestionsForInsightType(
        _ insightType: InsightType,
        maxCount: Int,
        difficulty: QuizDifficulty?
    ) -> [QuizQuestion] {
        
        switch insightType {
        case .income:
            return generateIncomeQuestions(maxCount: maxCount, difficulty: difficulty)
        case .deductions:
            return generateDeductionQuestions(maxCount: maxCount, difficulty: difficulty)
        case .net:
            return generateNetIncomeQuestions(maxCount: maxCount, difficulty: difficulty)
        }
    }
    
    /// Generates income-related questions
    private func generateIncomeQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let averageIncome = financialSummaryViewModel.calculateAverageIncome()
        
        // Question 1: Current month income (Easy)
        if shouldIncludeDifficulty(.easy, target: difficulty) && questions.count < maxCount {
            let question = QuizQuestion(
                questionText: "What was your total income in \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateIncomeOptions(correct: latestPayslip.credits),
                correctAnswer: formatCurrency(latestPayslip.credits),
                explanation: "Your total income for \(latestPayslip.month) \(latestPayslip.year) was \(formatCurrency(latestPayslip.credits)). This includes your basic salary and all allowances.",
                difficulty: .easy,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: latestPayslip.credits,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: averageIncome,
                    comparisonPeriod: nil,
                    specificMonth: "\(latestPayslip.month) \(latestPayslip.year)",
                    calculationDetails: nil
                )
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generates deduction-related questions
    private func generateDeductionQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: latestPayslip)
        
        // Question 1: Total deductions (Easy)
        if shouldIncludeDifficulty(.easy, target: difficulty) && questions.count < maxCount {
            let question = QuizQuestion(
                questionText: "What were your total deductions in \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateDeductionOptions(correct: totalDeductions),
                correctAnswer: formatCurrency(totalDeductions),
                explanation: "Your total deductions for \(latestPayslip.month) \(latestPayslip.year) were \(formatCurrency(totalDeductions)). This includes taxes, DSOP, and other deductions.",
                difficulty: .easy,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: latestPayslip.credits,
                    userTaxRate: (totalDeductions / latestPayslip.credits) * 100,
                    userDSOPContribution: latestPayslip.dsop,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: "\(latestPayslip.month) \(latestPayslip.year)",
                    calculationDetails: ["totalDeductions": totalDeductions]
                )
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generates net income related questions
    private func generateNetIncomeQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: latestPayslip)
        let netIncome = latestPayslip.credits - totalDeductions
        
        // Question 1: Net income calculation (Medium)
        if shouldIncludeDifficulty(.medium, target: difficulty) && questions.count < maxCount {
            let question = QuizQuestion(
                questionText: "What was your net income (after all deductions) in \(latestPayslip.month)?",
                questionType: .multipleChoice,
                options: generateIncomeOptions(correct: netIncome),
                correctAnswer: formatCurrency(netIncome),
                explanation: "Your net income was \(formatCurrency(netIncome)) (Income: \(formatCurrency(latestPayslip.credits)) - Deductions: \(formatCurrency(totalDeductions))).",
                difficulty: .medium,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: latestPayslip.credits,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: "\(latestPayslip.month) \(latestPayslip.year)",
                    calculationDetails: [
                        "grossIncome": latestPayslip.credits,
                        "totalDeductions": totalDeductions,
                        "netIncome": netIncome
                    ]
                )
            )
            questions.append(question)
        }
        
        return questions
    }
    
    // MARK: - Helper Methods
    
    /// Determines if a difficulty level should be included
    private func shouldIncludeDifficulty(_ difficulty: QuizDifficulty, target: QuizDifficulty?) -> Bool {
        guard let target = target else { return true }
        return difficulty == target
    }
    
    /// Generates multiple choice options for income values
    private func generateIncomeOptions(correct: Double) -> [String] {
        let correctFormatted = formatCurrency(correct)
        let variation1 = formatCurrency(correct * 0.85)
        let variation2 = formatCurrency(correct * 1.15)
        let variation3 = formatCurrency(correct * 0.70)
        
        return [correctFormatted, variation1, variation2, variation3].shuffled()
    }
    
    /// Generates multiple choice options for deduction values
    private func generateDeductionOptions(correct: Double) -> [String] {
        let correctFormatted = formatCurrency(correct)
        let variation1 = formatCurrency(correct * 0.80)
        let variation2 = formatCurrency(correct * 1.25)
        let variation3 = formatCurrency(correct * 0.65)
        
        return [correctFormatted, variation1, variation2, variation3].shuffled()
    }
    
    /// Formats currency values for display
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    /// Generates fallback questions when no payslip data is available
    private func generateFallbackQuestions(count: Int) -> [QuizQuestion] {
        return [
            QuizQuestion(
                questionText: "What does DSOP stand for in military payslips?",
                questionType: .multipleChoice,
                options: ["Deferred Savings and Pension", "Defense Service Pension", "Direct Service Pay", "Department Savings Plan"],
                correctAnswer: "Deferred Savings and Pension",
                explanation: "DSOP stands for Deferred Savings and Pension, which is a retirement savings scheme for military personnel.",
                difficulty: .easy,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            )
        ]
    }
} 
import Foundation
import SwiftUI

/// Service responsible for generating personalized quiz questions based on user's payslip data
@MainActor
class QuizGenerationService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let trendAnalysisViewModel: TrendAnalysisViewModel
    private let chartDataViewModel: ChartDataViewModel
    
    // MARK: - Properties
    
    /// Available quiz questions database
    private var questionBank: [QuizQuestion] = []
    
    /// Current payslip data for personalized questions
    private var payslips: [PayslipItem] = []
    
    // MARK: - Initialization
    
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        trendAnalysisViewModel: TrendAnalysisViewModel,
        chartDataViewModel: ChartDataViewModel
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.trendAnalysisViewModel = trendAnalysisViewModel
        self.chartDataViewModel = chartDataViewModel
        loadQuestionBank()
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
    
    /// Formats currency for display
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
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
    
    // MARK: - Data Management
    
    /// Updates the payslip data for generating personalized questions
    func updatePayslipData(_ payslips: [PayslipItem]) async {
        self.payslips = payslips
        // Regenerate personalized questions based on new data
        await generatePersonalizedQuestions()
    }
    
    // MARK: - Private Methods
    
    /// Loads the base question bank with template questions
    private func loadQuestionBank() {
        questionBank = [
            // Basic Income Questions
            QuizQuestion(
                questionText: "What was your gross income last month?",
                questionType: .multipleChoice,
                options: ["₹35,000", "₹40,000", "₹45,000", "₹50,000"],
                correctAnswer: "₹35,000",
                explanation: "Your gross income is the total amount before any deductions.",
                difficulty: .easy,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: nil,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            // Deduction Questions
            QuizQuestion(
                questionText: "What percentage of your salary goes to DSOP?",
                questionType: .multipleChoice,
                options: ["8%", "10%", "12%", "15%"],
                correctAnswer: "10%",
                explanation: "DSOP (Defence Services Officers Provident Fund) is typically 10% of your basic pay.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            // Net Income Questions
            QuizQuestion(
                questionText: "What is your net take-home pay?",
                questionType: .multipleChoice,
                options: ["₹30,000", "₹35,000", "₹40,000", "₹45,000"],
                correctAnswer: "₹40,000",
                explanation: "Net pay is your gross income minus all deductions and taxes.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: nil,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            )
        ]
    }
    
    /// Generates personalized questions based on current payslip data
    private func generatePersonalizedQuestions() async {
        guard !payslips.isEmpty else { return }
        
        // Clear existing personalized questions and rebuild
        questionBank.removeAll { question in
            if let specificMonth = question.contextData.specificMonth {
                return !specificMonth.isEmpty // Remove personalized questions that have specific month data
            }
            return false
        }
        
        // Generate questions based on actual payslip data
        if let latestPayslip = payslips.first {
            await generateIncomeQuestions(from: latestPayslip)
            await generateDeductionQuestions(from: latestPayslip)
            await generateNetIncomeQuestions(from: latestPayslip)
        }
        
        // Generate trend questions if we have multiple payslips
        if payslips.count >= 2 {
            await generateTrendQuestions()
        }
    }
    
    /// Generates income-related questions from payslip data
    private func generateIncomeQuestions(from payslip: PayslipItem) async {
        let actualIncome = payslip.credits
        let wrongOptions = [
            actualIncome - 5000,
            actualIncome + 3000,
            actualIncome + 8000
        ]
        
        let allOptions = [
            formatCurrency(actualIncome),
            formatCurrency(wrongOptions[0]),
            formatCurrency(wrongOptions[1]),
            formatCurrency(wrongOptions[2])
        ].shuffled()
        
        let question = QuizQuestion(
            questionText: "What was your gross income in \(payslip.month) \(payslip.year)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: formatCurrency(actualIncome),
            explanation: "This is your gross income from your \(payslip.month) \(payslip.year) payslip.",
            difficulty: .easy,
            relatedInsightType: .income,
            contextData: QuizContextData(
                userIncome: actualIncome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: "\(payslip.month) \(payslip.year)",
                calculationDetails: ["gross_income": actualIncome]
            )
        )
        
        questionBank.append(question)
    }
    
    /// Generates deduction-related questions from payslip data
    private func generateDeductionQuestions(from payslip: PayslipItem) async {
        let totalDeductions = payslip.debits + payslip.tax
        let deductionPercentage = (totalDeductions / payslip.credits) * 100
        
        let wrongPercentages = [
            deductionPercentage - 5,
            deductionPercentage + 3,
            deductionPercentage + 8
        ]
        
        let allOptions = [
            String(format: "%.1f%%", deductionPercentage),
            String(format: "%.1f%%", wrongPercentages[0]),
            String(format: "%.1f%%", wrongPercentages[1]),
            String(format: "%.1f%%", wrongPercentages[2])
        ].shuffled()
        
        let question = QuizQuestion(
            questionText: "What percentage of your gross income went to total deductions in \(payslip.month)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: String(format: "%.1f%%", deductionPercentage),
            explanation: "Total deductions include debits and taxes from your gross income.",
            difficulty: .medium,
            relatedInsightType: .deductions,
            contextData: QuizContextData(
                userIncome: payslip.credits,
                userTaxRate: (payslip.tax / payslip.credits) * 100,
                userDSOPContribution: payslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: "\(payslip.month) \(payslip.year)",
                calculationDetails: [
                    "total_deductions": totalDeductions,
                    "deduction_percentage": deductionPercentage
                ]
            )
        )
        
        questionBank.append(question)
    }
    
    /// Generates net income questions from payslip data
    private func generateNetIncomeQuestions(from payslip: PayslipItem) async {
        let netIncome = payslip.credits - payslip.debits - payslip.tax
        let wrongOptions = [
            netIncome - 3000,
            netIncome + 2000,
            netIncome + 5000
        ]
        
        let allOptions = [
            formatCurrency(netIncome),
            formatCurrency(wrongOptions[0]),
            formatCurrency(wrongOptions[1]),
            formatCurrency(wrongOptions[2])
        ].shuffled()
        
        let question = QuizQuestion(
            questionText: "What was your net take-home pay in \(payslip.month) \(payslip.year)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: formatCurrency(netIncome),
            explanation: "Net pay is calculated as gross income minus all deductions and taxes.",
            difficulty: .easy,
            relatedInsightType: .net,
            contextData: QuizContextData(
                userIncome: payslip.credits,
                userTaxRate: (payslip.tax / payslip.credits) * 100,
                userDSOPContribution: payslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: "\(payslip.month) \(payslip.year)",
                calculationDetails: [
                    "net_income": netIncome,
                    "gross_income": payslip.credits,
                    "total_deductions": payslip.debits + payslip.tax
                ]
            )
        )
        
        questionBank.append(question)
    }
    
    /// Generates trend analysis questions from multiple payslips
    private func generateTrendQuestions() async {
        let sortedPayslips = payslips.sorted { 
            createDate(from: $0) < createDate(from: $1)
        }
        
        guard sortedPayslips.count >= 2,
              let oldest = sortedPayslips.first,
              let newest = sortedPayslips.last else { return }
        
        let oldIncome = oldest.credits
        let newIncome = newest.credits
        let growthPercentage = ((newIncome - oldIncome) / oldIncome) * 100
        
        let trendDescription: String
        let correctOption: String
        
        if growthPercentage > 5 {
            trendDescription = "increased"
            correctOption = "Increased by \(String(format: "%.1f", growthPercentage))%"
        } else if growthPercentage < -5 {
            trendDescription = "decreased"
            correctOption = "Decreased by \(String(format: "%.1f", abs(growthPercentage)))%"
        } else {
            trendDescription = "remained stable"
            correctOption = "Remained roughly the same"
        }
        
        let allOptions = [
            correctOption,
            "Increased by 15%",
            "Decreased by 10%",
            "Increased by 25%"
        ].shuffled()
        
        let question = QuizQuestion(
            questionText: "How has your income changed from \(oldest.month) to \(newest.month)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctOption,
            explanation: "Based on your payslip data, your income has \(trendDescription) over this period.",
            difficulty: .hard,
            relatedInsightType: .income,
            contextData: QuizContextData(
                userIncome: newIncome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: (oldIncome + newIncome) / 2,
                comparisonPeriod: "\(oldest.month) to \(newest.month)",
                specificMonth: nil,
                calculationDetails: [
                    "old_income": oldIncome,
                    "new_income": newIncome,
                    "growth_percentage": growthPercentage
                ]
            )
        )
        
        questionBank.append(question)
    }
    
    /// Creates a Date from payslip month/year
    private func createDate(from payslip: PayslipItem) -> Date {
        let monthInt = monthToInt(payslip.month)
        var dateComponents = DateComponents()
        dateComponents.year = payslip.year
        dateComponents.month = monthInt
        dateComponents.day = 1
        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    /// Converts month name to integer
    private func monthToInt(_ month: String) -> Int {
        let monthNames = [
            "January": 1, "February": 2, "March": 3, "April": 4,
            "May": 5, "June": 6, "July": 7, "August": 8,
            "September": 9, "October": 10, "November": 11, "December": 12
        ]
        return monthNames[month] ?? 1
    }
} 
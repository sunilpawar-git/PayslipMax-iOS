//
//  QuizQuestionGenerators.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Generator for payslip-specific questions using actual user data
final class QuizPayslipQuestionGenerator: QuizPayslipQuestionGeneratorProtocol {
    // MARK: - Dependencies

    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let utility: QuizUtilityProtocol

    // MARK: - Initialization

    /// Initializes the payslip question generator
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel containing payslip data
    ///   - utility: Utility functions for formatting and calculations
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        utility: QuizUtilityProtocol
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.utility = utility
    }

    // MARK: - QuizPayslipQuestionGeneratorProtocol Implementation

    /// Generates payslip-specific questions with month references for clarity
    /// - Parameters:
    ///   - maxCount: Maximum number of questions to generate
    ///   - difficulty: Optional difficulty filter
    /// - Returns: Array of payslip-specific quiz questions
    func generatePayslipSpecificQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []

        let payslips = await financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }

        let latestPayslip = payslips.first!
        let monthYear = "\(latestPayslip.month) \(latestPayslip.year)"

        // Question 1: Basic Pay for specific month
        if let basicPay = latestPayslip.earnings["BPAY"] ?? latestPayslip.earnings["Basic Pay"],
           basicPay > 0, utility.shouldIncludeDifficulty(difficulty, .easy) {
            questions.append(generateBasicPayQuestion(basicPay: basicPay, monthYear: monthYear))
        }

        // Question 2: Net salary for specific month
        let netSalary = latestPayslip.credits - latestPayslip.debits - latestPayslip.tax
        if netSalary > 0, utility.shouldIncludeDifficulty(difficulty, .easy) {
            questions.append(generateNetSalaryQuestion(netSalary: netSalary, monthYear: monthYear))
        }

        // Question 3: Total deductions for specific month
        let totalDeductions = latestPayslip.debits + latestPayslip.tax
        if totalDeductions > 0, utility.shouldIncludeDifficulty(difficulty, .medium) {
            questions.append(generateDeductionsQuestion(deductions: totalDeductions, monthYear: monthYear))
        }

        // Question 4: Comparison with previous month (if available)
        if payslips.count > 1, utility.shouldIncludeDifficulty(difficulty, .hard) {
            if let comparisonQuestion = generateComparisonQuestion(latestPayslip: latestPayslip, previousPayslip: payslips[1]) {
                questions.append(comparisonQuestion)
            }
        }

        return Array(questions.prefix(maxCount))
    }

    // MARK: - Private Question Generation Methods

    private func generateBasicPayQuestion(basicPay: Double, monthYear: String) -> QuizQuestion {
        let correctBasicPay = utility.formatCurrencyForOptions(basicPay)
        let wrongOptions = utility.generateWrongCurrencyOptions(correct: basicPay)

        return QuizQuestion(
            questionText: "What was your Basic Pay for \(monthYear)?",
            questionType: .multipleChoice,
            options: ([correctBasicPay] + wrongOptions).shuffled(),
            correctAnswer: correctBasicPay,
            explanation: "Basic Pay is the foundation of your salary structure and was \(correctBasicPay) for \(monthYear).",
            difficulty: .easy,
            relatedInsightType: .income,
            contextData: QuizContextData(
                userIncome: basicPay,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: monthYear,
                calculationDetails: ["basic_pay": basicPay]
            )
        )
    }

    private func generateNetSalaryQuestion(netSalary: Double, monthYear: String) -> QuizQuestion {
        let correctNet = utility.formatCurrencyForOptions(netSalary)
        let wrongOptions = utility.generateWrongCurrencyOptions(correct: netSalary)

        return QuizQuestion(
            questionText: "What was your Net Salary (take-home pay) for \(monthYear)?",
            questionType: .multipleChoice,
            options: ([correctNet] + wrongOptions).shuffled(),
            correctAnswer: correctNet,
            explanation: "Your Net Salary for \(monthYear) was \(correctNet) after all deductions.",
            difficulty: .easy,
            relatedInsightType: .net,
            contextData: QuizContextData(
                userIncome: netSalary,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: monthYear,
                calculationDetails: ["net_salary": netSalary]
            )
        )
    }

    private func generateDeductionsQuestion(deductions: Double, monthYear: String) -> QuizQuestion {
        let correctDeductions = utility.formatCurrencyForOptions(deductions)
        let wrongOptions = utility.generateWrongCurrencyOptions(correct: deductions)

        return QuizQuestion(
            questionText: "What was your total deductions amount for \(monthYear)?",
            questionType: .multipleChoice,
            options: ([correctDeductions] + wrongOptions).shuffled(),
            correctAnswer: correctDeductions,
            explanation: "Total deductions for \(monthYear) were \(correctDeductions), including tax and other deductions.",
            difficulty: .medium,
            relatedInsightType: .deductions,
            contextData: QuizContextData(
                userIncome: nil,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: monthYear,
                calculationDetails: ["total_deductions": deductions]
            )
        )
    }

    private func generateComparisonQuestion(latestPayslip: any PayslipProtocol, previousPayslip: any PayslipProtocol) -> QuizQuestion? {
        let latestMonthYear = "\(latestPayslip.month) \(latestPayslip.year)"
        let previousMonthYear = "\(previousPayslip.month) \(previousPayslip.year)"

        let currentNet = latestPayslip.credits - latestPayslip.debits - latestPayslip.tax
        let previousNet = previousPayslip.credits - previousPayslip.debits - previousPayslip.tax

        let (fromMonth, toMonth, _, _, correctDifference) = utility.chronologicalComparison(
            latest: (latestMonthYear, currentNet),
            previous: (previousMonthYear, previousNet)
        )

        let isIncrease = correctDifference > 0
        let correctAnswer = isIncrease ? "Increased" : (correctDifference == 0 ? "Remained the same" : "Decreased")

        return QuizQuestion(
            questionText: "Did your net salary increase or decrease from \(fromMonth) to \(toMonth)?",
            questionType: .multipleChoice,
            options: ["Increased", "Decreased", "Remained the same", "Cannot determine"],
            correctAnswer: correctAnswer,
            explanation: "Your net salary \(correctAnswer.lowercased()) by ₹\(abs(correctDifference).formatted(.number.precision(.fractionLength(0)))) from \(fromMonth) to \(toMonth).",
            difficulty: .hard,
            relatedInsightType: .income,
            contextData: QuizContextData(
                userIncome: currentNet,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: "\(fromMonth) vs \(toMonth)",
                specificMonth: latestMonthYear,
                calculationDetails: ["current_net": currentNet, "previous_net": previousNet, "difference": correctDifference]
            )
        )
    }
}

//
//  QuizFallbackQuestions.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Generator for fallback questions when payslip data isn't available
final class QuizFallbackGenerator: QuizFallbackGeneratorProtocol {
    // MARK: - QuizFallbackGeneratorProtocol Implementation

    /// Generates fallback questions when payslip data isn't available
    /// - Parameter count: Number of fallback questions to generate
    /// - Returns: Array of fallback quiz questions
    func generateFallbackQuestions(count: Int) -> [QuizQuestion] {
        let fallbackQuestions = createFallbackQuestionDefinitions()
        return Array(fallbackQuestions.shuffled().prefix(count))
    }

    // MARK: - Private Methods

    /// Creates the predefined fallback question definitions
    /// - Returns: Array of fallback quiz questions
    private func createFallbackQuestionDefinitions() -> [QuizQuestion] {
        return [
            // Question 1: Net Remittance definition
            QuizQuestion(
                questionText: "What does 'Net Remittance' typically represent in a military payslip?",
                questionType: .multipleChoice,
                options: [
                    "Take-home pay after all deductions",
                    "Total gross salary before deductions",
                    "Only basic pay amount",
                    "Total allowances received"
                ].shuffled(),
                correctAnswer: "Take-home pay after all deductions",
                explanation: "Net Remittance is the final amount credited to your account after all deductions.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),

            // Question 2: DSOP definition
            {
                let correctAnswer2 = "Defence Service Officers Provident Fund"
                let options2 = [
                    correctAnswer2,
                    "Duty Station Operations Pay",
                    "Defence Support Operations Premium",
                    "Daily Service Officer Payment"
                ].shuffled()

                return QuizQuestion(
                    questionText: "What does 'DSOP' stand for in military payslips?",
                    questionType: .multipleChoice,
                    options: options2,
                    correctAnswer: correctAnswer2,
                    explanation: "DSOP is a retirement benefit scheme for defence personnel.",
                    difficulty: .medium,
                    relatedInsightType: .deductions,
                    contextData: QuizContextData(
                        userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                        averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                        calculationDetails: nil
                    )
                )
            }(),

            // Question 3: Basic Pay importance
            QuizQuestion(
                questionText: "Which component typically contributes the most to gross income?",
                questionType: .multipleChoice,
                options: [
                    "BPAY (Basic Pay)",
                    "DA (Dearness Allowance)",
                    "MSP (Military Service Pay)",
                    "HRA (House Rent Allowance)"
                ],
                correctAnswer: "BPAY (Basic Pay)",
                explanation: "Basic Pay usually forms the largest component of military salary.",
                difficulty: .medium,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),

            // Question 4: CDA Account Number
            QuizQuestion(
                questionText: "What part of your CDA Account Number remains fixed throughout service?",
                questionType: .multipleChoice,
                options: [
                    "The last six digits with check alpha",
                    "The first five digits only",
                    "The entire account number",
                    "Only the first two digits"
                ],
                correctAnswer: "The last six digits with check alpha",
                explanation: "The last six digits along with the check alpha (NNNNNNA) remain constant.",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),

            // Question 5: Income Tax Assessment Year
            QuizQuestion(
                questionText: "Income Tax in payslips is calculated for which Assessment Year?",
                questionType: .multipleChoice,
                options: [
                    "Current financial year + 1",
                    "Current financial year",
                    "Previous financial year",
                    "Next calendar year"
                ],
                correctAnswer: "Current financial year + 1",
                explanation: "Assessment Year is typically the financial year following the income year.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),

            // Question 6: DTS ticket reimbursement
            QuizQuestion(
                questionText: "What should be submitted for DTS ticket cancellation reimbursement?",
                questionType: .multipleChoice,
                options: [
                    "Claim with sanction under TR 44b",
                    "Only the cancelled ticket",
                    "Verbal confirmation only",
                    "Just the boarding pass"
                ],
                correctAnswer: "Claim with sanction under TR 44b",
                explanation: "Proper documentation and sanction are required for reimbursement claims.",
                difficulty: .hard,
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

// Note: IncomeQuestionGenerator, DeductionQuestionGenerator, and FinancialLiteracyQuestionGenerator
// are implemented in separate files for better organization and maintainability.

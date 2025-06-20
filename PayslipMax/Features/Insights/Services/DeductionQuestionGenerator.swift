import Foundation

/// Generates enhanced financial literacy deduction questions
@MainActor
class DeductionQuestionGenerator {
    
    private let financialSummaryViewModel: FinancialSummaryViewModel
    
    init(financialSummaryViewModel: FinancialSummaryViewModel) {
        self.financialSummaryViewModel = financialSummaryViewModel
    }
    
    /// Generates enhanced financial literacy deduction questions
    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let totalDeductions = latestPayslip.debits + latestPayslip.tax + latestPayslip.dsop
        let deductionPercentage = (totalDeductions / latestPayslip.credits) * 100
        
        // 💡 Deduction Efficiency Analysis Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let contextData = QuizContextData(
                userIncome: latestPayslip.credits,
                userTaxRate: (latestPayslip.tax / latestPayslip.credits) * 100,
                userDSOPContribution: latestPayslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["total_deductions": totalDeductions, "deduction_percentage": deductionPercentage]
            )
            
            let correctAnswer = deductionPercentage < 25 ? "Excellent - very tax efficient" : deductionPercentage < 35 ? "Good - within optimal range" : "High - consider optimization strategies"
            let allOptions = [
                correctAnswer,
                "Too low - should pay more tax",
                "Perfect - never change strategy",
                "Percentage doesn't matter"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Your total deductions are ₹\(formatCurrency(totalDeductions)) (\(String(format: "%.1f", deductionPercentage))% of gross). This deduction rate is:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Optimal deduction rates: <25% = Excellent tax planning, 25-35% = Good efficiency, >35% = Review needed. Consider maximizing ELSS, PPF, NPS to reduce taxable income while building wealth.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // 💡 DSOP Retirement Planning Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
            let projectedCorpus = latestPayslip.dsop * 12 * 25 * 1.08 // 25 years at 8% return
            let contextData = QuizContextData(
                userIncome: latestPayslip.credits,
                userTaxRate: nil,
                userDSOPContribution: latestPayslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["dsop_contribution": latestPayslip.dsop, "projected_corpus": projectedCorpus]
            )
            
            let correctAnswer = "Excellent retirement planning - DSOP gives guaranteed 8-9% returns"
            let allOptions = [
                correctAnswer,
                "Poor investment - should stop DSOP and invest elsewhere",
                "Average returns - FDs are better",
                "DSOP returns are unpredictable"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Your DSOP of ₹\(formatCurrency(latestPayslip.dsop)) (\(String(format: "%.1f", dsopPercentage))%) will grow to ₹\(formatCurrency(projectedCorpus)) in 25 years. This represents:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "DSOP is one of the best retirement investments with government backing, tax benefits, and consistent 8-9% returns. Your contribution builds substantial wealth for post-retirement financial security.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        return questions
    }
    
    // MARK: - Helper Methods
    
    private func shouldIncludeDifficulty(_ requested: QuizDifficulty?, _ questionDifficulty: QuizDifficulty) -> Bool {
        guard let requested = requested else { return true }
        return requested == questionDifficulty
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
} 
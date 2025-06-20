import Foundation

/// Generates advanced financial literacy and investment planning questions
@MainActor
class FinancialLiteracyQuestionGenerator {
    
    private let financialSummaryViewModel: FinancialSummaryViewModel
    
    init(financialSummaryViewModel: FinancialSummaryViewModel) {
        self.financialSummaryViewModel = financialSummaryViewModel
    }
    
    /// Generates advanced financial literacy and investment planning questions
    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let netTakeHome = latestPayslip.credits - latestPayslip.debits
        let surplusForInvestment = netTakeHome * 0.25 // 25% for investments
        
        // 💡 Investment Strategy Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let projectedWealth = surplusForInvestment * 12 * 15 * 1.12 // 15 years at 12% CAGR
            let contextData = QuizContextData(
                userIncome: surplusForInvestment,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["investment_surplus": surplusForInvestment, "projected_wealth": projectedWealth]
            )
            
            let correctAnswer = "Power of compounding - returns earn returns over time"
            let allOptions = [
                correctAnswer,
                "Market timing - buying at perfect moments",
                "Luck - markets are completely random",
                "Government subsidies for investments"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "If you invest ₹\(formatCurrency(surplusForInvestment)) monthly in equity mutual funds, you could have ₹\(formatCurrency(projectedWealth)) in 15 years. The key factor is:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Compounding is wealth creation's most powerful force. Your money grows exponentially because you earn returns on both principal and all previous returns. Starting early and staying consistent maximizes this effect dramatically.",
                difficulty: .medium,
                relatedInsightType: .income,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // 💡 Inflation Protection Question  
        if shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            let contextData = QuizContextData(
                userIncome: netTakeHome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: nil
            )
            
            let correctAnswer = "Above 6% annually to beat inflation"
            let allOptions = [
                correctAnswer,
                "Exactly 6% to match inflation",
                "Any positive return is sufficient",
                "Inflation doesn't affect investments"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Inflation averages 6% annually. To maintain your ₹\(formatCurrency(netTakeHome)) purchasing power, your investments must earn:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Inflation erodes money's purchasing power. If inflation is 6% and your investment earns 4%, you lose 2% purchasing power annually. Always target returns above inflation rate to build real wealth.",
                difficulty: .hard,
                relatedInsightType: .income,
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
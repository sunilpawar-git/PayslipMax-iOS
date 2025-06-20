import Foundation

/// Generates enhanced financial literacy income questions
@MainActor
class IncomeQuestionGenerator {
    
    private let financialSummaryViewModel: FinancialSummaryViewModel
    
    init(financialSummaryViewModel: FinancialSummaryViewModel) {
        self.financialSummaryViewModel = financialSummaryViewModel
    }
    
    /// Generates enhanced financial literacy income questions
    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let netTakeHome = latestPayslip.credits - latestPayslip.debits
        
        // 💡 Financial Literacy Question: Savings Rate Understanding
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            let recommendedSavings = netTakeHome * 0.25 // 25% savings rate
            let contextData = QuizContextData(
                userIncome: netTakeHome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["net_take_home": netTakeHome, "recommended_savings": recommendedSavings]
            )
            
            let correctAnswer = "20-30% (₹\(formatCurrency(recommendedSavings))) for wealth building"
            let allOptions = [
                correctAnswer,
                "5-10% is sufficient for any goals",
                "50-60% to retire early",
                "No specific percentage needed"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Your net take-home is ₹\(formatCurrency(netTakeHome)). For building long-term wealth, you should aim to save:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Financial experts recommend saving 20-30% of net income. Your ₹\(formatCurrency(recommendedSavings)) monthly can grow to ₹\(formatCurrency(recommendedSavings * 12 * 20 * 1.12)) in 20 years at 12% returns through disciplined investing.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // 💡 Emergency Fund Planning Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let monthlyExpenses = netTakeHome * 0.7 // Estimated expenses
            let emergencyFund = monthlyExpenses * 6
            let contextData = QuizContextData(
                userIncome: netTakeHome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["emergency_fund": emergencyFund, "monthly_expenses": monthlyExpenses]
            )
            
            let correctAnswer = "₹\(formatCurrency(emergencyFund)) (6 months of expenses)"
            let allOptions = [
                correctAnswer,
                "₹\(formatCurrency(netTakeHome)) (1 month income)",
                "₹50,000 (fixed amount)",
                "Not needed with job security"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "With your take-home of ₹\(formatCurrency(netTakeHome)), your emergency fund should be:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Emergency fund = 6 months of living expenses, not income. Keep in liquid funds for medical emergencies, job loss, or major repairs without touching long-term investments.",
                difficulty: .medium,
                relatedInsightType: .net,
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
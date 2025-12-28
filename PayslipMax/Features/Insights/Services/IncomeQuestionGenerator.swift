import Foundation

/// Generates enhanced financial literacy income questions
@MainActor
class IncomeQuestionGenerator: QuizQuestionGeneratorProtocol {

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
        let monthYear = "\(latestPayslip.month) \(latestPayslip.year)"
        let netTakeHome = FinancialCalculationUtility.shared.calculateNetIncome(for: latestPayslip)

        // 💡 Financial Literacy Question: Savings Rate Understanding
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            questions.append(createSavingsRateQuestion(latestPayslip: latestPayslip, monthYear: monthYear, netTakeHome: netTakeHome))
        }

        // 💡 Emergency Fund Planning Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            questions.append(createEmergencyFundQuestion(monthYear: monthYear, netTakeHome: netTakeHome))
        }

        // 📊 ACTUAL PAYSLIP DATA: Net Salary Question
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            questions.append(createNetSalaryQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: Gross Salary Question
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            questions.append(createGrossSalaryQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: Total Deductions Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            questions.append(createTotalDeductionsQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: Account Number Question
        let hasValidAccountNumber = !latestPayslip.accountNumber.isEmpty && latestPayslip.accountNumber.count >= 4
        if hasValidAccountNumber && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            questions.append(createAccountNumberQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        return questions.shuffled()
    }

    // MARK: - Helper Methods

    func shouldIncludeDifficulty(_ requested: QuizDifficulty?, _ questionDifficulty: QuizDifficulty) -> Bool {
        guard let requested = requested else { return true }
        return requested == questionDifficulty
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    func generateRandomDigits(_ count: Int) -> String {
        return String((0..<count).map { _ in String(Int.random(in: 1...9)) }.joined())
    }
}

import Foundation

/// Generates enhanced financial literacy deduction questions
@MainActor
class DeductionQuestionGenerator: QuizQuestionGeneratorProtocol {

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
        let monthYear = "\(latestPayslip.month) \(latestPayslip.year)"
        let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: latestPayslip)
        let deductionPercentage = (totalDeductions / latestPayslip.credits) * 100

        // 💡 Deduction Efficiency Analysis Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            questions.append(createDeductionEfficiencyQuestion(
                latestPayslip: latestPayslip,
                monthYear: monthYear,
                totalDeductions: totalDeductions,
                deductionPercentage: deductionPercentage
            ))
        }

        // 💡 DSOP Retirement Planning Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            questions.append(createDSOPRetirementQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: DSOP Amount Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            questions.append(createDSOPAmountQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: Tax Amount Question
        if latestPayslip.tax > 0 && shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            questions.append(createTaxAmountQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: DSOP Percentage Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            questions.append(createDSOPPercentageQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
        }

        // 📊 ACTUAL PAYSLIP DATA: Tax Percentage Question
        if latestPayslip.tax > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            questions.append(createTaxPercentageQuestion(latestPayslip: latestPayslip, monthYear: monthYear))
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
}

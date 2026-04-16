import Foundation

// MARK: - Savings Rate Question & Helper Methods

extension FinancialLiteracyQuestionGenerator {

    func createSavingsRateQuestion(
        latestPayslip: any PayslipProtocol,
        netTakeHome: Double
    ) -> QuizQuestion {
        let actualSavingsAmount = netTakeHome * 0.2
        let wrongRate1 = 15.0
        let wrongRate2 = 35.0
        let wrongRate3 = 50.0

        let correctAnswer = "20% (₹\(formatCurrency(actualSavingsAmount)) monthly)"
        let allOptions = [
            correctAnswer,
            "\(String(format: "%.0f", wrongRate1))% " +
                "(₹\(formatCurrency(netTakeHome * wrongRate1 / 100)) monthly)",
            "\(String(format: "%.0f", wrongRate2))% " +
                "(₹\(formatCurrency(netTakeHome * wrongRate2 / 100)) monthly)",
            "\(String(format: "%.0f", wrongRate3))% " +
                "(₹\(formatCurrency(netTakeHome * wrongRate3 / 100)) monthly)"
        ].shuffled()

        let netStr = formatCurrency(netTakeHome)
        let questionText = "With your net income of ₹\(netStr), what should be " +
            "your target savings rate for wealth building?"

        let savingsStr = formatCurrency(actualSavingsAmount)
        let explanation = "A 20% savings rate on your ₹\(netStr) income means saving " +
            "₹\(savingsStr) monthly, which can build substantial wealth over time."

        let contextData = QuizContextData(
            userIncome: netTakeHome,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: latestPayslip.month,
            calculationDetails: ["target_savings": actualSavingsAmount, "savings_rate": 20.0]
        )

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .hard,
            relatedInsightType: .income,
            contextData: contextData
        )
    }

    func shouldIncludeDifficulty(
        _ requested: QuizDifficulty?,
        _ questionDifficulty: QuizDifficulty
    ) -> Bool {
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

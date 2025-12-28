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

        // ✅ FIXED: Use correct calculation from FinancialCalculationUtility
        let totalDeductions = FinancialCalculationUtility.shared
            .calculateTotalDeductions(for: latestPayslip)
        let deductionPercentage = (totalDeductions / latestPayslip.credits) * 100

        // 💡 Deduction Efficiency Analysis Question - WITH MONTH CONTEXT
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let question = createDeductionEfficiencyQuestion(
                latestPayslip: latestPayslip,
                monthYear: monthYear,
                totalDeductions: totalDeductions,
                deductionPercentage: deductionPercentage
            )
            questions.append(question)
        }

        // 💡 DSOP Retirement Planning Question - WITH MONTH CONTEXT
        if latestPayslip.dsop > 0
            && shouldIncludeDifficulty(difficulty, .hard)
            && questions.count < maxCount {
            let question = createDSOPRetirementQuestion(
                latestPayslip: latestPayslip, monthYear: monthYear
            )
            questions.append(question)
        }

        // 📊 ACTUAL PAYSLIP DATA: DSOP Amount Question
        if latestPayslip.dsop > 0
            && shouldIncludeDifficulty(difficulty, .easy)
            && questions.count < maxCount {
            let question = createDSOPAmountQuestion(
                latestPayslip: latestPayslip, monthYear: monthYear
            )
            questions.append(question)
        }

        // 📊 ACTUAL PAYSLIP DATA: Tax Amount Question
        if latestPayslip.tax > 0
            && shouldIncludeDifficulty(difficulty, .medium)
            && questions.count < maxCount {
            let question = createTaxAmountQuestion(
                latestPayslip: latestPayslip, monthYear: monthYear
            )
            questions.append(question)
        }

        // 📊 ACTUAL PAYSLIP DATA: DSOP Percentage Question
        if latestPayslip.dsop > 0
            && shouldIncludeDifficulty(difficulty, .hard)
            && questions.count < maxCount {
            let question = createDSOPPercentageQuestion(
                latestPayslip: latestPayslip, monthYear: monthYear
            )
            questions.append(question)
        }

        // 📊 ACTUAL PAYSLIP DATA: Tax Percentage Question
        if latestPayslip.tax > 0
            && shouldIncludeDifficulty(difficulty, .hard)
            && questions.count < maxCount {
            let question = createTaxPercentageQuestion(
                latestPayslip: latestPayslip, monthYear: monthYear
            )
            questions.append(question)
        }

        return questions.shuffled()
    }

    // MARK: - Question Creation Helpers

    private func createDeductionEfficiencyQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String,
        totalDeductions: Double,
        deductionPercentage: Double
    ) -> QuizQuestion {
        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: (latestPayslip.tax / latestPayslip.credits) * 100,
            userDSOPContribution: latestPayslip.dsop,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: [
                "total_deductions": totalDeductions,
                "deduction_percentage": deductionPercentage
            ]
        )

        let correctAnswer: String
        if deductionPercentage < 25 {
            correctAnswer = "Excellent - very tax efficient"
        } else if deductionPercentage < 35 {
            correctAnswer = "Good - within optimal range"
        } else {
            correctAnswer = "High - consider optimization strategies"
        }

        let allOptions = [
            correctAnswer,
            "Too low - should pay more tax",
            "Perfect - never change strategy",
            "Percentage doesn't matter"
        ].shuffled()

        let formattedDeductions = formatCurrency(totalDeductions)
        let percentStr = String(format: "%.1f", deductionPercentage)
        let questionText = "Your total deductions for \(monthYear) are " +
            "₹\(formattedDeductions) (\(percentStr)% of gross). This deduction rate is:"

        let explanation = "For \(monthYear): Optimal deduction rates: <25% = Excellent " +
            "tax planning, 25-35% = Good efficiency, >35% = Review needed. " +
            "Consider maximizing ELSS, PPF, NPS to reduce taxable income."

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .medium,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    private func createDSOPRetirementQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String
    ) -> QuizQuestion {
        let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
        let projectedCorpus = latestPayslip.dsop * 12 * 25 * 1.08

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: nil,
            userDSOPContribution: latestPayslip.dsop,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: [
                "dsop_contribution": latestPayslip.dsop,
                "projected_corpus": projectedCorpus
            ]
        )

        let correctAnswer = "Excellent retirement planning - DSOP gives guaranteed 8-9% returns"
        let allOptions = [
            correctAnswer,
            "Poor investment - should stop DSOP and invest elsewhere",
            "Average returns - FDs are better",
            "DSOP returns are unpredictable"
        ].shuffled()

        let percentStr = String(format: "%.1f", dsopPercentage)
        let dsopStr = formatCurrency(latestPayslip.dsop)
        let corpusStr = formatCurrency(projectedCorpus)
        let questionText = "Your DSOP contribution for \(monthYear) is " +
            "₹\(dsopStr) (\(percentStr)% of gross). If this continues, " +
            "it will grow to ₹\(corpusStr) in 25 years. This represents:"

        let explanation = "Based on your \(monthYear) DSOP contribution: " +
            "DSOP is one of the best retirement investments with government backing, " +
            "tax benefits, and consistent 8-9% returns."

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .hard,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    private func createDSOPAmountQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String
    ) -> QuizQuestion {
        let actualDSOP = latestPayslip.dsop
        let wrongOption1 = actualDSOP + 1000
        let wrongOption2 = actualDSOP - 500
        let wrongOption3 = actualDSOP * 2

        let correctAnswer = "₹\(formatCurrency(actualDSOP))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(wrongOption1))",
            "₹\(formatCurrency(wrongOption2))",
            "₹\(formatCurrency(wrongOption3))"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: nil,
            userDSOPContribution: actualDSOP,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: nil
        )

        let explanation = "Your DSOP contribution for \(monthYear) was " +
            "₹\(formatCurrency(actualDSOP)), invested for retirement with guaranteed returns."

        return QuizQuestion(
            questionText: "What is your DSOP contribution amount for \(monthYear)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .easy,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    private func createTaxAmountQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String
    ) -> QuizQuestion {
        let actualTax = latestPayslip.tax
        let wrongOption1 = actualTax + 800
        let wrongOption2 = actualTax - 600
        let wrongOption3 = latestPayslip.debits

        let correctAnswer = "₹\(formatCurrency(actualTax))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(wrongOption1))",
            "₹\(formatCurrency(wrongOption2))",
            "₹\(formatCurrency(wrongOption3))"
        ].shuffled()

        let taxRate = (actualTax / latestPayslip.credits) * 100
        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: taxRate,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: nil
        )

        let explanation = "Your income tax for \(monthYear) was " +
            "₹\(formatCurrency(actualTax)), deducted at source (TDS)."

        return QuizQuestion(
            questionText: "What is your income tax deduction for \(monthYear)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .medium,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    private func createDSOPPercentageQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String
    ) -> QuizQuestion {
        let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
        let roundedPercentage = round(dsopPercentage * 10) / 10
        let wrongOption1 = roundedPercentage + 2.0
        let wrongOption2 = roundedPercentage - 1.5
        let wrongOption3 = roundedPercentage + 5.0

        let correctAnswer = "\(String(format: "%.1f", roundedPercentage))%"
        let allOptions = [
            correctAnswer,
            "\(String(format: "%.1f", wrongOption1))%",
            "\(String(format: "%.1f", wrongOption2))%",
            "\(String(format: "%.1f", wrongOption3))%"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: nil,
            userDSOPContribution: latestPayslip.dsop,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["dsop_percentage": roundedPercentage]
        )

        let percentStr = String(format: "%.1f", roundedPercentage)
        let questionText = "What percentage of your gross salary went to " +
            "DSOP contribution in \(monthYear)?"

        let explanation = "Your DSOP contribution for \(monthYear) was \(percentStr)% " +
            "of your gross salary, which is an excellent retirement savings rate."

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .hard,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    private func createTaxPercentageQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String
    ) -> QuizQuestion {
        let taxPercentage = (latestPayslip.tax / latestPayslip.credits) * 100
        let roundedTaxPercentage = round(taxPercentage * 10) / 10
        let wrongOption1 = roundedTaxPercentage + 3.0
        let wrongOption2 = roundedTaxPercentage - 2.0
        let wrongOption3 = 30.0

        let correctAnswer = "\(String(format: "%.1f", roundedTaxPercentage))%"
        let allOptions = [
            correctAnswer,
            "\(String(format: "%.1f", wrongOption1))%",
            "\(String(format: "%.1f", wrongOption2))%",
            "\(String(format: "%.1f", wrongOption3))%"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: roundedTaxPercentage,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["tax_percentage": roundedTaxPercentage]
        )

        let percentStr = String(format: "%.1f", roundedTaxPercentage)
        let questionText = "What percentage of your gross salary went to " +
            "income tax in \(monthYear)?"

        let explanation = "Your effective tax rate for \(monthYear) was \(percentStr)% " +
            "of your gross salary."

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .hard,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    // MARK: - Helper Methods

    private func shouldIncludeDifficulty(
        _ requested: QuizDifficulty?,
        _ questionDifficulty: QuizDifficulty
    ) -> Bool {
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

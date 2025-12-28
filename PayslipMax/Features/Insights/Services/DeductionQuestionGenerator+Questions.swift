import Foundation

// MARK: - Question Creation Methods

extension DeductionQuestionGenerator {

    func createDeductionEfficiencyQuestion(
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
            calculationDetails: ["total_deductions": totalDeductions, "deduction_percentage": deductionPercentage]
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
        let questionText = """
            Your total deductions for \(monthYear) are ₹\(formattedDeductions) \
            (\(percentStr)% of gross). This deduction rate is:
            """
        let explanation = """
            For \(monthYear): Optimal deduction rates: <25% = Excellent tax planning, \
            25-35% = Good efficiency, >35% = Review needed. \
            Consider maximizing ELSS, PPF, NPS to reduce taxable income.
            """

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

    func createDSOPRetirementQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
        let projectedCorpus = latestPayslip.dsop * 12 * 25 * 1.08

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: nil,
            userDSOPContribution: latestPayslip.dsop,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["dsop_contribution": latestPayslip.dsop, "projected_corpus": projectedCorpus]
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
        let questionText = "Your DSOP contribution for \(monthYear) is ₹\(dsopStr) (\(percentStr)% of gross). If this continues, it will grow to ₹\(corpusStr) in 25 years. This represents:"
        let explanation = "Based on your \(monthYear) DSOP contribution: DSOP is one of the best retirement investments with government backing, tax benefits, and consistent 8-9% returns."

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

    func createDSOPAmountQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let actualDSOP = latestPayslip.dsop
        let correctAnswer = "₹\(formatCurrency(actualDSOP))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(actualDSOP + 1000))",
            "₹\(formatCurrency(actualDSOP - 500))",
            "₹\(formatCurrency(actualDSOP * 2))"
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

        let explanation = "Your DSOP contribution for \(monthYear) was ₹\(formatCurrency(actualDSOP)), invested for retirement with guaranteed returns."

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

    func createTaxAmountQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let actualTax = latestPayslip.tax
        let correctAnswer = "₹\(formatCurrency(actualTax))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(actualTax + 800))",
            "₹\(formatCurrency(actualTax - 600))",
            "₹\(formatCurrency(latestPayslip.debits))"
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

        let explanation = "Your income tax for \(monthYear) was ₹\(formatCurrency(actualTax)), deducted at source (TDS)."

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

    func createDSOPPercentageQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
        let roundedPercentage = round(dsopPercentage * 10) / 10
        let correctAnswer = "\(String(format: "%.1f", roundedPercentage))%"
        let allOptions = [
            correctAnswer,
            "\(String(format: "%.1f", roundedPercentage + 2.0))%",
            "\(String(format: "%.1f", roundedPercentage - 1.5))%",
            "\(String(format: "%.1f", roundedPercentage + 5.0))%"
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
        let questionText = "What percentage of your gross salary went to DSOP contribution in \(monthYear)?"
        let explanation = "Your DSOP contribution for \(monthYear) was \(percentStr)% of your gross salary, which is an excellent retirement savings rate."

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

    func createTaxPercentageQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let taxPercentage = (latestPayslip.tax / latestPayslip.credits) * 100
        let roundedTaxPercentage = round(taxPercentage * 10) / 10
        let correctAnswer = "\(String(format: "%.1f", roundedTaxPercentage))%"
        let allOptions = [
            correctAnswer,
            "\(String(format: "%.1f", roundedTaxPercentage + 3.0))%",
            "\(String(format: "%.1f", roundedTaxPercentage - 2.0))%",
            "\(String(format: "%.1f", 30.0))%"
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
        let questionText = "What percentage of your gross salary went to income tax in \(monthYear)?"
        let explanation = "Your effective tax rate for \(monthYear) was \(percentStr)% of your gross salary."

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
}


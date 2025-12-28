import Foundation

// MARK: - Question Creation Methods

extension IncomeQuestionGenerator {

    func createSavingsRateQuestion(
        latestPayslip: any PayslipProtocol,
        monthYear: String,
        netTakeHome: Double
    ) -> QuizQuestion {
        let recommendedSavings = netTakeHome * 0.25
        let contextData = QuizContextData(
            userIncome: netTakeHome,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["net_take_home": netTakeHome, "recommended_savings": recommendedSavings]
        )

        let savingsStr = formatCurrency(recommendedSavings)
        let correctAnswer = "20-30% (₹\(savingsStr)) for wealth building"
        let allOptions = [
            correctAnswer,
            "5-10% is sufficient for any goals",
            "50-60% to retire early",
            "No specific percentage needed"
        ].shuffled()

        let netStr = formatCurrency(netTakeHome)
        let questionText = "Your net take-home for \(monthYear) is ₹\(netStr). For building long-term wealth, you should aim to save:"

        let futureValue = recommendedSavings * 12 * 20 * 1.12
        let futureValueStr = formatCurrency(futureValue)
        let explanation = """
            Based on your \(monthYear) income: Financial experts recommend saving 20-30% of net income. \
            Your ₹\(savingsStr) monthly can grow to ₹\(futureValueStr) in 20 years at 12% returns.
            """

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .easy,
            relatedInsightType: .net,
            contextData: contextData
        )
    }

    func createEmergencyFundQuestion(monthYear: String, netTakeHome: Double) -> QuizQuestion {
        let monthlyExpenses = netTakeHome * 0.7
        let emergencyFund = monthlyExpenses * 6
        let contextData = QuizContextData(
            userIncome: netTakeHome,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["emergency_fund": emergencyFund, "monthly_expenses": monthlyExpenses]
        )

        let correctAnswer = "₹\(formatCurrency(emergencyFund)) (6 months of expenses)"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(netTakeHome)) (1 month income)",
            "₹50,000 (fixed amount)",
            "Not needed with job security"
        ].shuffled()

        let netStr = formatCurrency(netTakeHome)
        let questionText = "With your take-home of ₹\(netStr), your emergency fund should be:"
        let explanation = "Emergency fund = 6 months of living expenses, not income. Keep in liquid funds for medical emergencies, job loss, or major repairs."

        return QuizQuestion(
            questionText: questionText,
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .medium,
            relatedInsightType: .net,
            contextData: contextData
        )
    }

    func createNetSalaryQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let actualNet = latestPayslip.getNetAmount()
        let correctAnswer = "₹\(formatCurrency(actualNet))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(actualNet + 5000))",
            "₹\(formatCurrency(actualNet - 3000))",
            "₹\(formatCurrency(latestPayslip.credits))"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: actualNet,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: nil
        )

        let explanation = "Net Remittance for \(monthYear) was ₹\(formatCurrency(actualNet)) - your actual take-home pay after all deductions from gross of ₹\(formatCurrency(latestPayslip.credits))."

        return QuizQuestion(
            questionText: "What is your net remittance (take-home amount) for \(monthYear)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .easy,
            relatedInsightType: .net,
            contextData: contextData
        )
    }

    func createGrossSalaryQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let grossSalary = latestPayslip.credits
        let correctAnswer = "₹\(formatCurrency(grossSalary))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(grossSalary + 8000))",
            "₹\(formatCurrency(grossSalary - 5000))",
            "₹\(formatCurrency(latestPayslip.getNetAmount()))"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: grossSalary,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: nil
        )

        let explanation = "Your gross salary for \(monthYear) was ₹\(formatCurrency(grossSalary)), including all allowances and earnings before deductions."

        return QuizQuestion(
            questionText: "What is your total gross salary (before deductions) for \(monthYear)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .easy,
            relatedInsightType: .income,
            contextData: contextData
        )
    }

    func createTotalDeductionsQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: latestPayslip)
        let correctAnswer = "₹\(formatCurrency(totalDeductions))"
        let allOptions = [
            correctAnswer,
            "₹\(formatCurrency(totalDeductions + 2000))",
            "₹\(formatCurrency(totalDeductions - 1500))",
            "₹\(formatCurrency(latestPayslip.tax))"
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: latestPayslip.credits,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: ["total_deductions": totalDeductions]
        )

        let deductionsStr = formatCurrency(totalDeductions)
        let taxStr = formatCurrency(latestPayslip.tax)
        let explanation = """
            Your total deductions for \(monthYear) were ₹\(deductionsStr), \
            which include all deductions from gross (including tax of ₹\(taxStr)).
            """

        return QuizQuestion(
            questionText: "What is your total deductions amount for \(monthYear)?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .medium,
            relatedInsightType: .deductions,
            contextData: contextData
        )
    }

    func createAccountNumberQuestion(latestPayslip: any PayslipProtocol, monthYear: String) -> QuizQuestion {
        let lastFourDigits = String(latestPayslip.accountNumber.suffix(4))
        let correctAnswer = lastFourDigits
        let allOptions = [
            correctAnswer,
            generateRandomDigits(4),
            generateRandomDigits(4),
            generateRandomDigits(4)
        ].shuffled()

        let contextData = QuizContextData(
            userIncome: nil,
            userTaxRate: nil,
            userDSOPContribution: nil,
            averageIncome: nil,
            comparisonPeriod: nil,
            specificMonth: monthYear,
            calculationDetails: nil
        )

        let explanation = "Your CDA account number ending in \(lastFourDigits) is where your salary gets credited each month."

        return QuizQuestion(
            questionText: "What are the last four digits of your CDA account number?",
            questionType: .multipleChoice,
            options: allOptions,
            correctAnswer: correctAnswer,
            explanation: explanation,
            difficulty: .hard,
            relatedInsightType: .income,
            contextData: contextData
        )
    }
}


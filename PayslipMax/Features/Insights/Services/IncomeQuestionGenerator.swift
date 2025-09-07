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
            let recommendedSavings = netTakeHome * 0.25 // 25% savings rate
            let contextData = QuizContextData(
                userIncome: netTakeHome,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: monthYear,
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
                questionText: "Your net take-home for \(monthYear) is ₹\(formatCurrency(netTakeHome)). For building long-term wealth, you should aim to save:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Based on your \(monthYear) income: Financial experts recommend saving 20-30% of net income. Your ₹\(formatCurrency(recommendedSavings)) monthly can grow to ₹\(formatCurrency(recommendedSavings * 12 * 20 * 1.12)) in 20 years at 12% returns through disciplined investing.",
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
        
        // 📊 ACTUAL PAYSLIP DATA: Net Salary Question
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            let actualNet = latestPayslip.getNetAmount()
            let wrongOption1 = actualNet + 5000
            let wrongOption2 = actualNet - 3000
            let wrongOption3 = latestPayslip.credits // Gross instead of net
            
            let correctAnswer = "₹\(formatCurrency(actualNet))"
            let allOptions = [
                correctAnswer,
                "₹\(formatCurrency(wrongOption1))",
                "₹\(formatCurrency(wrongOption2))",
                "₹\(formatCurrency(wrongOption3))"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What is your net remittance (take-home amount) for \(monthYear)?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Net Remittance for \(monthYear) was ₹\(formatCurrency(actualNet)) - your actual take-home pay after all deductions from your gross salary of ₹\(formatCurrency(latestPayslip.credits)).",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(userIncome: actualNet, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: monthYear, calculationDetails: nil)
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Gross Salary Question
        if shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
            let grossSalary = latestPayslip.credits
            let wrongOption1 = grossSalary + 8000
            let wrongOption2 = grossSalary - 5000
            let wrongOption3 = latestPayslip.getNetAmount() // Net instead of gross
            
            let correctAnswer = "₹\(formatCurrency(grossSalary))"
            let allOptions = [
                correctAnswer,
                "₹\(formatCurrency(wrongOption1))",
                "₹\(formatCurrency(wrongOption2))",
                "₹\(formatCurrency(wrongOption3))"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What is your total gross salary (before deductions) for \(monthYear)?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your gross salary for \(monthYear) was ₹\(formatCurrency(grossSalary)), which includes all your allowances and earnings before any deductions are applied.",
                difficulty: .easy,
                relatedInsightType: .income,
                contextData: QuizContextData(userIncome: grossSalary, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: monthYear, calculationDetails: nil)
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Total Deductions Question  
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            // ✅ FIXED: Use correct calculation from FinancialCalculationUtility
            let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: latestPayslip)
            let wrongOption1 = totalDeductions + 2000
            let wrongOption2 = totalDeductions - 1500
            let wrongOption3 = latestPayslip.tax // Only tax, not total deductions
            
            let correctAnswer = "₹\(formatCurrency(totalDeductions))"
            let allOptions = [
                correctAnswer,
                "₹\(formatCurrency(wrongOption1))",
                "₹\(formatCurrency(wrongOption2))",
                "₹\(formatCurrency(wrongOption3))"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What is your total deductions amount for \(monthYear)?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your total deductions for \(monthYear) were ₹\(formatCurrency(totalDeductions)), which include all deductions from your gross salary (including tax of ₹\(formatCurrency(latestPayslip.tax))).",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: monthYear, calculationDetails: ["total_deductions": totalDeductions])
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Account Number Question
        if !latestPayslip.accountNumber.isEmpty && latestPayslip.accountNumber.count >= 4 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            let lastFourDigits = String(latestPayslip.accountNumber.suffix(4))
            let wrongOption1 = generateRandomDigits(4)
            let wrongOption2 = generateRandomDigits(4)
            let wrongOption3 = generateRandomDigits(4)
            
            let correctAnswer = lastFourDigits
            let allOptions = [
                correctAnswer,
                wrongOption1,
                wrongOption2,
                wrongOption3
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What are the last four digits of your CDA account number?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your CDA account number ending in \(lastFourDigits) is where your salary gets credited each month.",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: QuizContextData(userIncome: nil, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: monthYear, calculationDetails: nil)
            )
            questions.append(question)
        }
        
        return questions.shuffled() // Randomize the order of questions returned
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
    
    private func generateRandomDigits(_ count: Int) -> String {
        return String((0..<count).map { _ in String(Int.random(in: 1...9)) }.joined())
    }
} 
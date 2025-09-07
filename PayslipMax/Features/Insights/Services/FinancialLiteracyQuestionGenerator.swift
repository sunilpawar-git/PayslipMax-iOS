import Foundation

/// Generates advanced financial literacy and investment planning questions
@MainActor
class FinancialLiteracyQuestionGenerator: QuizQuestionGeneratorProtocol {
    
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
        
        // 📊 ACTUAL PAYSLIP DATA: Highest Allowance Component Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount && !latestPayslip.earnings.isEmpty {
            // Get allowances from the earnings dictionary
            var allowanceAmounts: [(String, Double)] = []
            
            // Common earning components that might be in the earnings dictionary
            let knownEarnings = [
                ("BPAY", "Basic Pay"),
                ("Basic Pay", "Basic Pay"),
                ("DA", "Dearness Allowance"),
                ("Dearness Allowance", "Dearness Allowance"),
                ("MSP", "Military Service Pay"),
                ("Military Service Pay", "Military Service Pay"),
                ("HRA", "House Rent Allowance"),
                ("House Rent Allowance", "House Rent Allowance"),
                ("AGIF", "Army Group Insurance Fund"),
                ("Misc Credits", "Miscellaneous Credits")
            ]
            
            for (key, displayName) in knownEarnings {
                if let amount = latestPayslip.earnings[key], amount > 0 {
                    allowanceAmounts.append((displayName, amount))
                }
            }
            
            // If we have allowances, create the question
            if allowanceAmounts.count >= 2 {
                let highestAllowance = allowanceAmounts.max(by: { $0.1 < $1.1 })!
                let otherAllowances = allowanceAmounts.filter { $0.0 != highestAllowance.0 }
                
                var options = [highestAllowance.0]
                options.append(contentsOf: otherAllowances.prefix(3).map { $0.0 })
                
                // If we don't have enough options, add some generic ones
                if options.count < 4 {
                    let genericOptions = ["Transport Allowance", "Medical Allowance", "Special Allowance"]
                    options.append(contentsOf: genericOptions.prefix(4 - options.count))
                }
                
                let question = QuizQuestion(
                    questionText: "Which is your highest earning component this month?",
                    questionType: .multipleChoice,
                    options: Array(options.prefix(4)).shuffled(),
                    correctAnswer: highestAllowance.0,
                    explanation: "\(highestAllowance.0) of ₹\(formatCurrency(highestAllowance.1)) is your highest earning component, contributing significantly to your total income.",
                    difficulty: .medium,
                    relatedInsightType: .income,
                    contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: ["highest_allowance": highestAllowance.1])
                )
                questions.append(question)
            }
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Savings Rate Calculation Question
        if shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            // Target 20% savings rate for wealth building
            let actualSavingsAmount = netTakeHome * 0.2
            let wrongRate1 = 15.0
            let wrongRate2 = 35.0
            let wrongRate3 = 50.0
            
            let correctAnswer = "20% (₹\(formatCurrency(actualSavingsAmount)) monthly)"
            let allOptions = [
                correctAnswer,
                "\(String(format: "%.0f", wrongRate1))% (₹\(formatCurrency(netTakeHome * wrongRate1/100)) monthly)",
                "\(String(format: "%.0f", wrongRate2))% (₹\(formatCurrency(netTakeHome * wrongRate2/100)) monthly)",
                "\(String(format: "%.0f", wrongRate3))% (₹\(formatCurrency(netTakeHome * wrongRate3/100)) monthly)"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "With your net income of ₹\(formatCurrency(netTakeHome)), what should be your target savings rate for wealth building?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "A 20% savings rate on your ₹\(formatCurrency(netTakeHome)) income means saving ₹\(formatCurrency(actualSavingsAmount)) monthly, which can build substantial wealth over time through consistent investing.",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: QuizContextData(userIncome: netTakeHome, userTaxRate: nil, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: ["target_savings": actualSavingsAmount, "savings_rate": 20.0])
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
} 
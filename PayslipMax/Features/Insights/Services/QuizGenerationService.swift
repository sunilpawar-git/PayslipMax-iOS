import Foundation

/// Service responsible for generating personalized quiz questions based on user's payslip data
@MainActor
class QuizGenerationService: ObservableObject {
    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let trendAnalysisViewModel: TrendAnalysisViewModel
    private let chartDataViewModel: ChartDataViewModel
    
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        trendAnalysisViewModel: TrendAnalysisViewModel,
        chartDataViewModel: ChartDataViewModel
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.trendAnalysisViewModel = trendAnalysisViewModel
        self.chartDataViewModel = chartDataViewModel
    }
    
    /// Generates a set of personalized quiz questions
    func generateQuestions(count: Int = 5, difficulty: QuizDifficulty? = nil) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        // Try to generate personalized questions first
        questions.append(contentsOf: await generateIncomeQuestions(maxCount: 2, difficulty: difficulty))
        questions.append(contentsOf: await generateDeductionQuestions(maxCount: 2, difficulty: difficulty))
        questions.append(contentsOf: await generatePersonalDataQuestions(maxCount: 1, difficulty: difficulty))
        
        // Fill remaining slots with fallback questions
        let remaining = max(0, count - questions.count)
        if remaining > 0 {
            questions.append(contentsOf: generateFallbackQuestions(count: remaining))
        }
        
        // Shuffle and return requested count
        return Array(questions.shuffled().prefix(count))
    }
    
    /// Generates income-related questions
    private func generateIncomeQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let averageIncome = financialSummaryViewModel.calculateAverageIncome()
        
        // Question 1: Monthly Credits (Total Earnings)
        if shouldIncludeDifficulty(difficulty, .easy) {
            let contextData = QuizContextData(
                userIncome: latestPayslip.credits,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: averageIncome,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["total_credits": latestPayslip.credits]
            )
            
            let question = QuizQuestion(
                questionText: "What is your total credits (earnings) for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateIncomeOptions(correctAnswer: latestPayslip.credits),
                correctAnswer: "Rs. \(formatCurrency(latestPayslip.credits))",
                explanation: "Total credits include all income components before deductions.",
                difficulty: .easy,
                relatedInsightType: .income,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // Question 2: Net Pay  
        if shouldIncludeDifficulty(difficulty, .medium) {
            let netPay = latestPayslip.credits - latestPayslip.debits
            let contextData = QuizContextData(
                userIncome: netPay,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["net_pay": netPay]
            )
            
            let question = QuizQuestion(
                questionText: "What is your net pay (take-home) for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateIncomeOptions(correctAnswer: netPay),
                correctAnswer: "Rs. \(formatCurrency(netPay))",
                explanation: "Net pay is total credits minus total debits.",
                difficulty: .medium,
                relatedInsightType: .net,
                contextData: contextData
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generates deduction-related questions
    private func generateDeductionQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        
        // Question 1: Total Deductions
        if shouldIncludeDifficulty(difficulty, .medium) {
            let contextData = QuizContextData(
                userIncome: nil,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["total_deductions": latestPayslip.debits]
            )
            
            let question = QuizQuestion(
                questionText: "What is the total amount of deductions for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateDeductionOptions(correctAnswer: latestPayslip.debits),
                correctAnswer: "Rs. \(formatCurrency(latestPayslip.debits))",
                explanation: "Total deductions include all amounts subtracted from gross pay.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // Question 2: DSOP Contribution
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) {
            let contextData = QuizContextData(
                userIncome: nil,
                userTaxRate: nil,
                userDSOPContribution: latestPayslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["dsop_contribution": latestPayslip.dsop]
            )
            
            let question = QuizQuestion(
                questionText: "What is your DSOP contribution for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: generateDeductionOptions(correctAnswer: latestPayslip.dsop),
                correctAnswer: "Rs. \(formatCurrency(latestPayslip.dsop))",
                explanation: "DSOP (Defence Service Officers Provident Fund) is a retirement benefit scheme.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generates questions about personal data and administrative details
    private func generatePersonalDataQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        
        // Question 1: Account Number
        if !latestPayslip.accountNumber.isEmpty && latestPayslip.accountNumber.count >= 4,
           shouldIncludeDifficulty(difficulty, .hard) {
            let lastFourDigits = String(latestPayslip.accountNumber.suffix(4))
            let contextData = QuizContextData(
                userIncome: nil,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: nil,
                calculationDetails: nil
            )
            
            let question = QuizQuestion(
                questionText: "What are the last four digits of your account number?",
                questionType: .multipleChoice,
                options: generateAccountDigitOptions(correctAnswer: lastFourDigits),
                correctAnswer: lastFourDigits,
                explanation: "Account numbers are unique identifiers for banking transactions.",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: contextData
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Generates fallback questions when payslip data isn't available
    private func generateFallbackQuestions(count: Int) -> [QuizQuestion] {
        let fallbackQuestions = [
            QuizQuestion(
                questionText: "What does 'Net Remittance' typically represent in a military payslip?",
                questionType: .multipleChoice,
                options: [
                    "Take-home pay after all deductions",
                    "Total gross salary before deductions",
                    "Only basic pay amount",
                    "Total allowances received"
                ],
                correctAnswer: "Take-home pay after all deductions",
                explanation: "Net Remittance is the final amount credited to your account after all deductions.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            QuizQuestion(
                questionText: "What does 'DSOP' stand for in military payslips?",
                questionType: .multipleChoice,
                options: [
                    "Defence Service Officers Provident Fund",
                    "Duty Station Operations Pay",
                    "Defence Support Operations Premium",
                    "Daily Service Officer Payment"
                ],
                correctAnswer: "Defence Service Officers Provident Fund",
                explanation: "DSOP is a retirement benefit scheme for defence personnel.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            QuizQuestion(
                questionText: "Which component typically contributes the most to gross income?",
                questionType: .multipleChoice,
                options: [
                    "BPAY (Basic Pay)",
                    "DA (Dearness Allowance)",
                    "MSP (Military Service Pay)",
                    "HRA (House Rent Allowance)"
                ],
                correctAnswer: "BPAY (Basic Pay)",
                explanation: "Basic Pay usually forms the largest component of military salary.",
                difficulty: .medium,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            QuizQuestion(
                questionText: "What part of your CDA Account Number remains fixed throughout service?",
                questionType: .multipleChoice,
                options: [
                    "The last six digits with check alpha",
                    "The first five digits only",
                    "The entire account number",
                    "Only the first two digits"
                ],
                correctAnswer: "The last six digits with check alpha",
                explanation: "The last six digits along with the check alpha (NNNNNNA) remain constant.",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            QuizQuestion(
                questionText: "Income Tax in payslips is calculated for which Assessment Year?",
                questionType: .multipleChoice,
                options: [
                    "Current financial year + 1",
                    "Current financial year",
                    "Previous financial year",
                    "Next calendar year"
                ],
                correctAnswer: "Current financial year + 1",
                explanation: "Assessment Year is typically the financial year following the income year.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            QuizQuestion(
                questionText: "What should be submitted for DTS ticket cancellation reimbursement?",
                questionType: .multipleChoice,
                options: [
                    "Claim with sanction under TR 44b",
                    "Only the cancelled ticket",
                    "Verbal confirmation only",
                    "Just the boarding pass"
                ],
                correctAnswer: "Claim with sanction under TR 44b",
                explanation: "Proper documentation and sanction are required for reimbursement claims.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            )
        ]
        
        return Array(fallbackQuestions.shuffled().prefix(count))
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
    
    private func generateIncomeOptions(correctAnswer: Double) -> [String] {
        let correct = "Rs. \(formatCurrency(correctAnswer))"
        let variations = [
            "Rs. \(formatCurrency(correctAnswer * 0.8))",
            "Rs. \(formatCurrency(correctAnswer * 1.2))",
            "Rs. \(formatCurrency(correctAnswer * 0.95))"
        ]
        return ([correct] + variations).shuffled()
    }
    
    private func generateDeductionOptions(correctAnswer: Double) -> [String] {
        let correct = "Rs. \(formatCurrency(correctAnswer))"
        let variations = [
            "Rs. \(formatCurrency(correctAnswer * 0.7))",
            "Rs. \(formatCurrency(correctAnswer * 1.3))",
            "Rs. \(formatCurrency(correctAnswer * 0.9))"
        ]
        return ([correct] + variations).shuffled()
    }
    
    private func generateAccountDigitOptions(correctAnswer: String) -> [String] {
        let incorrectOptions = ["1234", "5678", "9876", "4321"].filter { $0 != correctAnswer }
        return ([correctAnswer] + Array(incorrectOptions.prefix(3))).shuffled()
    }
    
    /// Generates a quiz with specified parameters
    @MainActor
    func generateQuiz(
        questionCount: Int = 5,
        difficulty: QuizDifficulty? = nil,
        timeLimit: TimeInterval? = nil
    ) async -> [QuizQuestion] {
        return await generateQuestions(count: questionCount, difficulty: difficulty)
    }
    
    /// Updates the service with new payslip data for generating personalized questions
    @MainActor
    func updatePayslipData(_ payslips: [any PayslipProtocol]) async {
        // This method updates the internal data sources when new payslip data is available
        // For now, this is handled through the ViewModels, but can be enhanced later
        // to cache payslip data locally within the service for better performance
    }
} 
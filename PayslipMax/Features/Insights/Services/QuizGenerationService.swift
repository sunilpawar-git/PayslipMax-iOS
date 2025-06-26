import Foundation

/// Service responsible for generating personalized quiz questions based on user's payslip data
@MainActor
class QuizGenerationService: ObservableObject {
    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let trendAnalysisViewModel: TrendAnalysisViewModel
    private let chartDataViewModel: ChartDataViewModel
    
    // Question generators
    private let incomeQuestionGenerator: IncomeQuestionGenerator
    private let deductionQuestionGenerator: DeductionQuestionGenerator
    private let financialLiteracyQuestionGenerator: FinancialLiteracyQuestionGenerator
    
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        trendAnalysisViewModel: TrendAnalysisViewModel,
        chartDataViewModel: ChartDataViewModel
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.trendAnalysisViewModel = trendAnalysisViewModel
        self.chartDataViewModel = chartDataViewModel
        
        // Initialize question generators
        self.incomeQuestionGenerator = IncomeQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)
        self.deductionQuestionGenerator = DeductionQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)
        self.financialLiteracyQuestionGenerator = FinancialLiteracyQuestionGenerator(financialSummaryViewModel: financialSummaryViewModel)
    }
    
    /// Generates a set of personalized quiz questions
    func generateQuiz(questionCount: Int = 5, difficulty: QuizDifficulty? = nil) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        // 🔥 CRITICAL FIX: Load actual payslip data first
        await loadPayslipData()
        
        // Check if we have payslip data
        if !financialSummaryViewModel.payslips.isEmpty {
            print("QuizGenerationService: Found \(financialSummaryViewModel.payslips.count) payslips for quiz generation")
            
            // Start with payslip-specific questions for better user engagement
            let payslipSpecificQuestions = await generatePayslipSpecificQuestions(maxCount: 3, difficulty: difficulty)
            questions.append(contentsOf: payslipSpecificQuestions)
            
            // Add other personalized questions
            let incomeQuestions = incomeQuestionGenerator.generateQuestions(maxCount: 3, difficulty: difficulty)
            let deductionQuestions = deductionQuestionGenerator.generateQuestions(maxCount: 3, difficulty: difficulty)
            let literacyQuestions = financialLiteracyQuestionGenerator.generateQuestions(maxCount: 2, difficulty: difficulty)
            
            questions.append(contentsOf: incomeQuestions)
            questions.append(contentsOf: deductionQuestions)
            questions.append(contentsOf: literacyQuestions)
            
            print("QuizGenerationService: Generated \(questions.count) personalized questions")
        } else {
            print("QuizGenerationService: No payslip data available, using fallback questions only")
        }
        
        // Fill remaining slots with fallback questions
        let remaining = max(0, questionCount - questions.count)
        if remaining > 0 {
            questions.append(contentsOf: generateFallbackQuestions(count: remaining))
        }
        
        print("QuizGenerationService: Final question count: \(questions.count)")
        // Shuffle and return requested count
        return Array(questions.shuffled().prefix(questionCount))
    }
    
    /// Loads payslip data into the financial summary view model
    private func loadPayslipData() async {
        do {
            let dataService = DIContainer.shared.dataService
            
            // Initialize data service if needed
            if !dataService.isInitialized {
                try await dataService.initialize()
            }
            
            // Fetch payslips
            let payslips = try await dataService.fetch(PayslipItem.self)
            print("QuizGenerationService: Loaded \(payslips.count) payslips from data service")
            
            // Update the financial summary view model with the loaded payslips
            financialSummaryViewModel.updatePayslips(payslips)
            
        } catch {
            print("QuizGenerationService: Error loading payslip data: \(error.localizedDescription)")
        }
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
        let correctAnswer1 = "Take-home pay after all deductions"
        let options1 = [
            correctAnswer1,
            "Total gross salary before deductions",
            "Only basic pay amount",
            "Total allowances received"
        ].shuffled()
        
        let fallbackQuestions = [
            QuizQuestion(
                questionText: "What does 'Net Remittance' typically represent in a military payslip?",
                questionType: .multipleChoice,
                options: options1,
                correctAnswer: correctAnswer1,
                explanation: "Net Remittance is the final amount credited to your account after all deductions.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                    averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            
            {
                let correctAnswer2 = "Defence Service Officers Provident Fund"
                let options2 = [
                    correctAnswer2,
                    "Duty Station Operations Pay",
                    "Defence Support Operations Premium",
                    "Daily Service Officer Payment"
                ].shuffled()
                
                return QuizQuestion(
                    questionText: "What does 'DSOP' stand for in military payslips?",
                    questionType: .multipleChoice,
                    options: options2,
                    correctAnswer: correctAnswer2,
                    explanation: "DSOP is a retirement benefit scheme for defence personnel.",
                    difficulty: .medium,
                    relatedInsightType: .deductions,
                    contextData: QuizContextData(
                        userIncome: nil, userTaxRate: nil, userDSOPContribution: nil,
                        averageIncome: nil, comparisonPeriod: nil, specificMonth: nil,
                        calculationDetails: nil
                    )
                )
            }(),
            
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
    
    /// Generates payslip-specific questions with month references for clarity
    private func generatePayslipSpecificQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        let payslips = financialSummaryViewModel.payslips
        guard !payslips.isEmpty else { return questions }
        
        let latestPayslip = payslips.first!
        let monthYear = "\(latestPayslip.month) \(latestPayslip.year)"
        
        // Question 1: Basic Pay for specific month
        let basicPay = latestPayslip.earnings["BPAY"] ?? latestPayslip.earnings["Basic Pay"] ?? 0
        if basicPay > 0, shouldIncludeDifficulty(difficulty, .easy) {
            let correctBasicPay = formatCurrencyForOptions(basicPay)
            let wrongOptions = generateWrongCurrencyOptions(correct: basicPay)
            
            let question = QuizQuestion(
                questionText: "What was your Basic Pay for \(monthYear)?",
                questionType: .multipleChoice,
                options: ([correctBasicPay] + wrongOptions).shuffled(),
                correctAnswer: correctBasicPay,
                explanation: "Basic Pay is the foundation of your salary structure and was \(correctBasicPay) for \(monthYear).",
                difficulty: .easy,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: basicPay,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: monthYear,
                    calculationDetails: ["basic_pay": basicPay]
                )
            )
            questions.append(question)
        }
        
        // Question 2: Net salary for specific month
        let netSalary = latestPayslip.credits - latestPayslip.debits - latestPayslip.tax
        if netSalary > 0, shouldIncludeDifficulty(difficulty, .easy) {
            let correctNet = formatCurrencyForOptions(netSalary)
            let wrongOptions = generateWrongCurrencyOptions(correct: netSalary)
            
            let question = QuizQuestion(
                questionText: "What was your Net Salary (take-home pay) for \(monthYear)?",
                questionType: .multipleChoice,
                options: ([correctNet] + wrongOptions).shuffled(),
                correctAnswer: correctNet,
                explanation: "Your Net Salary for \(monthYear) was \(correctNet) after all deductions.",
                difficulty: .easy,
                relatedInsightType: .net,
                contextData: QuizContextData(
                    userIncome: netSalary,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: monthYear,
                    calculationDetails: ["net_salary": netSalary]
                )
            )
            questions.append(question)
        }
        
        // Question 3: Total deductions for specific month
        let totalDeductions = latestPayslip.debits + latestPayslip.tax
        if totalDeductions > 0, shouldIncludeDifficulty(difficulty, .medium) {
            let correctDeductions = formatCurrencyForOptions(totalDeductions)
            let wrongOptions = generateWrongCurrencyOptions(correct: totalDeductions)
            
            let question = QuizQuestion(
                questionText: "What was your total deductions amount for \(monthYear)?",
                questionType: .multipleChoice,
                options: ([correctDeductions] + wrongOptions).shuffled(),
                correctAnswer: correctDeductions,
                explanation: "Total deductions for \(monthYear) were \(correctDeductions), including tax and other deductions.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: monthYear,
                    calculationDetails: ["total_deductions": totalDeductions]
                )
            )
            questions.append(question)
        }
        
        // Question 4: Comparison with previous month (if available)
        if payslips.count > 1, shouldIncludeDifficulty(difficulty, .hard) {
            let previousPayslip = payslips[1]
            let previousMonthYear = "\(previousPayslip.month) \(previousPayslip.year)"
            let currentNet = latestPayslip.credits - latestPayslip.debits - latestPayslip.tax
            let previousNet = previousPayslip.credits - previousPayslip.debits - previousPayslip.tax
            let difference = currentNet - previousNet
            
            let isIncrease = difference > 0
            let correctAnswer = isIncrease ? "Increased" : "Decreased"
            
            let question = QuizQuestion(
                questionText: "Did your net salary increase or decrease from \(previousMonthYear) to \(monthYear)?",
                questionType: .multipleChoice,
                options: ["Increased", "Decreased", "Remained the same", "Cannot determine"],
                correctAnswer: correctAnswer,
                explanation: "Your net salary \(correctAnswer.lowercased()) by ₹\(abs(difference).formatted(.number.precision(.fractionLength(0)))) from \(previousMonthYear) to \(monthYear).",
                difficulty: .hard,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: currentNet,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: "\(previousMonthYear) vs \(monthYear)",
                    specificMonth: monthYear,
                    calculationDetails: ["current_net": currentNet, "previous_net": previousNet, "difference": difference]
                )
            )
            questions.append(question)
        }
        
        return Array(questions.prefix(maxCount))
    }
    
    /// Formats currency amount for quiz options
    private func formatCurrencyForOptions(_ amount: Double) -> String {
        if amount >= 100000 {
            return "₹\((amount/100000).formatted(.number.precision(.fractionLength(1))))L"
        } else if amount >= 1000 {
            return "₹\((amount/1000).formatted(.number.precision(.fractionLength(1))))K"
        } else {
            return "₹\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }
    
    /// Generates plausible wrong options for currency amounts
    private func generateWrongCurrencyOptions(correct: Double) -> [String] {
        let variations = [
            correct * 0.8,  // 20% less
            correct * 1.2,  // 20% more
            correct * 0.9   // 10% less
        ]
        
        return variations.map { formatCurrencyForOptions($0) }
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
        return await generateQuiz(questionCount: questionCount, difficulty: difficulty)
    }
    
    /// Updates the service with new payslip data for generating personalized questions
    @MainActor
    func updatePayslipData(_ payslips: [any PayslipProtocol]) async {
        // This method updates the internal data sources when new payslip data is available
        // For now, this is handled through the ViewModels, but can be enhanced later
        // to cache payslip data locally within the service for better performance
    }
} 
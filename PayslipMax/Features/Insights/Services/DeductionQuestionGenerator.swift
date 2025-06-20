import Foundation

/// Generates enhanced financial literacy deduction questions
@MainActor
class DeductionQuestionGenerator {
    
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
        let totalDeductions = latestPayslip.debits + latestPayslip.tax + latestPayslip.dsop
        let deductionPercentage = (totalDeductions / latestPayslip.credits) * 100
        
        // 💡 Deduction Efficiency Analysis Question
        if shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let contextData = QuizContextData(
                userIncome: latestPayslip.credits,
                userTaxRate: (latestPayslip.tax / latestPayslip.credits) * 100,
                userDSOPContribution: latestPayslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["total_deductions": totalDeductions, "deduction_percentage": deductionPercentage]
            )
            
            let correctAnswer = deductionPercentage < 25 ? "Excellent - very tax efficient" : deductionPercentage < 35 ? "Good - within optimal range" : "High - consider optimization strategies"
            let allOptions = [
                correctAnswer,
                "Too low - should pay more tax",
                "Perfect - never change strategy",
                "Percentage doesn't matter"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Your total deductions are ₹\(formatCurrency(totalDeductions)) (\(String(format: "%.1f", deductionPercentage))% of gross). This deduction rate is:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Optimal deduction rates: <25% = Excellent tax planning, 25-35% = Good efficiency, >35% = Review needed. Consider maximizing ELSS, PPF, NPS to reduce taxable income while building wealth.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // 💡 DSOP Retirement Planning Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            let dsopPercentage = (latestPayslip.dsop / latestPayslip.credits) * 100
            let projectedCorpus = latestPayslip.dsop * 12 * 25 * 1.08 // 25 years at 8% return
            let contextData = QuizContextData(
                userIncome: latestPayslip.credits,
                userTaxRate: nil,
                userDSOPContribution: latestPayslip.dsop,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: latestPayslip.month,
                calculationDetails: ["dsop_contribution": latestPayslip.dsop, "projected_corpus": projectedCorpus]
            )
            
            let correctAnswer = "Excellent retirement planning - DSOP gives guaranteed 8-9% returns"
            let allOptions = [
                correctAnswer,
                "Poor investment - should stop DSOP and invest elsewhere",
                "Average returns - FDs are better",
                "DSOP returns are unpredictable"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "Your DSOP of ₹\(formatCurrency(latestPayslip.dsop)) (\(String(format: "%.1f", dsopPercentage))%) will grow to ₹\(formatCurrency(projectedCorpus)) in 25 years. This represents:",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "DSOP is one of the best retirement investments with government backing, tax benefits, and consistent 8-9% returns. Your contribution builds substantial wealth for post-retirement financial security.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: contextData
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: DSOP Amount Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .easy) && questions.count < maxCount {
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
            
            let question = QuizQuestion(
                questionText: "What is your DSOP contribution amount for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your DSOP contribution of ₹\(formatCurrency(actualDSOP)) is being invested for your retirement with guaranteed returns.",
                difficulty: .easy,
                relatedInsightType: .deductions,
                contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: nil, userDSOPContribution: actualDSOP, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: nil)
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Tax Amount Question
        if latestPayslip.tax > 0 && shouldIncludeDifficulty(difficulty, .medium) && questions.count < maxCount {
            let actualTax = latestPayslip.tax
            let wrongOption1 = actualTax + 800
            let wrongOption2 = actualTax - 600
            let wrongOption3 = latestPayslip.debits // Total deductions instead of tax
            
            let correctAnswer = "₹\(formatCurrency(actualTax))"
            let allOptions = [
                correctAnswer,
                "₹\(formatCurrency(wrongOption1))",
                "₹\(formatCurrency(wrongOption2))",
                "₹\(formatCurrency(wrongOption3))"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What is your income tax deduction for \(latestPayslip.month) \(latestPayslip.year)?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your income tax of ₹\(formatCurrency(actualTax)) is deducted at source (TDS) based on your annual income projection.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: (actualTax/latestPayslip.credits)*100, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: nil)
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: DSOP Percentage Question
        if latestPayslip.dsop > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
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
            
            let question = QuizQuestion(
                questionText: "What percentage of your gross salary goes to DSOP contribution?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your DSOP contribution is \(String(format: "%.1f", roundedPercentage))% of your gross salary, which is an excellent retirement savings rate.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: nil, userDSOPContribution: latestPayslip.dsop, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: ["dsop_percentage": roundedPercentage])
            )
            questions.append(question)
        }
        
        // 📊 ACTUAL PAYSLIP DATA: Tax Percentage Question
        if latestPayslip.tax > 0 && shouldIncludeDifficulty(difficulty, .hard) && questions.count < maxCount {
            let taxPercentage = (latestPayslip.tax / latestPayslip.credits) * 100
            let roundedTaxPercentage = round(taxPercentage * 10) / 10
            let wrongOption1 = roundedTaxPercentage + 3.0
            let wrongOption2 = roundedTaxPercentage - 2.0
            let wrongOption3 = 30.0 // Standard tax rate
            
            let correctAnswer = "\(String(format: "%.1f", roundedTaxPercentage))%"
            let allOptions = [
                correctAnswer,
                "\(String(format: "%.1f", wrongOption1))%",
                "\(String(format: "%.1f", wrongOption2))%",
                "\(String(format: "%.1f", wrongOption3))%"
            ].shuffled()
            
            let question = QuizQuestion(
                questionText: "What percentage of your gross salary goes to income tax?",
                questionType: .multipleChoice,
                options: allOptions,
                correctAnswer: correctAnswer,
                explanation: "Your effective tax rate is \(String(format: "%.1f", roundedTaxPercentage))% of your gross salary this month.",
                difficulty: .hard,
                relatedInsightType: .deductions,
                contextData: QuizContextData(userIncome: latestPayslip.credits, userTaxRate: roundedTaxPercentage, userDSOPContribution: nil, averageIncome: nil, comparisonPeriod: nil, specificMonth: latestPayslip.month, calculationDetails: ["tax_percentage": roundedTaxPercentage])
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
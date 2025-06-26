import Foundation

@MainActor
class RecommendationEngine {
    
    // MARK: - Constants
    
    private struct Constants {
        static let minimumDataPoints = 3
        static let optimalTaxRate = 0.15
        static let goodGrowthRate = 0.03
        static let minimumInvestmentThreshold = 10000.0
        static let optimalSavingsRate = 0.20
    }
    
    // MARK: - Public Methods
    
    func generateProfessionalRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= Constants.minimumDataPoints else {
            return createInsufficientDataRecommendations()
        }
        
        var recommendations: [ProfessionalRecommendation] = []
        
        // Generate different types of recommendations concurrently
        async let taxRecommendations = generateTaxOptimizationRecommendations(payslips: payslips)
        async let careerRecommendations = generateCareerGrowthRecommendations(payslips: payslips)
        async let investmentRecommendations = generateInvestmentRecommendations(payslips: payslips)
        async let savingsRecommendations = generateSavingsRecommendations(payslips: payslips)
        async let deductionRecommendations = generateDeductionOptimizationRecommendations(payslips: payslips)
        
        recommendations.append(contentsOf: await taxRecommendations)
        recommendations.append(contentsOf: await careerRecommendations)
        recommendations.append(contentsOf: await investmentRecommendations)
        recommendations.append(contentsOf: await savingsRecommendations)
        recommendations.append(contentsOf: await deductionRecommendations)
        
        // Sort by priority and return top recommendations
        return Array(recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }.prefix(10))
    }
    
    // MARK: - Private Recommendation Methods
    
    private func createInsufficientDataRecommendations() -> [ProfessionalRecommendation] {
        return [
            ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Upload More Payslips",
                summary: "We need more data to provide accurate insights",
                detailedAnalysis: "Please upload at least 3 months of payslips for comprehensive analysis.",
                actionSteps: ["Upload recent payslips", "Ensure data accuracy"],
                potentialSavings: nil,
                priority: .medium,
                source: .aiAnalysis
            )
        ]
    }
    
    private func generateTaxOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveTaxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if effectiveTaxRate > Constants.optimalTaxRate {
            let potentialSavings = totalIncome * (effectiveTaxRate - Constants.optimalTaxRate)
            
            recommendations.append(ProfessionalRecommendation(
                category: .taxOptimization,
                title: "Tax Optimization Opportunity",
                summary: "Your effective tax rate of \(String(format: "%.1f", effectiveTaxRate * 100))% is above optimal",
                detailedAnalysis: "With proper tax planning, you could potentially reduce your tax burden and save approximately ₹\(Int(potentialSavings)) annually.",
                actionSteps: [
                    "Maximize 80C deductions (₹1.5L limit)",
                    "Utilize 80D for health insurance premiums",
                    "Consider ELSS mutual funds for tax-saving",
                    "Review house rent allowance (HRA) claims",
                    "Optimize meal vouchers and transport allowance",
                    "Consult with a tax advisor for personalized strategy"
                ],
                potentialSavings: potentialSavings,
                priority: potentialSavings > 20000 ? .high : .medium,
                source: .aiAnalysis
            ))
        }
        
        // Additional tax recommendations based on specific patterns
        let monthlyTaxVariation = calculateTaxVariation(payslips: payslips)
        if monthlyTaxVariation > 0.20 {
            recommendations.append(ProfessionalRecommendation(
                category: .taxOptimization,
                title: "Stabilize Tax Deductions",
                summary: "Your monthly tax varies significantly (\(String(format: "%.1f", monthlyTaxVariation * 100))%)",
                detailedAnalysis: "High tax variation suggests inconsistent deduction planning throughout the year.",
                actionSteps: [
                    "Plan tax-saving investments at year beginning",
                    "Set up systematic investment plans (SIP)",
                    "Use tax-saving fixed deposits if needed",
                    "Maintain monthly investment discipline"
                ],
                potentialSavings: totalIncome * 0.02, // 2% potential savings
                priority: .medium,
                source: .aiAnalysis
            ))
        }
        
        return recommendations
    }
    
    private func generateCareerGrowthRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= 6 else { return [] }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if growthRate < Constants.goodGrowthRate { // Less than 3% growth
            recommendations.append(ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Accelerate Career Progression",
                summary: "Your income growth of \(String(format: "%.1f", growthRate * 100))% is below industry average",
                detailedAnalysis: "Slow income growth may indicate opportunities for career advancement or skill development to increase earning potential.",
                actionSteps: [
                    "Identify key skills in demand in your field",
                    "Pursue relevant certifications or training",
                    "Network within your industry",
                    "Document and communicate your achievements",
                    "Consider lateral moves or role expansion",
                    "Schedule performance review with manager",
                    "Research market salary benchmarks"
                ],
                potentialSavings: recentAverage * 0.20 * 12, // 20% potential income increase annually
                priority: .high,
                source: .aiAnalysis
            ))
        }
        
        // Income stability recommendation
        let incomeVolatility = calculateIncomeVolatility(payslips: payslips)
        if incomeVolatility > 0.15 {
            recommendations.append(ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Income Stabilization Strategy",
                summary: "Your income shows high volatility (\(String(format: "%.1f", incomeVolatility * 100))%)",
                detailedAnalysis: "Variable income can impact financial planning and security.",
                actionSteps: [
                    "Explore stable employment opportunities",
                    "Develop multiple income streams",
                    "Build larger emergency fund (12+ months)",
                    "Consider freelance or consulting work",
                    "Negotiate for fixed component increases"
                ],
                potentialSavings: nil,
                priority: .medium,
                source: .aiAnalysis
            ))
        }
        
        return recommendations
    }
    
    private func generateInvestmentRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate available for investment (assuming 70% goes to expenses)
        let availableForInvestment = netIncome * 0.30
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if availableForInvestment > Constants.minimumInvestmentThreshold {
            recommendations.append(ProfessionalRecommendation(
                category: .investmentStrategy,
                title: "Investment Portfolio Development",
                summary: "You have approximately ₹\(Int(availableForInvestment)) available for investments annually",
                detailedAnalysis: "Based on your income stability and risk profile, we recommend a diversified investment approach to build long-term wealth.",
                actionSteps: [
                    "Allocate 60% to equity mutual funds for long-term growth",
                    "Invest 30% in debt instruments for stability",
                    "Keep 10% in liquid funds for emergencies",
                    "Start systematic investment plans (SIP)",
                    "Review and rebalance portfolio quarterly",
                    "Consider index funds for low-cost exposure",
                    "Gradually increase equity allocation with age"
                ],
                potentialSavings: availableForInvestment * 0.12 * 5, // 12% annual returns over 5 years
                priority: .medium,
                source: .aiAnalysis
            ))
        }
        
        // DSOP optimization
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        let dsopRate = totalIncome > 0 ? totalDSOP / totalIncome : 0
        
        if dsopRate < 0.12 {
            recommendations.append(ProfessionalRecommendation(
                category: .investmentStrategy,
                title: "Optimize DSOP Contributions",
                summary: "Your DSOP contribution rate is \(String(format: "%.1f", dsopRate * 100))%",
                detailedAnalysis: "Increasing DSOP contributions can provide tax benefits and secure retirement planning.",
                actionSteps: [
                    "Consider increasing DSOP to maximum allowed",
                    "Understand employer matching benefits",
                    "Review investment options within DSOP",
                    "Calculate retirement fund projections",
                    "Consider additional voluntary contributions"
                ],
                potentialSavings: totalIncome * 0.05, // Tax savings from increased contributions
                priority: .medium,
                source: .aiAnalysis
            ))
        }
        
        return recommendations
    }
    
    private func generateSavingsRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        let estimatedSavings = netIncome * 0.30 // Estimated savings
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if savingsRate < Constants.optimalSavingsRate {
            let targetIncrease = (Constants.optimalSavingsRate - savingsRate) * totalIncome
            
            recommendations.append(ProfessionalRecommendation(
                category: .debtManagement,
                title: "Increase Savings Rate",
                summary: "Your estimated savings rate is \(String(format: "%.1f", savingsRate * 100))%, below the recommended 20%",
                detailedAnalysis: "Increasing your savings rate to 20% would provide better financial security and investment opportunities.",
                actionSteps: [
                    "Track all expenses for one month",
                    "Identify non-essential spending categories",
                    "Set up automatic transfers to savings",
                    "Use the 50/30/20 budgeting rule",
                    "Reduce subscription services and memberships",
                    "Cook more meals at home",
                    "Consider carpooling or public transport"
                ],
                potentialSavings: targetIncrease,
                priority: .high,
                source: .aiAnalysis
            ))
        }
        
        return recommendations
    }
    
    private func generateDeductionOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if deductionRatio > 0.35 { // High deduction ratio
            recommendations.append(ProfessionalRecommendation(
                category: .debtManagement,
                title: "Review Deduction Efficiency",
                summary: "Your total deductions are \(String(format: "%.1f", deductionRatio * 100))% of income",
                detailedAnalysis: "High deduction ratios may indicate opportunities for optimization or potential financial stress.",
                actionSteps: [
                    "Review all mandatory vs. optional deductions",
                    "Analyze loan EMI burden and consider prepayment",
                    "Review insurance premiums for optimization",
                    "Consider debt consolidation if applicable",
                    "Negotiate with service providers for better rates",
                    "Evaluate subscription services and memberships"
                ],
                potentialSavings: totalIncome * 0.05, // 5% potential savings
                priority: .medium,
                source: .aiAnalysis
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func calculateTaxVariation(payslips: [PayslipItem]) -> Double {
        let taxes = payslips.map { $0.tax }
        guard taxes.count > 1 else { return 0 }
        
        let mean = taxes.reduce(0, +) / Double(taxes.count)
        let variance = taxes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(taxes.count)
        
        return mean > 0 ? sqrt(variance) / mean : 0
    }
    
    private func calculateIncomeVolatility(payslips: [PayslipItem]) -> Double {
        let incomes = payslips.map { $0.credits }
        guard incomes.count > 1 else { return 0 }
        
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        
        return mean > 0 ? sqrt(variance) / mean : 0
    }
}

// MARK: - Extensions

extension ProfessionalRecommendation.Priority {
    var rawValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
} 
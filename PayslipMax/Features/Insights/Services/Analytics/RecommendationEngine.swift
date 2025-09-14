import Foundation

@MainActor
class RecommendationEngine {

    // MARK: - Dependencies

    private let taxOptimizationService: TaxOptimizationRecommendationsServiceProtocol
    private let careerGrowthService: CareerGrowthRecommendationsServiceProtocol

    init(
        taxOptimizationService: TaxOptimizationRecommendationsServiceProtocol = TaxOptimizationRecommendationsService(),
        careerGrowthService: CareerGrowthRecommendationsServiceProtocol = CareerGrowthRecommendationsService()
    ) {
        self.taxOptimizationService = taxOptimizationService
        self.careerGrowthService = careerGrowthService
    }
    
    // MARK: - Public Methods
    
    func generateProfessionalRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= RecommendationConstants.minimumDataPoints else {
            return createInsufficientDataRecommendations()
        }

        var recommendations: [ProfessionalRecommendation] = []

        // Generate different types of recommendations concurrently
        async let taxRecommendations = taxOptimizationService.generateTaxOptimizationRecommendations(payslips: payslips)
        async let careerRecommendations = careerGrowthService.generateCareerGrowthRecommendations(payslips: payslips)

        // TODO: Extract investment, savings, and deduction services when needed
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
    
    
    
    private func generateInvestmentRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate available for investment (assuming 70% goes to expenses)
        let availableForInvestment = netIncome * 0.30
        
        var recommendations: [ProfessionalRecommendation] = []
        
        if availableForInvestment > RecommendationConstants.minimumInvestmentThreshold {
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
        
        if dsopRate < RecommendationConstants.dsopOptimalRate {
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
        
        if savingsRate < RecommendationConstants.optimalSavingsRate {
            let targetIncrease = (RecommendationConstants.optimalSavingsRate - savingsRate) * totalIncome
            
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
        
        if deductionRatio > RecommendationConstants.highDeductionRatioThreshold { // High deduction ratio
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
    
}

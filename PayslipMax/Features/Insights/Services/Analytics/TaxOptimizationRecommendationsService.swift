import Foundation

/// Service responsible for generating tax optimization recommendations
protocol TaxOptimizationRecommendationsServiceProtocol {
    func generateTaxOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation]
}

/// Service responsible for generating tax optimization recommendations
class TaxOptimizationRecommendationsService: TaxOptimizationRecommendationsServiceProtocol {

    // MARK: - Dependencies

    private let calculationService: RecommendationCalculationServiceProtocol

    init(calculationService: RecommendationCalculationServiceProtocol = RecommendationCalculationService()) {
        self.calculationService = calculationService
    }

    /// Generates tax optimization recommendations based on payslip data
    func generateTaxOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let effectiveTaxRate = calculationService.calculateEffectiveTaxRate(payslips: payslips)
        let totalIncome = calculationService.calculateTotalIncome(payslips: payslips)

        var recommendations: [ProfessionalRecommendation] = []

        // Check for high tax rate
        if effectiveTaxRate > RecommendationConstants.optimalTaxRate {
            let potentialSavings = totalIncome * (effectiveTaxRate - RecommendationConstants.optimalTaxRate)

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
                priority: potentialSavings > RecommendationConstants.highPrioritySavingsThreshold ? .high : .medium,
                source: .aiAnalysis
            ))
        }

        // Check for tax variation
        let monthlyTaxVariation = calculationService.calculateTaxVariation(payslips: payslips)
        if monthlyTaxVariation > RecommendationConstants.taxVariationThreshold {
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
}

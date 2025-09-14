import Foundation

/// Service responsible for generating career growth recommendations
protocol CareerGrowthRecommendationsServiceProtocol {
    func generateCareerGrowthRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation]
}

/// Service responsible for generating career growth recommendations
class CareerGrowthRecommendationsService: CareerGrowthRecommendationsServiceProtocol {

    // MARK: - Dependencies

    private let calculationService: RecommendationCalculationServiceProtocol

    init(calculationService: RecommendationCalculationServiceProtocol = RecommendationCalculationService()) {
        self.calculationService = calculationService
    }

    /// Generates career growth recommendations based on payslip data
    func generateCareerGrowthRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= 6 else { return [] }

        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))

        let growthRate = calculationService.calculateGrowthRate(
            recentPayslips: recent6Months,
            previousPayslips: previous6Months
        )

        var recommendations: [ProfessionalRecommendation] = []

        // Check for low growth rate
        if growthRate < RecommendationConstants.goodGrowthRate {
            let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6

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

        // Check for income volatility
        let incomeVolatility = calculationService.calculateIncomeVolatility(payslips: payslips)
        if incomeVolatility > RecommendationConstants.incomeVolatilityThreshold {
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
}

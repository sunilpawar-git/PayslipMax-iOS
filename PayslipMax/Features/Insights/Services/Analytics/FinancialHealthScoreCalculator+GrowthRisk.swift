import Foundation

// MARK: - Growth & Risk Category Calculators

@MainActor
extension FinancialHealthScoreCalculator {

    func calculateGrowthCategory(payslips: [PayslipItem]) -> HealthCategory {
        guard payslips.count >= 6 else {
            return HealthCategory(name: "Income Growth", score: 50, weight: 0.15, status: .fair,
                                recommendation: "Need more data for growth analysis",
                                actionItems: [])
        }

        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))

        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage :
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)

        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0

        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String

        if growthRate > 0.10 {
            score = 95
            status = .excellent
            recommendation = "Exceptional income growth!"
        } else if growthRate > 0.05 {
            score = 80
            status = .good
            recommendation = "Strong income growth trend"
        } else if growthRate > 0 {
            score = 60
            status = .fair
            recommendation = "Modest growth, consider career advancement"
        } else {
            score = 30
            status = .poor
            recommendation = "Declining income - focus on skill development"
        }

        return HealthCategory(
            name: "Income Growth",
            score: score,
            weight: 0.15,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateGrowthActionItems(growthRate: growthRate)
        )
    }

    func calculateRiskCategory(payslips: [PayslipItem]) -> HealthCategory {
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean

        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0

        let riskScore = (volatility * 50) + (max(0, deductionRatio - 0.3) * 100)
        let healthScore = max(0, 100 - riskScore)

        let status: HealthCategory.HealthStatus
        let recommendation: String

        if healthScore > 80 {
            status = .excellent
            recommendation = "Low financial risk profile"
        } else if healthScore > 60 {
            status = .good
            recommendation = "Moderate risk, well managed"
        } else if healthScore > 40 {
            status = .fair
            recommendation = "Some risk factors need attention"
        } else {
            status = .poor
            recommendation = "High risk - needs immediate attention"
        }

        return HealthCategory(
            name: "Risk Management",
            score: healthScore,
            weight: 0.10,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateRiskActionItems(volatility: volatility, deductionRatio: deductionRatio)
        )
    }
}

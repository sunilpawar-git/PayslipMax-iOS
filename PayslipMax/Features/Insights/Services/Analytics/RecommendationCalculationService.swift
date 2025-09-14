import Foundation

/// Service responsible for financial calculations used in recommendations
protocol RecommendationCalculationServiceProtocol {
    func calculateTaxVariation(payslips: [PayslipItem]) -> Double
    func calculateIncomeVolatility(payslips: [PayslipItem]) -> Double
    func calculateEffectiveTaxRate(payslips: [PayslipItem]) -> Double
    func calculateTotalIncome(payslips: [PayslipItem]) -> Double
    func calculateTotalDeductions(payslips: [PayslipItem]) -> Double
    func calculateGrowthRate(recentPayslips: [PayslipItem], previousPayslips: [PayslipItem]) -> Double
}

/// Service responsible for financial calculations used in recommendations
class RecommendationCalculationService: RecommendationCalculationServiceProtocol {

    /// Calculates the coefficient of variation for tax amounts
    func calculateTaxVariation(payslips: [PayslipItem]) -> Double {
        let taxes = payslips.map { $0.tax }
        guard taxes.count > 1 else { return 0 }

        let mean = taxes.reduce(0, +) / Double(taxes.count)
        let variance = taxes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(taxes.count)

        return mean > 0 ? sqrt(variance) / mean : 0
    }

    /// Calculates the coefficient of variation for income amounts
    func calculateIncomeVolatility(payslips: [PayslipItem]) -> Double {
        let incomes = payslips.map { $0.credits }
        guard incomes.count > 1 else { return 0 }

        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)

        return mean > 0 ? sqrt(variance) / mean : 0
    }

    /// Calculates the effective tax rate across all payslips
    func calculateEffectiveTaxRate(payslips: [PayslipItem]) -> Double {
        let totalIncome = calculateTotalIncome(payslips: payslips)
        let totalTax = payslips.reduce(0) { $0 + $1.tax }

        return totalIncome > 0 ? totalTax / totalIncome : 0
    }

    /// Calculates total income across all payslips
    func calculateTotalIncome(payslips: [PayslipItem]) -> Double {
        return payslips.reduce(0) { $0 + $1.credits }
    }

    /// Calculates total deductions across all payslips
    func calculateTotalDeductions(payslips: [PayslipItem]) -> Double {
        return payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
    }

    /// Calculates growth rate between two periods
    func calculateGrowthRate(recentPayslips: [PayslipItem], previousPayslips: [PayslipItem]) -> Double {
        let recentAverage = recentPayslips.reduce(0) { $0 + $1.credits } / Double(recentPayslips.count)
        let previousAverage = previousPayslips.isEmpty ? recentAverage :
                             previousPayslips.reduce(0) { $0 + $1.credits } / Double(previousPayslips.count)

        return previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
    }
}

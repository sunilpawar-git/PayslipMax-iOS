import Foundation
import SwiftUI

/// Simple analytics service for basic financial insights
/// Replaces the massive AdvancedAnalyticsEngine with essential functionality only
@MainActor
class BasicAnalytics: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    
    // MARK: - Analytics Functions
    
    /// Calculates basic financial health score
    /// - Parameter payslips: Array of payslip items
    /// - Returns: Simple health score between 0-100
    func calculateHealthScore(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 3 else { return 50.0 }
        
        let recentPayslips = Array(payslips.prefix(6))
        
        // Income stability (40% weight)
        let stabilityScore = calculateIncomeStability(payslips: recentPayslips) * 0.4
        
        // Growth trend (30% weight)
        let growthScore = calculateGrowthTrend(payslips: recentPayslips) * 0.3
        
        // Deduction efficiency (30% weight)
        let deductionScore = calculateDeductionEfficiency(payslips: recentPayslips) * 0.3
        
        return min(100, max(0, stabilityScore + growthScore + deductionScore))
    }
    
    /// Generates basic financial insights
    /// - Parameter payslips: Array of payslip items
    /// - Returns: Array of simple insight strings
    func generateBasicInsights(payslips: [PayslipItem]) -> [String] {
        guard payslips.count >= 3 else {
            return ["Upload more payslips for better insights"]
        }
        
        var insights: [String] = []
        
        // Average income insight
        let avgIncome = payslips.reduce(0) { $0 + $1.credits } / Double(payslips.count)
        insights.append("Average monthly income: ₹\(Int(avgIncome))")
        
        // Tax efficiency
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let taxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        insights.append("Effective tax rate: \(String(format: "%.1f", taxRate * 100))%")
        
        // Growth trend
        if payslips.count >= 6 {
            let recent3 = Array(payslips.prefix(3))
            let previous3 = Array(payslips.dropFirst(3).prefix(3))
            
            let recentAvg = recent3.reduce(0) { $0 + $1.credits } / 3
            let previousAvg = previous3.reduce(0) { $0 + $1.credits } / 3
            
            let growth = previousAvg > 0 ? (recentAvg - previousAvg) / previousAvg : 0
            insights.append("Income trend: \(growth > 0 ? "+" : "")\(String(format: "%.1f", growth * 100))%")
        }
        
        return insights
    }
    
    // MARK: - Private Helpers
    
    private func calculateIncomeStability(payslips: [PayslipItem]) -> Double {
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = mean > 0 ? sqrt(variance) / mean : 1.0
        
        // Convert volatility to stability score (lower volatility = higher score)
        return max(0, 100 - (volatility * 200))
    }
    
    private func calculateGrowthTrend(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 2 else { return 50 }
        
        let sorted = payslips.sorted { $0.timestamp > $1.timestamp }
        let recent = sorted[0].credits
        let previous = sorted[1].credits
        
        let growth = previous > 0 ? (recent - previous) / previous : 0
        
        // Convert growth rate to score
        return max(0, min(100, 50 + (growth * 500))) // ±10% growth = ±50 points
    }
    
    private func calculateDeductionEfficiency(payslips: [PayslipItem]) -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        
        guard totalIncome > 0 else { return 50 }
        
        let deductionRatio = totalDeductions / totalIncome
        
        // Optimal deduction ratio is around 25-30%
        if deductionRatio < 0.20 {
            return 90 // Very efficient
        } else if deductionRatio < 0.35 {
            return 70 // Good
        } else if deductionRatio < 0.50 {
            return 40 // Fair
        } else {
            return 20 // High deductions
        }
    }
}

import Foundation
import SwiftUI

/// Handles AI-driven professional recommendations for tax optimization, career growth, and investment strategies
@MainActor
class ProfessionalRecommendationEngine: ObservableObject {
    
    // MARK: - Main Recommendations Generation
    
    func generateProfessionalRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        var recommendations: [ProfessionalRecommendation] = []
        
        // Tax optimization recommendations
        recommendations.append(contentsOf: await generateTaxOptimizationRecommendations(payslips: payslips))
        
        // Career growth recommendations
        recommendations.append(contentsOf: await generateCareerGrowthRecommendations(payslips: payslips))
        
        // Investment strategy recommendations
        recommendations.append(contentsOf: await generateInvestmentRecommendations(payslips: payslips))
        
        return recommendations
    }
    
    // MARK: - Tax Optimization Recommendations
    
    private func generateTaxOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        if effectiveRate > 0.25 {
            return [ProfessionalRecommendation(
                category: .taxOptimization,
                title: "High Tax Rate Optimization",
                summary: "Your effective tax rate of \(String(format: "%.1f", effectiveRate * 100))% is above average",
                detailedAnalysis: "Analysis shows potential for significant tax savings through strategic planning and deduction optimization.",
                actionSteps: [
                    "Review all available deductions and exemptions",
                    "Consider tax-saving investments under Section 80C",
                    "Evaluate salary restructuring opportunities",
                    "Consult with a tax professional for advanced strategies"
                ],
                potentialSavings: totalIncome * 0.05, // 5% potential savings
                priority: .high,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    // MARK: - Career Growth Recommendations
    
    private func generateCareerGrowthRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= 6 else { return [] }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        if growthRate < 0.03 { // Less than 3% growth
            return [ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Accelerate Career Progression",
                summary: "Your income growth of \(String(format: "%.1f", growthRate * 100))% is below industry average",
                detailedAnalysis: "Slow income growth may indicate opportunities for career advancement or skill development to increase earning potential.",
                actionSteps: [
                    "Identify key skills in demand in your field",
                    "Pursue relevant certifications or training",
                    "Network within your industry",
                    "Document and communicate your achievements",
                    "Consider lateral moves or role expansion"
                ],
                potentialSavings: recentAverage * 0.20, // 20% potential income increase
                priority: .medium,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    // MARK: - Investment Strategy Recommendations
    
    private func generateInvestmentRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate available for investment (assuming 70% goes to expenses)
        let availableForInvestment = netIncome * 0.30
        
        if availableForInvestment > 10000 { // Minimum threshold for investment advice
            return [ProfessionalRecommendation(
                category: .investmentStrategy,
                title: "Investment Opportunity Analysis",
                summary: "You have approximately ₹\(Int(availableForInvestment)) available for investments",
                detailedAnalysis: "Based on your income stability and risk profile, we recommend a diversified investment approach.",
                actionSteps: [
                    "Allocate 60% to equity mutual funds for long-term growth",
                    "Invest 30% in debt instruments for stability",
                    "Keep 10% in liquid funds for emergencies",
                    "Review and rebalance portfolio quarterly",
                    "Consider SIP for rupee cost averaging"
                ],
                potentialSavings: availableForInvestment * 0.12 * 5, // 12% annual returns over 5 years
                priority: .medium,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    // MARK: - Specialized Recommendation Types
    
    func generateEmergencyFundRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        let monthlyExpenses = netIncome * 0.70 / monthsOfData // Estimate 70% of net goes to expenses
        let recommendedEmergencyFund = monthlyExpenses * 6 // 6 months of expenses
        
        return [ProfessionalRecommendation(
            category: .emergencyFund,
            title: "Emergency Fund Strategy",
            summary: "Build an emergency fund of ₹\(Int(recommendedEmergencyFund)) (6 months expenses)",
            detailedAnalysis: "An emergency fund provides financial security and peace of mind during unexpected situations.",
            actionSteps: [
                "Open a separate high-yield savings account",
                "Automate monthly transfers of ₹\(Int(recommendedEmergencyFund / 12))",
                "Keep funds easily accessible but separate from daily banking",
                "Review and adjust target amount annually"
            ],
            potentialSavings: nil,
            priority: .high,
            source: .aiAnalysis
        )]
    }
    
    func generateDebtOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        
        if deductionRatio > 0.40 { // High deduction ratio may indicate debt burden
            return [ProfessionalRecommendation(
                category: .debtManagement,
                title: "High Deduction Analysis",
                summary: "Your deductions represent \(String(format: "%.1f", deductionRatio * 100))% of income",
                detailedAnalysis: "High deduction ratios may indicate opportunities for optimization or debt consolidation.",
                actionSteps: [
                    "Review all current deductions and their necessity",
                    "Consider debt consolidation for better rates",
                    "Prioritize high-interest debt payments",
                    "Negotiate with creditors for better terms",
                    "Create a debt reduction timeline"
                ],
                potentialSavings: totalIncome * 0.05, // 5% potential savings
                priority: .high,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    func generateRetirementPlanningRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        let dsopRate = totalIncome > 0 ? totalDSOP / totalIncome : 0
        
        if dsopRate < 0.12 { // Below recommended retirement savings rate
            return [ProfessionalRecommendation(
                category: .retirementPlanning,
                title: "Retirement Savings Enhancement",
                summary: "Your current retirement savings rate is \(String(format: "%.1f", dsopRate * 100))%",
                detailedAnalysis: "Financial experts recommend saving at least 12-15% of income for retirement.",
                actionSteps: [
                    "Increase DSOP contributions if possible",
                    "Consider additional retirement accounts (NPS, PPF)",
                    "Explore employer matching programs",
                    "Review investment allocation for growth",
                    "Calculate retirement income needs"
                ],
                potentialSavings: nil,
                priority: .medium,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
} 
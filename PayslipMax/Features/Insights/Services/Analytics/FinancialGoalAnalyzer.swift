import Foundation
import SwiftUI

/// Handles financial goal analysis and milestone tracking
@MainActor
class FinancialGoalAnalyzer: ObservableObject {
    
    // MARK: - Main Goal Analysis
    
    func analyzeMilestoneProgress(payslips: [PayslipItem]) async -> [FinancialGoal] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        // Emergency fund goal
        let monthlyExpenses = netIncome * 0.70 / monthsOfData // Estimate 70% of net goes to expenses
        let emergencyFundTarget = monthlyExpenses * 6 // 6 months of expenses
        let currentSavings = netIncome * 0.30 // Estimate current savings
        
        return [
            FinancialGoal(
                type: .emergencyFund,
                title: "Emergency Fund",
                targetAmount: emergencyFundTarget,
                currentAmount: currentSavings,
                targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                category: .shortTerm,
                isAchievable: true,
                recommendedMonthlyContribution: (emergencyFundTarget - currentSavings) / 12,
                projectedAchievementDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())
            )
        ]
    }
    
    // MARK: - Specific Goal Analysis
    
    func analyzeEmergencyFundGoal(payslips: [PayslipItem]) async -> FinancialGoal {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        let monthlyExpenses = netIncome * 0.70 / monthsOfData
        let emergencyFundTarget = monthlyExpenses * 6
        let estimatedCurrentSavings = netIncome * 0.30
        
        let monthlyContribution = (emergencyFundTarget - estimatedCurrentSavings) / 12
        let achievementMonths = emergencyFundTarget > estimatedCurrentSavings ? 
                               Int(ceil((emergencyFundTarget - estimatedCurrentSavings) / (monthlyContribution))) : 0
        
        return FinancialGoal(
            type: .emergencyFund,
            title: "Emergency Fund (6 months expenses)",
            targetAmount: emergencyFundTarget,
            currentAmount: estimatedCurrentSavings,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
            category: .shortTerm,
            isAchievable: achievementMonths <= 18, // Achievable within 18 months
            recommendedMonthlyContribution: monthlyContribution,
            projectedAchievementDate: Calendar.current.date(byAdding: .month, value: achievementMonths, to: Date())
        )
    }
    
    func analyzeRetirementGoal(payslips: [PayslipItem]) async -> FinancialGoal {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        let monthsOfData = Double(payslips.count)
        
        let annualDSOPContribution = totalDSOP * (12.0 / monthsOfData)
        let yearsToRetirement = 25.0
        let growthRate = 0.08
        
        // Future value calculation
        let futureValue = annualDSOPContribution * (pow(1 + growthRate, yearsToRetirement) - 1) / growthRate
        
        // Target retirement corpus (10x annual income)
        let annualIncome = totalIncome * (12.0 / monthsOfData)
        let retirementTarget = annualIncome * 10
        
        let additionalRequired = max(0, retirementTarget - futureValue)
        let additionalMonthlyContribution = additionalRequired > 0 ? 
                                          additionalRequired / (yearsToRetirement * 12) : 0
        
        return FinancialGoal(
            type: .retirementContribution,
            title: "Retirement Corpus",
            targetAmount: retirementTarget,
            currentAmount: futureValue,
            targetDate: Calendar.current.date(byAdding: .year, value: Int(yearsToRetirement), to: Date()) ?? Date(),
            category: .longTerm,
            isAchievable: additionalMonthlyContribution < (annualIncome * 0.1 / 12), // Achievable if <10% of income
            recommendedMonthlyContribution: additionalMonthlyContribution,
            projectedAchievementDate: Calendar.current.date(byAdding: .year, value: Int(yearsToRetirement), to: Date())
        )
    }
    
    func analyzeHomePurchaseGoal(targetAmount: Double, payslips: [PayslipItem]) async -> FinancialGoal {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        let monthlySavings = netIncome * 0.30 / monthsOfData
        let downPayment = targetAmount * 0.20 // 20% down payment
        
        let monthsToSave = monthlySavings > 0 ? Int(ceil(downPayment / monthlySavings)) : 999
        
        return FinancialGoal(
            type: .majorPurchase,
            title: "Home Purchase (Down Payment)",
            targetAmount: downPayment,
            currentAmount: 0, // Assume starting from zero
            targetDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date(),
            category: .mediumTerm,
            isAchievable: monthsToSave <= 60, // Achievable within 5 years
            recommendedMonthlyContribution: monthlySavings,
            projectedAchievementDate: Calendar.current.date(byAdding: .month, value: monthsToSave, to: Date())
        )
    }
    
    func analyzeEducationGoal(targetAmount: Double, payslips: [PayslipItem]) async -> FinancialGoal {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        let monthlySavings = netIncome * 0.15 / monthsOfData // Allocate 15% for education
        let monthsToSave = monthlySavings > 0 ? Int(ceil(targetAmount / monthlySavings)) : 999
        
        return FinancialGoal(
            type: .education,
            title: "Education Fund",
            targetAmount: targetAmount,
            currentAmount: 0,
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date(),
            category: .shortTerm,
            isAchievable: monthsToSave <= 36, // Achievable within 3 years
            recommendedMonthlyContribution: monthlySavings,
            projectedAchievementDate: Calendar.current.date(byAdding: .month, value: monthsToSave, to: Date())
        )
    }
    
    // MARK: - Goal Progress Tracking
    
    func calculateGoalProgress(goal: FinancialGoal) async -> Double {
        return goal.targetAmount > 0 ? min(1.0, goal.currentAmount / goal.targetAmount) : 0.0
    }
    
    func calculateTimeToGoal(goal: FinancialGoal) async -> Int {
        let remaining = goal.targetAmount - goal.currentAmount
        return goal.recommendedMonthlyContribution > 0 ? 
               Int(ceil(remaining / goal.recommendedMonthlyContribution)) : 999
    }
    
    func isGoalOnTrack(goal: FinancialGoal) async -> Bool {
        let timeElapsed = Date().timeIntervalSince(goal.targetDate.addingTimeInterval(-365*24*60*60)) // Assume 1 year goal
        let totalTime: TimeInterval = 365*24*60*60 // 1 year
        let expectedProgress = timeElapsed / totalTime
        let actualProgress = await calculateGoalProgress(goal: goal)
        
        return actualProgress >= expectedProgress * 0.9 // Allow 10% variance
    }
    
    // MARK: - Goal Recommendations
    
    func generateGoalRecommendations(payslips: [PayslipItem]) async -> [String] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let savingsRate = totalIncome > 0 ? (netIncome * 0.30) / totalIncome : 0
        
        var recommendations: [String] = []
        
        if savingsRate < 0.15 {
            recommendations.append("Increase your savings rate to at least 15% to achieve financial goals faster")
        }
        
        if savingsRate >= 0.20 {
            recommendations.append("Great savings rate! Consider diversifying into different goal categories")
        }
        
        recommendations.append("Set up automatic transfers to dedicated goal accounts")
        recommendations.append("Review and adjust goals quarterly based on income changes")
        recommendations.append("Consider tax-advantaged accounts for long-term goals")
        
        return recommendations
    }
    
    func prioritizeGoals(goals: [FinancialGoal]) async -> [FinancialGoal] {
        return goals.sorted { goal1, goal2 in
            // Priority: Emergency fund > Short-term > Medium-term > Long-term
            let priority1 = goalPriority(goal1)
            let priority2 = goalPriority(goal2)
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // If same priority, sort by achievability and target date
            if goal1.isAchievable != goal2.isAchievable {
                return goal1.isAchievable && !goal2.isAchievable
            }
            
            return goal1.targetDate < goal2.targetDate
        }
    }
    
    private func goalPriority(_ goal: FinancialGoal) -> Int {
        switch goal.type {
        case .emergencyFund: return 1
        case .education: return 2
        case .majorPurchase: return 3
        case .retirementContribution: return 4
        case .savings: return 5
        case .investment: return 6
        case .debtPayoff: return 7
        }
    }
} 
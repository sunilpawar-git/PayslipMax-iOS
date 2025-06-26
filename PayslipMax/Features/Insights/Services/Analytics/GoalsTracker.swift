import Foundation

@MainActor
class GoalsTracker {
    // MARK: - Constants
    private struct Constants {
        static let minimumDataPoints = 3
        static let emergencyFundMonths = 6.0
        static let optimalSavingsRate = 0.20
        static let targetTaxRate = 0.15
        static let targetGrowthRate = 0.10
    }
    
    // MARK: - Public Methods
    func trackFinancialGoals(payslips: [PayslipItem]) async -> [FinancialGoal] {
        guard payslips.count >= Constants.minimumDataPoints else { return [] }
        
        var goals: [FinancialGoal] = []
        
        // Emergency Fund Goal
        if let emergencyGoal = await createEmergencyFundGoal(payslips: payslips) {
            goals.append(emergencyGoal)
        }
        
        // Savings Goal
        if let savingsGoal = await createSavingsGoal(payslips: payslips) {
            goals.append(savingsGoal)
        }
        
        // Retirement Goal
        if let retirementGoal = await createRetirementGoal(payslips: payslips) {
            goals.append(retirementGoal)
        }
        
        // Investment Goal
        if let investmentGoal = await createInvestmentGoal(payslips: payslips) {
            goals.append(investmentGoal)
        }
        
        return goals
    }
    
    // MARK: - Private Methods
    private func createEmergencyFundGoal(payslips: [PayslipItem]) async -> FinancialGoal? {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        // Calculate monthly expenses (assuming 70% of net income)
        let monthlyExpenses = (netIncome / monthsOfData) * 0.70
        let emergencyFundTarget = monthlyExpenses * Constants.emergencyFundMonths
        
        // Estimate current savings (30% of net income)
        let currentSavings = (netIncome / monthsOfData) * 0.30 * monthsOfData
        
        // Calculate target date (assuming current savings rate)
        let monthlySavingsRate = (netIncome / monthsOfData) * 0.30
        let monthsToGoal = monthlySavingsRate > 0 ? max(0, (emergencyFundTarget - currentSavings) / monthlySavingsRate) : 12
        let targetDate = Calendar.current.date(byAdding: .month, value: Int(monthsToGoal), to: Date()) ?? Date()
        
        // Determine goal category based on time to completion
        let category: FinancialGoal.GoalCategory
        if monthsToGoal <= 12 {
            category = .shortTerm
        } else if monthsToGoal <= 36 {
            category = .mediumTerm
        } else {
            category = .longTerm
        }
        
        let isAchievable = monthsToGoal <= 60 // Achievable within 5 years
        let projectedDate = isAchievable ? targetDate : nil
        
        return FinancialGoal(
            type: .emergencyFund,
            title: "Emergency Fund",
            targetAmount: emergencyFundTarget,
            currentAmount: max(0, currentSavings),
            targetDate: targetDate,
            category: category,
            isAchievable: isAchievable,
            recommendedMonthlyContribution: monthlySavingsRate,
            projectedAchievementDate: projectedDate
        )
    }
    
    private func createSavingsGoal(payslips: [PayslipItem]) async -> FinancialGoal? {
        let annualIncome = calculateAnnualizedIncome(payslips: payslips)
        let currentSavingsRate = calculateCurrentSavingsRate(payslips: payslips)
        
        // Target: 20% savings rate
        let targetSavingsAmount = annualIncome * Constants.optimalSavingsRate
        let currentSavingsAmount = annualIncome * currentSavingsRate
        
        let monthlySavingsNeeded = (targetSavingsAmount - currentSavingsAmount) / 12
        let monthsToGoal = monthlySavingsNeeded > 0 ? 12.0 : 0 // Goal to achieve in 1 year
        
        let targetDate = Calendar.current.date(byAdding: .month, value: Int(monthsToGoal), to: Date()) ?? Date()
        
        return FinancialGoal(
            type: .savings,
            title: "Optimal Savings Rate",
            targetAmount: targetSavingsAmount,
            currentAmount: currentSavingsAmount,
            targetDate: targetDate,
            category: .shortTerm,
            isAchievable: true,
            recommendedMonthlyContribution: max(0, monthlySavingsNeeded),
            projectedAchievementDate: targetDate
        )
    }
    
    private func createRetirementGoal(payslips: [PayslipItem]) async -> FinancialGoal? {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        let monthsOfData = Double(payslips.count)
        
        let annualIncome = (totalIncome / monthsOfData) * 12
        let currentDSOPContribution = (totalDSOP / monthsOfData) * 12
        
        // Target: 12% DSOP contribution
        let targetDSOPContribution = annualIncome * 0.12
        let additionalContributionNeeded = max(0, targetDSOPContribution - currentDSOPContribution)
        
        // Project to retirement (assuming 25 years)
        let targetDate = Calendar.current.date(byAdding: .year, value: 25, to: Date()) ?? Date()
        
        return FinancialGoal(
            type: .retirementContribution,
            title: "Retirement Fund",
            targetAmount: targetDSOPContribution,
            currentAmount: currentDSOPContribution,
            targetDate: targetDate,
            category: .longTerm,
            isAchievable: true,
            recommendedMonthlyContribution: additionalContributionNeeded / 12,
            projectedAchievementDate: targetDate
        )
    }
    
    private func createInvestmentGoal(payslips: [PayslipItem]) async -> FinancialGoal? {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        // Target: invest 10% of net income
        let monthlyNetIncome = netIncome / monthsOfData
        let targetMonthlyInvestment = monthlyNetIncome * 0.10
        let targetAnnualInvestment = targetMonthlyInvestment * 12
        
        // Assume current investment is 50% of target
        let currentInvestment = targetAnnualInvestment * 0.50
        
        let targetDate = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        
        return FinancialGoal(
            type: .investment,
            title: "Investment Portfolio",
            targetAmount: targetAnnualInvestment,
            currentAmount: currentInvestment,
            targetDate: targetDate,
            category: .mediumTerm,
            isAchievable: true,
            recommendedMonthlyContribution: targetMonthlyInvestment,
            projectedAchievementDate: targetDate
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateAnnualizedIncome(payslips: [PayslipItem]) -> Double {
        let monthlyAverage = payslips.reduce(0) { $0 + $1.credits } / Double(payslips.count)
        return monthlyAverage * 12
    }
    
    private func calculateCurrentSavingsRate(payslips: [PayslipItem]) -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate savings as 30% of net income
        let estimatedSavings = netIncome * 0.30
        
        return totalIncome > 0 ? estimatedSavings / totalIncome : 0
    }
    
    private func calculateGrowthRate(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 6 else { return 0 }
        
        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
        let recent6Months = Array(sortedPayslips.suffix(6))
        let previous6Months = Array(sortedPayslips.dropLast(6).suffix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        return previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
    }
} 
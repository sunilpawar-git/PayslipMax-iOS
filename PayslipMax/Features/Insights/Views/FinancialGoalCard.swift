import SwiftUI

// MARK: - Financial Goal Card

struct FinancialGoalCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text(goalTypeText)
                        .font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
                
                Spacer()
                
                Text("\(Int(goal.progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 1.0), value: goal.progress)
                }
            }
            .frame(height: 8)
            
            // Goal details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Text("₹\(formatAmount(goal.currentAmount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Text("₹\(formatAmount(goal.targetAmount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }
            
            // Target date and time remaining
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(FintechColors.primaryBlue)
                    .font(.caption)
                
                Text("Target: \(formattedDate(goal.targetDate))")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                
                Spacer()
                
                Text(timeRemainingText(to: goal.targetDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(timeRemainingColor(to: goal.targetDate))
            }
            
            // Recommended monthly contribution
            if goal.recommendedMonthlyContribution > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(FintechColors.primaryBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended monthly contribution")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Text("₹\(Int(goal.recommendedMonthlyContribution))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.primaryBlue)
                    }
                    
                    Spacer()
                }
            }
            
            // Goal achievability indicator
            HStack {
                Image(systemName: goal.isAchievable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(goal.isAchievable ? .green : .orange)
                    .font(.caption)
                
                Text(goal.isAchievable ? "Goal is achievable" : "Review target date")
                    .font(.caption)
                    .foregroundColor(goal.isAchievable ? .green : .orange)
                    .fontWeight(.medium)
            }
        }
        .fintechCardStyle()
    }
    
    private var goalTypeText: String {
        switch goal.type {
        case .savings: return "Savings Goal"
        case .investment: return "Investment Goal"
        case .emergencyFund: return "Emergency Fund"
        case .retirementContribution: return "Retirement"
        case .debtPayoff: return "Debt Payoff"
        case .majorPurchase: return "Major Purchase"
        case .education: return "Education"
        }
    }
    
    private var progressColor: Color {
        if goal.progress >= 0.8 { return .green }
        else if goal.progress >= 0.5 { return FintechColors.primaryBlue }
        else if goal.progress >= 0.2 { return .orange }
        else { return .red }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 100000 {
            return String(format: "%.1fL", amount / 100000)
        } else if amount >= 1000 {
            return String(format: "%.1fK", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func timeRemainingText(to date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: Date(), to: date)
        
        if let months = components.month, months > 0 {
            return "\(months) months left"
        } else if let days = components.day, days > 0 {
            return "\(days) days left"
        } else {
            return "Due soon"
        }
    }
    
    private func timeRemainingColor(to date: Date) -> Color {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysRemaining > 60 { return .green }
        else if daysRemaining > 30 { return .orange }
        else { return .red }
    }
}



// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FinancialGoalCard(goal: FinancialGoal(
            type: .emergencyFund,
            title: "Emergency Fund",
            targetAmount: 300000,
            currentAmount: 150000,
            targetDate: Calendar.current.date(byAdding: .month, value: 8, to: Date()) ?? Date(),
            category: .mediumTerm,
            isAchievable: true,
            recommendedMonthlyContribution: 20000,
            projectedAchievementDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())
        ))
        
        FinancialGoalCard(goal: FinancialGoal(
            type: .retirementContribution,
            title: "Retirement Fund",
            targetAmount: 2000000,
            currentAmount: 500000,
            targetDate: Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date(),
            category: .longTerm,
            isAchievable: true,
            recommendedMonthlyContribution: 15000,
            projectedAchievementDate: Calendar.current.date(byAdding: .year, value: 10, to: Date())
        ))
    }
    .padding()
} 
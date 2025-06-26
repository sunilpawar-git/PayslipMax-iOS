import SwiftUI

// MARK: - Premium Goals Section

struct PremiumGoalsSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            if analyticsEngine.financialGoals.isEmpty {
                PremiumEmptyStateView(
                    icon: "target",
                    title: "No Goals Set",
                    description: "Upload more payslips to track financial goals"
                )
            } else {
                ForEach(analyticsEngine.financialGoals, id: \.id) { goal in
                    FinancialGoalCard(goal: goal)
                }
            }
        }
    }
} 
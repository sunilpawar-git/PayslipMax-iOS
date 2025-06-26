import SwiftUI

// MARK: - Premium Health Score Section

struct PremiumHealthScoreSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            if let healthScore = analyticsEngine.financialHealthScore {
                // Overall score
                HealthScoreCard(healthScore: healthScore)
                
                // Categories breakdown
                ForEach(healthScore.categories, id: \.name) { category in
                    HealthCategoryCard(category: category)
                }
            } else {
                PremiumEmptyStateView(
                    icon: "heart.circle",
                    title: "Calculating Health Score",
                    description: "Upload more payslips for accurate analysis"
                )
            }
        }
    }
} 
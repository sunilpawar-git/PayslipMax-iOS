import SwiftUI

// MARK: - Premium Overview Section

struct PremiumOverviewSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    @ObservedObject var subscriptionManager: SubscriptionManager
    let showPaywall: Binding<Bool>
    
    var body: some View {
        VStack(spacing: 20) {
            // Financial Health Score Overview
            if let healthScore = analyticsEngine.financialHealthScore {
                FinancialHealthOverviewCard(healthScore: healthScore)
            }
            
            // Top Insights Preview
            TopInsightsPreviewCard(insights: [
                "AI predicts 12% income growth next year",
                "Tax efficiency above industry average",
                "Recommended: Increase DSOP by ₹5K monthly"
            ])
            
            // Upgrade prompt for free users
            if !subscriptionManager.isPremiumUser {
                UpgradePromptCard {
                    showPaywall.wrappedValue = true
                }
            }
        }
    }
} 
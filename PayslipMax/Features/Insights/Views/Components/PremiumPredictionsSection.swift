import SwiftUI

// MARK: - Premium Predictions Section

struct PremiumPredictionsSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            if analyticsEngine.predictiveInsights.isEmpty {
                PremiumEmptyStateView(
                    icon: "crystal.ball",
                    title: "No Predictions Available",
                    description: "Upload more payslips to generate predictive insights"
                )
            } else {
                ForEach(analyticsEngine.predictiveInsights, id: \.id) { insight in
                    PredictiveInsightCard(insight: insight)
                }
            }
        }
    }
} 
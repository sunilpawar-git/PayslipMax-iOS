import SwiftUI

// MARK: - Premium Recommendations Section

struct PremiumRecommendationsSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            if analyticsEngine.professionalRecommendations.isEmpty {
                PremiumEmptyStateView(
                    icon: "lightbulb",
                    title: "No Recommendations",
                    description: "Upload more payslips to get personalized recommendations"
                )
            } else {
                ForEach(analyticsEngine.professionalRecommendations, id: \.id) { recommendation in
                    ProfessionalRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
} 
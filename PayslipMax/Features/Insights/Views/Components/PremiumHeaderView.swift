import SwiftUI

// MARK: - Premium Header View

struct PremiumHeaderView: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    @ObservedObject var subscriptionManager: SubscriptionManager
    let payslips: [PayslipItem]
    let showPaywall: Binding<Bool>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Text("Premium Insights")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                    
                    Text("AI-powered financial intelligence")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
                
                if !subscriptionManager.isPremiumUser {
                    Button("Upgrade") {
                        showPaywall.wrappedValue = true
                    }
                    .buttonStyle(PremiumButtonStyle())
                }
            }
            
            // Quick stats if user has data
            if !payslips.isEmpty {
                quickStatsView
            }
        }
        .fintechCardStyle()
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            PremiumQuickStatCard(
                title: "Financial Health",
                value: "\(Int(analyticsEngine.financialHealthScore?.overallScore ?? 0))",
                suffix: "/100",
                color: healthScoreColor,
                icon: "heart.circle.fill"
            )
            
            PremiumQuickStatCard(
                title: "Risk Level",
                value: riskLevelText,
                suffix: "",
                color: riskLevelColor,
                icon: "shield.fill"
            )
            
            PremiumQuickStatCard(
                title: "Insights",
                value: "\(analyticsEngine.predictiveInsights.count + analyticsEngine.professionalRecommendations.count)",
                suffix: " items",
                color: FintechColors.primaryBlue,
                icon: "lightbulb.fill"
            )
        }
    }
    
    private var healthScoreColor: Color {
        guard let score = analyticsEngine.financialHealthScore?.overallScore else { return .gray }
        
        if score >= 80 { return .green }
        else if score >= 60 { return FintechColors.primaryBlue }
        else if score >= 40 { return .orange }
        else { return .red }
    }
    
    private var riskLevelText: String {
        guard let metrics = analyticsEngine.advancedMetrics else { return "N/A" }
        
        if metrics.financialRiskScore < 30 { return "Low" }
        else if metrics.financialRiskScore < 60 { return "Medium" }
        else { return "High" }
    }
    
    private var riskLevelColor: Color {
        guard let metrics = analyticsEngine.advancedMetrics else { return .gray }
        
        if metrics.financialRiskScore < 30 { return .green }
        else if metrics.financialRiskScore < 60 { return .orange }
        else { return .red }
    }
} 
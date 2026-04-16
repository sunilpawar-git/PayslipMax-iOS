import SwiftUI

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FinancialHealthOverviewCard(healthScore: FinancialHealthScore(
            overallScore: 85.0,
            categories: [
                HealthCategory(name: "Savings", score: 90, weight: 0.3, status: .excellent, recommendation: "Great", actionItems: []),
                HealthCategory(name: "Tax Efficiency", score: 75, weight: 0.2, status: .good, recommendation: "Good", actionItems: [])
            ],
            trend: .improving(5.2),
            lastUpdated: Date()
        ))
        HealthScoreCard(healthScore: FinancialHealthScore(
            overallScore: 85.0,
            categories: [
                HealthCategory(name: "Savings", score: 90, weight: 0.3, status: .excellent, recommendation: "Great", actionItems: []),
                HealthCategory(name: "Tax Efficiency", score: 75, weight: 0.2, status: .good, recommendation: "Good", actionItems: [])
            ],
            trend: .improving(5.2),
            lastUpdated: Date()
        ))
    }
    .padding()
}

import SwiftUI

/// Key insights section component for InsightsView
struct InsightsKeyInsightsSection: View {
    @ObservedObject var coordinator: InsightsCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            VStack(spacing: 16) {
                // Earnings Section
                if !coordinator.earningsInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(FintechColors.successGreen)
                                .font(.caption)

                            Text("Earnings")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            ForEach(coordinator.earningsInsights, id: \.title) { insight in
                                ClickableInsightCard(insight: insight)
                            }
                        }
                    }
                }

                // Subtle divider between sections
                if !coordinator.earningsInsights.isEmpty && !coordinator.deductionsInsights.isEmpty {
                    Divider()
                        .background(FintechColors.divider.opacity(0.3))
                        .padding(.vertical, 4)
                }

                // Deductions Section
                if !coordinator.deductionsInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(FintechColors.warningAmber)
                                .font(.caption)

                            Text("Deductions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            ForEach(coordinator.deductionsInsights, id: \.title) { insight in
                                ClickableInsightCard(insight: insight)
                            }
                        }
                    }
                }
            }
        }
        .fintechCardStyle()
    }
}

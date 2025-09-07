import SwiftUI

/// Detailed analysis section component for InsightsView
struct InsightsDetailedAnalysisSection: View {
    @ObservedObject var coordinator: InsightsCoordinator

    var body: some View {
        VStack(spacing: 16) {
            // Top earnings/deductions
            topCategoriesCard
        }
    }

    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            VStack(spacing: 8) {
                ForEach(coordinator.financialSummary.topEarnings.prefix(3), id: \.category) { item in
                    InsightsCategoryRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: FintechColors.successGreen,
                        isIncome: true
                    )
                }

                Divider()
                    .background(FintechColors.divider)

                ForEach(coordinator.financialSummary.topDeductions.prefix(3), id: \.category) { item in
                    InsightsCategoryRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: FintechColors.dangerRed,
                        isIncome: false
                    )
                }
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Supporting Components

struct InsightsCategoryRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    let isIncome: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)

                Text("\(percentage, specifier: "%.1f")% of \(isIncome ? "credits" : "deductions")")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }

            Spacer()

            Text("₹\(Formatters.formatIndianCurrency(amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

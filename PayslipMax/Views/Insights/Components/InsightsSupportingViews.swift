import SwiftUI

// MARK: - Supporting Views for Insights

struct InsightsInsightCard: View {
    let insight: InsightItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: insight.iconName)
                    .foregroundColor(insight.color)
                    .font(.system(size: 18, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

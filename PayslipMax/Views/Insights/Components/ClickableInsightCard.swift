import SwiftUI

struct ClickableInsightCard: View {
    let insight: InsightItem
    @State private var showingDetail = false

    var body: some View {
        Button {
            if insight.hasDetails {
                showingDetail = true
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(insight.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: insight.iconName)
                        .foregroundColor(insight.color)
                        .font(.system(size: 18, weight: .medium))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Clickable indicator
                if insight.hasDetails {
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)

                        Text("Details")
                            .font(.caption2)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!insight.hasDetails)
        .sheet(isPresented: $showingDetail) {
            InsightDetailView(insight: insight)
        }
        .accessibilityIdentifier("insight_card")
        .accessibilityLabel("\(insight.title). \(insight.description)")
        .accessibilityHint(insight.hasDetails ? "Tap to view detailed breakdown" : "")
    }
}

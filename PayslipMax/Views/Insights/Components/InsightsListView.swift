import SwiftUI

struct InsightsListView: View {
    let insights: [InsightItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            if insights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text("No insights available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("Upload more payslips to generate personalized financial insights")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(insights, id: \.title) { insight in
                    InsightRowView(insight: insight)
                }
            }
        }
        .fintechCardStyle()
    }
}

struct InsightRowView: View {
    let insight: InsightItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: insight.iconName)
                    .font(.title2)
                    .foregroundColor(insight.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    InsightsListView(insights: [
        InsightItem(
            title: "Income Trend", 
            description: "Your income has increased by 15% compared to last month", 
            iconName: "arrow.up.right", 
            color: FintechColors.successGreen
        ),
        InsightItem(
            title: "Tax Optimization", 
            description: "You could save more by optimizing your tax deductions", 
            iconName: "building.columns", 
            color: FintechColors.primaryBlue
        )
    ])
} 
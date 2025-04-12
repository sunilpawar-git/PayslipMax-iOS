import SwiftUI

struct InsightsListView: View {
    let insights: [InsightItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
            
            if insights.isEmpty {
                Text("Not enough data to generate insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(insights, id: \.title) { insight in
                    HStack(spacing: 16) {
                        Image(systemName: insight.iconName)
                            .font(.title2)
                            .foregroundColor(insight.color)
                            .frame(width: 40, height: 40)
                            .background(insight.color.opacity(0.2))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(.headline)
                            
                            Text(insight.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    InsightsListView(insights: [
        InsightItem(
            title: "Income Trend", 
            description: "Your income has increased by 15% compared to last month", 
            iconName: "arrow.up.right", 
            color: .green
        ),
        InsightItem(
            title: "Tax Optimization", 
            description: "You could save more by optimizing your tax deductions", 
            iconName: "building.columns", 
            color: .blue
        )
    ])
} 
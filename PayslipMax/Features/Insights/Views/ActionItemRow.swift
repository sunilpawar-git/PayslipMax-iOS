import SwiftUI

// MARK: - Action Item Row Component

struct ActionItemRow: View {
    let item: ActionItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            // Action content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("Impact: +\(String(format: "%.1f", item.estimatedImpact)) points")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Timeframe indicator  
            Text(item.timeframe)
                .font(.caption2)
                .foregroundColor(FintechColors.primaryBlue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(FintechColors.primaryBlue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
    }
    
    private var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ActionItemRow(item: ActionItem(
            title: "Increase DSOP contribution",
            description: "Boost your savings rate by 2%",
            priority: .high,
            category: .savings,
            estimatedImpact: 15.0,
            timeframe: "1-2 months"
        ))
        
        ActionItemRow(item: ActionItem(
            title: "Review tax deductions",
            description: "Optimize under Section 80C",
            priority: .medium,
            category: .tax,
            estimatedImpact: 10.5,
            timeframe: "Next month"
        ))
    }
    .padding()
} 
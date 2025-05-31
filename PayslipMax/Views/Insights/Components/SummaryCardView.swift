import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                TrendBadge(changePercent: trend)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
            }
        }
        .padding()
        .frame(width: 160, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SummaryCard(
        title: "Total Income",
        value: "₹50,000",
        trend: 5.2,
        icon: "arrow.up.right",
        color: FintechColors.successGreen
    )
} 
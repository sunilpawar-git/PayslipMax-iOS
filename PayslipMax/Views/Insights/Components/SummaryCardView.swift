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

// MARK: - Shared Trend Badge Component

struct TrendBadge: View {
    let changePercent: Double
    
    private var isPositive: Bool { changePercent >= 0 }
    private var color: Color { 
        isPositive ? FintechColors.successGreen : FintechColors.dangerRed 
    }
    private var icon: String { 
        isPositive ? "arrow.up" : "arrow.down" 
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text("\(abs(changePercent), specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
} 
import SwiftUI

// MARK: - Top Insights Preview Card

struct TopInsightsPreviewCard: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Top Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Text("PREVIEW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FintechColors.primaryBlue.opacity(0.15))
                    .foregroundColor(FintechColors.primaryBlue)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { index, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(FintechColors.primaryBlue)
                            .clipShape(Circle())
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Unlock premium message
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(FintechColors.primaryBlue)
                    .font(.caption)
                
                Text("Unlock all insights with Premium")
                    .font(.caption)
                    .foregroundColor(FintechColors.primaryBlue)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    // Handle premium upgrade
                }) {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(FintechColors.primaryBlue)
                        .cornerRadius(8)
                }
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Preview

#Preview {
    TopInsightsPreviewCard(insights: [
        "Your tax efficiency is above average at 22.5%",
        "Consider increasing DSOP contribution by ₹5,000",
        "Projected income growth of 12% over next year"
    ])
    .padding()
} 
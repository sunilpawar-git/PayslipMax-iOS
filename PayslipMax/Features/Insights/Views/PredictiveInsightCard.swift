import SwiftUI

// MARK: - Predictive Insight Card

struct PredictiveInsightCard: View {
    let insight: PredictiveInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    HStack {
                        Text(timeframeText)
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(FintechColors.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                                .font(.caption)
                            Text("\(Int(insight.confidence * 100))% confident")
                                .font(.caption)
                        }
                        .foregroundColor(FintechColors.primaryBlue)
                    }
                }
                
                Spacer()
                
                // Risk level indicator
                RiskLevelBadge(risk: insight.riskLevel)
            }
            
            // Description with value highlight
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textPrimary)
                
                if let expectedValue = insight.expectedValue {
                    HStack {
                        Text("Expected Value:")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Text("₹\(formatValue(expectedValue))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.primaryBlue)
                    }
                }
            }
            
            // AI-powered prediction indicator
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(FintechColors.primaryBlue)
                    .font(.subheadline)
                
                Text("AI-powered prediction")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .italic()
            }
            
            // Recommendation with action
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.recommendation)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Button(action: {
                        // Handle action - placeholder
                    }) {
                        Text("Take Action")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(FintechColors.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(FintechColors.primaryBlue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .fintechCardStyle()
    }
    
    private var timeframeText: String {
        switch insight.timeframe {
        case .nextMonth: return "Next Month"
        case .nextQuarter: return "Next Quarter"
        case .nextYear: return "Next Year"
        case .fiveYears: return "5 Years"
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100000 {
            return String(format: "%.1fL", value / 100000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    

}

// MARK: - Preview

#Preview {
    PredictiveInsightCard(insight: PredictiveInsight(
        type: .salaryGrowth,
        title: "Income Growth Prediction",
        description: "Based on your career trajectory and market trends, your income is expected to grow steadily.",
        confidence: 0.85,
        timeframe: .nextYear,
        expectedValue: 75000,
        recommendation: "Consider increasing your DSOP contribution by 2% to maximize long-term wealth building.",
        riskLevel: .low
    ))
    .padding()
} 
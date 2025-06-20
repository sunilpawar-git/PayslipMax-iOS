import SwiftUI

// MARK: - Professional Recommendation Card

struct ProfessionalRecommendationCard: View {
    let recommendation: ProfessionalRecommendation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.title)
                            .font(.headline)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        Spacer()
                        
                        RecommendationPriorityBadge(priority: recommendation.priority)
                    }
                    
                    Text(categoryText)
                        .font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
            }
            
            // Expert source
            HStack(spacing: 8) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundColor(FintechColors.primaryBlue)
                    .font(.caption)
                
                Text("Source: \(sourceText)")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            // Summary
            Text(recommendation.summary)
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
            
            // Potential savings highlight
            if let savings = recommendation.potentialSavings {
                HStack {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Potential savings: ₹\(formatSavings(savings))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            // Toggle for detailed view
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "View Action Plan")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.primaryBlue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(FintechColors.primaryBlue)
                        .font(.caption)
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // Detailed description
                    VStack(alignment: .leading, spacing: 8) {
                                                Text("Detailed Analysis")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        Text(recommendation.detailedAnalysis)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    
                    // Action steps
                    if !recommendation.actionSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Action Steps")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                            
                            ForEach(Array(recommendation.actionSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(FintechColors.primaryBlue)
                                        .clipShape(Circle())
                                    
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundColor(FintechColors.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Source information
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(FintechColors.primaryBlue)
                        
                        Text("Analysis source: \(sourceText)")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                }
            }
        }
        .fintechCardStyle()
    }
    
    private var categoryText: String {
        switch recommendation.category {
        case .taxOptimization: return "Tax Optimization"
        case .careerGrowth: return "Career Growth"
        case .investmentStrategy: return "Investment Strategy"
        case .retirementPlanning: return "Retirement Planning"
        case .emergencyFund: return "Emergency Fund"
        case .debtManagement: return "Debt Management"
        case .salaryNegotiation: return "Salary Negotiation"
        case .benefitsOptimization: return "Benefits Optimization"
        }
    }
    
    private var sourceText: String {
        switch recommendation.source {
        case .aiAnalysis: return "AI Analysis"
        case .industryBenchmark: return "Industry Benchmark"
        case .regulatoryChange: return "Regulatory Update"
        case .userPattern: return "User Pattern Analysis"
        }
    }
    
    private func formatSavings(_ savings: Double) -> String {
        if savings >= 100000 {
            return String(format: "%.1fL", savings / 100000)
        } else if savings >= 1000 {
            return String(format: "%.1fK", savings / 1000)
        } else {
            return String(format: "%.0f", savings)
        }
    }
}



// MARK: - Preview

#Preview {
    ProfessionalRecommendationCard(recommendation: ProfessionalRecommendation(
        category: .taxOptimization,
        title: "Optimize Tax-Saving Investments",
        summary: "Your current tax-saving investments can be optimized to save additional ₹25,000 annually.",
        detailedAnalysis: "Based on your income bracket and current investments, reallocating funds to ELSS and NPS can provide better tax benefits while maintaining growth potential.",
        actionSteps: [
            "Review current investments under Section 80C",
            "Move ₹50,000 from traditional savings to ELSS funds",
            "Set up systematic investment plans"
        ],
        potentialSavings: 25000,
        priority: .high,
        source: .aiAnalysis
    ))
    .padding()
} 
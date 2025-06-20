import SwiftUI

// MARK: - Risk Level Badge Component

struct RiskLevelBadge: View {
    let risk: PredictiveInsight.RiskLevel
    
    var body: some View {
        Text(riskText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
    }
    
    private var riskText: String {
        switch risk {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }
    
    private var backgroundColor: Color {
        switch risk {
        case .low: return .green.opacity(0.15)
        case .medium: return .orange.opacity(0.15)
        case .high: return .red.opacity(0.15)
        }
    }
    
    private var textColor: Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Recommendation Priority Badge

struct RecommendationPriorityBadge: View {
    let priority: ProfessionalRecommendation.Priority
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)
            
            Text(priorityText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var priorityText: String {
        switch priority {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return FintechColors.primaryBlue
        case .low: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            RiskLevelBadge(risk: .low)
            RiskLevelBadge(risk: .medium)
            RiskLevelBadge(risk: .high)
        }
        
        HStack(spacing: 12) {
            RecommendationPriorityBadge(priority: .critical)
            RecommendationPriorityBadge(priority: .high)
            RecommendationPriorityBadge(priority: .medium)
            RecommendationPriorityBadge(priority: .low)
        }
    }
    .padding()
} 
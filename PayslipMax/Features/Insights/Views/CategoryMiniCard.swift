import SwiftUI

// MARK: - Category Mini Card Component

struct CategoryMiniCard: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(category.status.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(Int(category.score))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(category.status.color)
            }
            
            Text(category.name)
                .font(.caption2)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryMiniCard(category: HealthCategory(
        name: "Savings",
        score: 85,
        weight: 0.2,
        status: .excellent,
        recommendation: "Great savings rate",
        actionItems: []
    ))
    .padding()
} 
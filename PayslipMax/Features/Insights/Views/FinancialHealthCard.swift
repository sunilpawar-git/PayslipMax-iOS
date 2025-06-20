import SwiftUI
import Charts

// MARK: - Financial Health Overview Card

struct FinancialHealthOverviewCard: View {
    let healthScore: FinancialHealthScore
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financial Health Score")
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("Based on 5 key factors")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
                
                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                    Text(trendText)
                        .font(.caption)
                        .foregroundColor(trendColor)
                }
            }
            
            // Score Display
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: healthScore.overallScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: scoreColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: healthScore.overallScore)
                
                // Score text
                VStack(spacing: 4) {
                    Text("\(Int(healthScore.overallScore))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            
            // Categories preview
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(healthScore.categories.prefix(3)), id: \.name) { category in
                    CategoryMiniCard(category: category)
                }
            }
        }
        .fintechCardStyle()
    }
    
    private var scoreColors: [Color] {
        if healthScore.overallScore >= 80 { return [.green, .green.opacity(0.7)] }
        else if healthScore.overallScore >= 60 { return [FintechColors.primaryBlue, FintechColors.primaryBlue.opacity(0.7)] }
        else if healthScore.overallScore >= 40 { return [.orange, .orange.opacity(0.7)] }
        else { return [.red, .red.opacity(0.7)] }
    }
    
    private var trendIcon: String {
        switch healthScore.trend {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        switch healthScore.trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .gray
        }
    }
    
    private var trendText: String {
        switch healthScore.trend {
        case .improving(let percentage): return "+\(String(format: "%.1f", percentage))%"
        case .declining(let percentage): return "-\(String(format: "%.1f", percentage))%"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Health Score Detailed Card

struct HealthScoreCard: View {
    let healthScore: FinancialHealthScore
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with overall score
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Health Score")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    HStack {
                        Text("\(Int(healthScore.overallScore))/100")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        Text("• \(scoreDescription)")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Animated progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: healthScore.overallScore / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: healthScore.overallScore)
                }
            }
            
            // Last updated
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(FintechColors.textSecondary)
                Text("Last updated \(formattedDate)")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                Spacer()
            }
        }
        .fintechCardStyle()
    }
    
    private var scoreColor: Color {
        if healthScore.overallScore >= 80 { return .green }
        else if healthScore.overallScore >= 60 { return FintechColors.primaryBlue }
        else if healthScore.overallScore >= 40 { return .orange }
        else { return .red }
    }
    
    private var scoreDescription: String {
        if healthScore.overallScore >= 80 { return "Excellent" }
        else if healthScore.overallScore >= 60 { return "Good" }
        else if healthScore.overallScore >= 40 { return "Fair" }
        else { return "Needs Improvement" }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: healthScore.lastUpdated)
    }
}

// MARK: - Health Category Detailed Card

struct HealthCategoryCard: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with category name and score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text(category.recommendation)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(category.score))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(category.status.color)
                    
                    Text("\(category.status)".capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(category.status.color.opacity(0.15))
                        .foregroundColor(category.status.color)
                        .cornerRadius(8)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(category.status.color)
                        .frame(width: geometry.size.width * (category.score / 100), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 1.0), value: category.score)
                }
            }
            .frame(height: 8)
            
            // Action items
            if !category.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Actions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    ForEach(Array(category.actionItems.enumerated()), id: \.offset) { index, item in
                        ActionItemRow(item: item)
                    }
                }
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FinancialHealthOverviewCard(healthScore: FinancialHealthScore(
            overallScore: 85.0,
            categories: [
                HealthCategory(name: "Savings", score: 90, weight: 0.3, status: .excellent, recommendation: "Great", actionItems: []),
                HealthCategory(name: "Tax Efficiency", score: 75, weight: 0.2, status: .good, recommendation: "Good", actionItems: [])
            ],
            trend: .improving(5.2),
            lastUpdated: Date()
        ))
        HealthScoreCard(healthScore: FinancialHealthScore(
            overallScore: 85.0,
            categories: [
                HealthCategory(name: "Savings", score: 90, weight: 0.3, status: .excellent, recommendation: "Great", actionItems: []),
                HealthCategory(name: "Tax Efficiency", score: 75, weight: 0.2, status: .good, recommendation: "Good", actionItems: [])
            ],
            trend: .improving(5.2),
            lastUpdated: Date()
        ))
    }
    .padding()
} 
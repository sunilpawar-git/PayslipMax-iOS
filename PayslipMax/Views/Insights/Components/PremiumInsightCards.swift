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

// MARK: - Category Mini Card

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

// MARK: - Health Score Card (Detailed)

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
        else { return "Needs Attention" }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: healthScore.lastUpdated)
    }
}

// MARK: - Health Category Card

struct HealthCategoryCard: View {
    let category: HealthCategory
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main category info
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Status indicator
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(category.status.color.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(category.score))")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(category.status.color)
                            
                            Text("/ 100")
                                .font(.caption2)
                                .foregroundColor(category.status.color.opacity(0.7))
                        }
                    }
                    
                    // Category details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.name)
                                .font(.headline)
                                .foregroundColor(FintechColors.textPrimary)
                            
                            Spacer()
                            
                            // Status badge
                            Text(statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(category.status.color.opacity(0.15))
                                .foregroundColor(category.status.color)
                                .cornerRadius(8)
                        }
                        
                        Text(category.recommendation)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(FintechColors.textSecondary)
                        .font(.caption)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                    
                    // Action items
                    if !category.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Actions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                            
                            ForEach(Array(category.actionItems.enumerated()), id: \.offset) { index, item in
                                ActionItemRow(item: item, index: index)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var statusText: String {
        switch category.status {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Action Item Row

struct ActionItemRow: View {
    let item: ActionItem
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority indicator
            ZStack {
                Circle()
                    .fill(priorityColor.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(priorityColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Spacer()
                    
                    // Priority badge
                    Text(priorityText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundColor(priorityColor)
                        .cornerRadius(4)
                }
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Impact and timeframe
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text("+\(Int(item.estimatedImpact)) pts")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    
                    Text("•")
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text(item.timeframe)
                        .font(.caption2)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
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
    
    private var priorityText: String {
        switch item.priority {
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        }
    }
}

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
                RiskLevelBadge(level: insight.riskLevel)
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
            
            // Recommendation
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                
                Text(insight.recommendation)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
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

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: PredictiveInsight.RiskLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(levelText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.15))
        .foregroundColor(level.color)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch level {
        case .low: return "shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.shield.fill"
        }
    }
    
    private var levelText: String {
        switch level {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }
}

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
                    
                    // Detailed analysis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        Text(recommendation.detailedAnalysis)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    
                    // Action steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Action Steps")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        ForEach(Array(recommendation.actionSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(FintechColors.primaryBlue.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(FintechColors.primaryBlue)
                                }
                                
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundColor(FintechColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
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

// MARK: - Priority Badge

struct RecommendationPriorityBadge: View {
    let priority: ProfessionalRecommendation.Priority
    
    var body: some View {
        Text(priorityText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.15))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .purple
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    private var priorityText: String {
        switch priority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        }
    }
}

// MARK: - Supporting Cards

struct TopInsightsPreviewCard: View {
    let predictions: [PredictiveInsight]
    let recommendations: [ProfessionalRecommendation]
    let onViewMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Insights")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Button("View All", action: onViewMore)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.primaryBlue)
            }
            
            if !predictions.isEmpty || !recommendations.isEmpty {
                VStack(spacing: 12) {
                    ForEach(predictions.prefix(1), id: \.id) { prediction in
                        InsightPreviewRow(
                            title: prediction.title,
                            description: prediction.description,
                            icon: "crystal.ball",
                            color: FintechColors.primaryBlue
                        )
                    }
                    
                    ForEach(recommendations.prefix(1), id: \.id) { recommendation in
                        InsightPreviewRow(
                            title: recommendation.title,
                            description: recommendation.summary,
                            icon: "lightbulb",
                            color: .orange
                        )
                    }
                }
            } else {
                Text("Upload more payslips to generate insights")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .fintechCardStyle()
    }
}

struct InsightPreviewRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                    .lineLimit(1)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct UpgradePromptCard: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Unlock Premium Insights")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                    
                    Text("Get AI-powered predictions, professional recommendations, and industry benchmarks")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
            }
            
            Button(action: onUpgrade) {
                Text("Upgrade Now")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Additional Cards (Benchmark, Goals, etc.)

struct BenchmarkCard: View {
    let benchmark: BenchmarkData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(categoryText)
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Text("\(Int(benchmark.percentile))th percentile")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FintechColors.primaryBlue.opacity(0.15))
                    .foregroundColor(FintechColors.primaryBlue)
                    .cornerRadius(8)
            }
            
            // Comparison visualization
            VStack(spacing: 8) {
                HStack {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Spacer()
                    Text("Industry Average")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(FintechColors.primaryBlue)
                            .frame(width: geometry.size.width * min(benchmark.userValue / benchmark.benchmarkValue, 1.0))
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width * max(0, 1.0 - min(benchmark.userValue / benchmark.benchmarkValue, 1.0)))
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
                
                Text(benchmark.comparison.description)
                    .font(.subheadline)
                    .foregroundColor(comparisonColor)
                    .fontWeight(.medium)
            }
        }
        .fintechCardStyle()
    }
    
    private var categoryText: String {
        switch benchmark.category {
        case .salary: return "Annual Salary"
        case .taxRate: return "Tax Rate"
        case .savingsRate: return "Savings Rate"
        case .benefits: return "Benefits"
        case .growthRate: return "Growth Rate"
        case .totalCompensation: return "Total Compensation"
        }
    }
    
    private var comparisonColor: Color {
        switch benchmark.comparison {
        case .aboveAverage: return .green
        case .average: return .gray
        case .belowAverage: return .orange
        }
    }
}

struct FinancialGoalCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text(goalTypeText)
                        .font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
                
                Spacer()
                
                Text("\(Int(goal.progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 1.0), value: goal.progress)
                }
            }
            .frame(height: 8)
            
            // Goal details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Text("₹\(formatAmount(goal.currentAmount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Text("₹\(formatAmount(goal.targetAmount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }
            
            if goal.recommendedMonthlyContribution > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(FintechColors.primaryBlue)
                    
                    Text("Recommended: ₹\(Int(goal.recommendedMonthlyContribution))/month")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
        }
        .fintechCardStyle()
    }
    
    private var goalTypeText: String {
        switch goal.type {
        case .savings: return "Savings Goal"
        case .investment: return "Investment Goal"
        case .emergencyFund: return "Emergency Fund"
        case .retirementContribution: return "Retirement"
        case .debtPayoff: return "Debt Payoff"
        case .majorPurchase: return "Major Purchase"
        case .education: return "Education"
        }
    }
    
    private var progressColor: Color {
        if goal.progress >= 0.8 { return .green }
        else if goal.progress >= 0.5 { return FintechColors.primaryBlue }
        else if goal.progress >= 0.2 { return .orange }
        else { return .red }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 100000 {
            return String(format: "%.1fL", amount / 100000)
        } else if amount >= 1000 {
            return String(format: "%.1fK", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
} 
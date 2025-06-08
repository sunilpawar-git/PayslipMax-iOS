import SwiftUI
import SwiftData
import Charts

struct PremiumInsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var analyticsEngine: AdvancedAnalyticsEngine
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedTab: InsightsTab = .overview
    @State private var showPaywall = false
    @State private var isAnalyzing = false
    
    enum InsightsTab: String, CaseIterable {
        case overview = "Overview"
        case health = "Health Score"
        case predictions = "Predictions"
        case recommendations = "Recommendations"
        case benchmarks = "Benchmarks"
        case goals = "Goals"
        
        var icon: String {
            switch self {
            case .overview: return "chart.line.uptrend.xyaxis"
            case .health: return "heart.circle"
            case .predictions: return "crystal.ball"
            case .recommendations: return "lightbulb"
            case .benchmarks: return "chart.bar.xaxis"
            case .goals: return "target"
            }
        }
    }
    
    init() {
        let dataService = DIContainer.shared.dataService
        self._analyticsEngine = StateObject(wrappedValue: AdvancedAnalyticsEngine(dataService: dataService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        FintechColors.secondaryBackground,
                        FintechColors.backgroundGray
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        premiumHeaderView
                        
                        // Tab Selection
                        tabSelectionView
                        
                        // Content based on selected tab
                        Group {
                            switch selectedTab {
                            case .overview:
                                overviewSection
                            case .health:
                                healthScoreSection
                            case .predictions:
                                predictionsSection
                            case .recommendations:
                                recommendationsSection
                            case .benchmarks:
                                benchmarksSection
                            case .goals:
                                goalsSection
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refreshAnalytics() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(FintechColors.primaryBlue)
                    }
                }
            }
            .onAppear {
                Task {
                    await refreshAnalytics()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
        }
    }
    
    // MARK: - Premium Header
    
    private var premiumHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Text("Premium Insights")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                    
                    Text("AI-powered financial intelligence")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
                
                if !subscriptionManager.isPremiumUser {
                    Button("Upgrade") {
                        showPaywall = true
                    }
                    .buttonStyle(PremiumButtonStyle())
                }
            }
            
            // Quick stats if user has data
            if !payslips.isEmpty {
                quickStatsView
            }
        }
        .fintechCardStyle()
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            PremiumQuickStatCard(
                title: "Financial Health",
                value: "\(Int(analyticsEngine.financialHealthScore?.overallScore ?? 0))",
                suffix: "/100",
                color: healthScoreColor,
                icon: "heart.circle.fill"
            )
            
            PremiumQuickStatCard(
                title: "Risk Level",
                value: riskLevelText,
                suffix: "",
                color: riskLevelColor,
                icon: "shield.fill"
            )
            
            PremiumQuickStatCard(
                title: "Insights",
                value: "\(analyticsEngine.predictiveInsights.count + analyticsEngine.professionalRecommendations.count)",
                suffix: " items",
                color: FintechColors.primaryBlue,
                icon: "lightbulb.fill"
            )
        }
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightsTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab,
                        requiresPremium: tab != .overview && !subscriptionManager.isPremiumUser
                    ) {
                        if tab == .overview || subscriptionManager.isPremiumUser {
                            selectedTab = tab
                        } else {
                            showPaywall = true
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Content Sections
    
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Financial Health Score Overview
            if let healthScore = analyticsEngine.financialHealthScore {
                FinancialHealthOverviewCard(healthScore: healthScore)
            }
            
            // Top Insights Preview
            TopInsightsPreviewCard(
                predictions: Array(analyticsEngine.predictiveInsights.prefix(2)),
                recommendations: Array(analyticsEngine.professionalRecommendations.prefix(2))
            ) {
                if subscriptionManager.isPremiumUser {
                    selectedTab = .predictions
                } else {
                    showPaywall = true
                }
            }
            
            // Upgrade prompt for free users
            if !subscriptionManager.isPremiumUser {
                UpgradePromptCard {
                    showPaywall = true
                }
            }
        }
    }
    
    private var healthScoreSection: some View {
        VStack(spacing: 20) {
            if let healthScore = analyticsEngine.financialHealthScore {
                // Overall score
                HealthScoreCard(healthScore: healthScore)
                
                // Categories breakdown
                ForEach(healthScore.categories, id: \.name) { category in
                    HealthCategoryCard(category: category)
                }
            } else {
                PremiumEmptyStateView(
                    icon: "heart.circle",
                    title: "Calculating Health Score",
                    description: "Upload more payslips for accurate analysis"
                )
            }
        }
    }
    
    private var predictionsSection: some View {
        VStack(spacing: 16) {
            if analyticsEngine.predictiveInsights.isEmpty {
                PremiumEmptyStateView(
                    icon: "crystal.ball",
                    title: "No Predictions Available",
                    description: "Upload more payslips to generate predictive insights"
                )
            } else {
                ForEach(analyticsEngine.predictiveInsights, id: \.id) { insight in
                    PredictiveInsightCard(insight: insight)
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            if analyticsEngine.professionalRecommendations.isEmpty {
                PremiumEmptyStateView(
                    icon: "lightbulb",
                    title: "No Recommendations",
                    description: "Upload more payslips to get personalized recommendations"
                )
            } else {
                ForEach(analyticsEngine.professionalRecommendations, id: \.id) { recommendation in
                    ProfessionalRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
    
    private var benchmarksSection: some View {
        VStack(spacing: 16) {
            if analyticsEngine.benchmarkData.isEmpty {
                PremiumEmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "No Benchmark Data",
                    description: "Upload more payslips to compare with industry standards"
                )
            } else {
                ForEach(analyticsEngine.benchmarkData, id: \.category) { benchmark in
                    BenchmarkCard(benchmark: benchmark)
                }
            }
        }
    }
    
    private var goalsSection: some View {
        VStack(spacing: 16) {
            if analyticsEngine.financialGoals.isEmpty {
                PremiumEmptyStateView(
                    icon: "target",
                    title: "No Goals Set",
                    description: "Upload more payslips to track financial goals"
                )
            } else {
                ForEach(analyticsEngine.financialGoals, id: \.id) { goal in
                    FinancialGoalCard(goal: goal)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var healthScoreColor: Color {
        guard let score = analyticsEngine.financialHealthScore?.overallScore else { return .gray }
        
        if score >= 80 { return .green }
        else if score >= 60 { return FintechColors.primaryBlue }
        else if score >= 40 { return .orange }
        else { return .red }
    }
    
    private var riskLevelText: String {
        guard let metrics = analyticsEngine.advancedMetrics else { return "N/A" }
        
        if metrics.financialRiskScore < 30 { return "Low" }
        else if metrics.financialRiskScore < 60 { return "Medium" }
        else { return "High" }
    }
    
    private var riskLevelColor: Color {
        guard let metrics = analyticsEngine.advancedMetrics else { return .gray }
        
        if metrics.financialRiskScore < 30 { return .green }
        else if metrics.financialRiskScore < 60 { return .orange }
        else { return .red }
    }
    
    // MARK: - Methods
    
    private func refreshAnalytics() async {
        isAnalyzing = true
        await analyticsEngine.performComprehensiveAnalysis(payslips: payslips)
        isAnalyzing = false
    }
}

// MARK: - Supporting Views

struct PremiumQuickStatCard: View {
    let title: String
    let value: String
    let suffix: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let requiresPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if requiresPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? FintechColors.primaryBlue : Color.clear)
            )
            .foregroundColor(isSelected ? .white : FintechColors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : FintechColors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PremiumEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(FintechColors.textSecondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .fintechCardStyle()
    }
}

#Preview {
    PremiumInsightsView()
} 
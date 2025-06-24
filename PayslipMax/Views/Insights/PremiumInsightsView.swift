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
                        PremiumHeaderView(
                            analyticsEngine: analyticsEngine,
                            subscriptionManager: subscriptionManager,
                            payslips: payslips,
                            showPaywall: $showPaywall
                        )
                        
                        // Tab Selection
                        PremiumTabSelectionView(
                            selectedTab: $selectedTab,
                            subscriptionManager: subscriptionManager,
                            showPaywall: $showPaywall
                        )
                        
                        // Content based on selected tab
                        Group {
                            switch selectedTab {
                            case .overview:
                                PremiumOverviewSection(
                                    analyticsEngine: analyticsEngine,
                                    subscriptionManager: subscriptionManager,
                                    showPaywall: $showPaywall
                                )
                            case .health:
                                PremiumHealthScoreSection(analyticsEngine: analyticsEngine)
                            case .predictions:
                                PremiumPredictionsSection(analyticsEngine: analyticsEngine)
                            case .recommendations:
                                PremiumRecommendationsSection(analyticsEngine: analyticsEngine)
                            case .benchmarks:
                                PremiumBenchmarksSection(analyticsEngine: analyticsEngine)
                            case .goals:
                                PremiumGoalsSection(analyticsEngine: analyticsEngine)
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
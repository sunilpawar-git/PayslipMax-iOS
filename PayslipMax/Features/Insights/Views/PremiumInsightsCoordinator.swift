import SwiftUI
import Combine

// MARK: - Premium Insights Coordinator

/// Orchestrates all premium insight components with centralized state management
@MainActor
class PremiumInsightsCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var healthScore: FinancialHealthScore?
    @Published var predictiveInsights: [PredictiveInsight] = []
    @Published var recommendations: [ProfessionalRecommendation] = []
    @Published var benchmarkData: [BenchmarkData] = []
    @Published var financialGoals: [FinancialGoal] = []
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let insightsDataService: any InsightsDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(insightsDataService: any InsightsDataServiceProtocol) {
        self.insightsDataService = insightsDataService
        setupDataRefresh()
    }
    
    // MARK: - Public Methods
    
    /// Load all premium insights data
    func loadPremiumInsights() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let healthTask: Void = loadFinancialHealth()
            async let predictionsTask: Void = loadPredictiveInsights()
            async let recommendationsTask: Void = loadRecommendations()
            async let benchmarksTask: Void = loadBenchmarkData()
            async let goalsTask: Void = loadFinancialGoals()
            
            // Execute all tasks concurrently
            let _ = try await (healthTask, predictionsTask, recommendationsTask, benchmarksTask, goalsTask)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load premium insights: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    /// Refresh specific insight category
    func refreshInsightCategory(_ category: InsightCategory) async {
        switch category {
        case .health:
            try? await loadFinancialHealth()
        case .predictions:
            try? await loadPredictiveInsights()
        case .recommendations:
            try? await loadRecommendations()
        case .benchmarks:
            try? await loadBenchmarkData()
        case .goals:
            try? await loadFinancialGoals()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDataRefresh() {
        // Auto-refresh insights when payslip data changes
        NotificationCenter.default.publisher(for: .payslipDataUpdated)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadPremiumInsights()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadFinancialHealth() async throws {
        let health = try await insightsDataService.getFinancialHealthScore()
        await MainActor.run {
            self.healthScore = health
        }
    }
    
    private func loadPredictiveInsights() async throws {
        let insights = try await insightsDataService.getPredictiveInsights()
        await MainActor.run {
            self.predictiveInsights = insights
        }
    }
    
    private func loadRecommendations() async throws {
        let recs = try await insightsDataService.getProfessionalRecommendations()
        await MainActor.run {
            self.recommendations = recs
        }
    }
    
    private func loadBenchmarkData() async throws {
        let benchmarks = try await insightsDataService.getBenchmarkData()
        await MainActor.run {
            self.benchmarkData = benchmarks
        }
    }
    
    private func loadFinancialGoals() async throws {
        let goals = try await insightsDataService.getFinancialGoals()
        await MainActor.run {
            self.financialGoals = goals
        }
    }
}

// MARK: - Supporting Types

enum InsightCategory {
    case health, predictions, recommendations, benchmarks, goals
}

// MARK: - Data Service Protocol

protocol InsightsDataServiceProtocol {
    func getFinancialHealthScore() async throws -> FinancialHealthScore
    func getPredictiveInsights() async throws -> [PredictiveInsight]
    func getProfessionalRecommendations() async throws -> [ProfessionalRecommendation]
    func getBenchmarkData() async throws -> [BenchmarkData]
    func getFinancialGoals() async throws -> [FinancialGoal]
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let payslipDataUpdated = Notification.Name("payslipDataUpdated")
}

// MARK: - Premium Insights Container View

struct PremiumInsightsContainerView: View {
    @StateObject private var coordinator: PremiumInsightsCoordinator
    
    init(insightsDataService: any InsightsDataServiceProtocol) {
        _coordinator = StateObject(wrappedValue: PremiumInsightsCoordinator(insightsDataService: insightsDataService))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Financial Health Section
                if let healthScore = coordinator.healthScore {
                    FinancialHealthOverviewCard(healthScore: healthScore)
                }
                
                // Predictive Insights Section
                if !coordinator.predictiveInsights.isEmpty {
                    ForEach(coordinator.predictiveInsights) { insight in
                        PredictiveInsightCard(insight: insight)
                    }
                }
                
                // Professional Recommendations Section
                if !coordinator.recommendations.isEmpty {
                    ForEach(coordinator.recommendations) { recommendation in
                        ProfessionalRecommendationCard(recommendation: recommendation)
                    }
                }
                
                // Benchmark Comparison Section
                if !coordinator.benchmarkData.isEmpty {
                    ForEach(coordinator.benchmarkData, id: \.category) { benchmark in
                        BenchmarkCard(benchmark: benchmark)
                    }
                }
                
                // Financial Goals Section
                if !coordinator.financialGoals.isEmpty {
                    ForEach(coordinator.financialGoals) { goal in
                        FinancialGoalCard(goal: goal)
                    }
                }
            }
            .padding()
        }
        .overlay {
            if coordinator.isLoading {
                ProgressView("Loading Premium Insights...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .refreshable {
            await coordinator.loadPremiumInsights()
        }
        .task {
            await coordinator.loadPremiumInsights()
        }
        .alert("Error", isPresented: .constant(coordinator.errorMessage != nil)) {
            Button("Retry") {
                Task {
                    await coordinator.loadPremiumInsights()
                }
            }
            Button("Cancel", role: .cancel) {
                coordinator.errorMessage = nil
            }
        } message: {
            Text(coordinator.errorMessage ?? "")
        }
    }
} 
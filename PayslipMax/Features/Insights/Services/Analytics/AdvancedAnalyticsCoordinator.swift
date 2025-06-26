import Foundation
import SwiftUI
import Combine

/// Main coordinator that orchestrates all advanced analytics components
@MainActor
class AdvancedAnalyticsCoordinator: ObservableObject {
    
    // MARK: - Published Properties (Same as original interface)
    @Published var financialHealthScore: FinancialHealthScore?
    @Published var predictiveInsights: [PredictiveInsight] = []
    @Published var professionalRecommendations: [ProfessionalRecommendation] = []
    @Published var advancedMetrics: AdvancedMetrics?
    @Published var benchmarkData: [BenchmarkData] = []
    @Published var financialGoals: [FinancialGoal] = []
    @Published var isProcessing = false
    
    // MARK: - Component Dependencies
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Analytics Components
    private let healthScoreCalculator: FinancialHealthScoreCalculator
    private let predictiveAnalytics: PredictiveAnalyticsService
    private let recommendationEngine: ProfessionalRecommendationEngine
    private let metricsCalculator: AdvancedMetricsCalculator
    private let benchmarkAnalysis: BenchmarkAnalysisService
    private let goalAnalyzer: FinancialGoalAnalyzer
    private let errorHandler: AnalyticsErrorHandler
    
    // MARK: - Constants
    private struct AnalyticsConstants {
        static let minimumDataPointsForAnalysis = 3
        static let volatilityThreshold = 0.15
        static let goodSavingsRate = 0.20
        static let excellentSavingsRate = 0.30
        static let averageIncomeTaxRate = 0.20
        static let healthyDeductionRatio = 0.25
    }
    
    // MARK: - Initialization
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
        
        // Initialize action items generator first
        let actionItemsGenerator = HealthCategoryActionItemsGenerator()
        
        // Initialize all components with proper dependency injection
        self.healthScoreCalculator = FinancialHealthScoreCalculator(actionItemsGenerator: actionItemsGenerator)
        self.predictiveAnalytics = PredictiveAnalyticsService()
        self.recommendationEngine = ProfessionalRecommendationEngine()
        self.metricsCalculator = AdvancedMetricsCalculator()
        self.benchmarkAnalysis = BenchmarkAnalysisService()
        self.goalAnalyzer = FinancialGoalAnalyzer()
        self.errorHandler = AnalyticsErrorHandler()
    }
    
    // MARK: - Main Analysis Function (Same interface as original)
    
    func performComprehensiveAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Validate data first
        let validationResult = await errorHandler.validatePayslipData(payslips)
        
        guard validationResult.canProceedWithWarnings else {
            let (healthScore, insights, recommendations) = await errorHandler.handleInsufficientData()
            financialHealthScore = healthScore
            predictiveInsights = insights
            professionalRecommendations = recommendations
            return
        }
        
        // Attempt data recovery if needed
        let cleanedPayslips = await errorHandler.attemptDataRecovery(payslips)
        
        guard cleanedPayslips.count >= AnalyticsConstants.minimumDataPointsForAnalysis else {
            let (healthScore, insights, recommendations) = await errorHandler.handleInsufficientData()
            financialHealthScore = healthScore
            predictiveInsights = insights
            professionalRecommendations = recommendations
            return
        }
        
        // Run all analyses in parallel using the modular components
        async let healthScore = healthScoreCalculator.calculateFinancialHealthScore(payslips: cleanedPayslips)
        async let predictions = predictiveAnalytics.generatePredictiveInsights(payslips: cleanedPayslips)
        async let recommendations = recommendationEngine.generateProfessionalRecommendations(payslips: cleanedPayslips)
        async let metrics = metricsCalculator.calculateAdvancedMetrics(payslips: cleanedPayslips)
        async let benchmarks = benchmarkAnalysis.performBenchmarkAnalysis(payslips: cleanedPayslips)
        async let goals = goalAnalyzer.analyzeMilestoneProgress(payslips: cleanedPayslips)
        
        // Await all results
        financialHealthScore = await healthScore
        predictiveInsights = await predictions
        professionalRecommendations = await recommendations
        advancedMetrics = await metrics
        benchmarkData = await benchmarks
        financialGoals = await goals
        
        // Log any validation warnings
        for warning in validationResult.warnings {
            errorHandler.logValidationWarning(warning, context: "Comprehensive Analysis")
        }
    }
    
    // MARK: - Component Access Methods (For advanced usage)
    
    func getHealthScoreCalculator() -> FinancialHealthScoreCalculator {
        return healthScoreCalculator
    }
    
    func getPredictiveAnalytics() -> PredictiveAnalyticsService {
        return predictiveAnalytics
    }
    
    func getRecommendationEngine() -> ProfessionalRecommendationEngine {
        return recommendationEngine
    }
    
    func getMetricsCalculator() -> AdvancedMetricsCalculator {
        return metricsCalculator
    }
    
    func getBenchmarkAnalysis() -> BenchmarkAnalysisService {
        return benchmarkAnalysis
    }
    
    func getGoalAnalyzer() -> FinancialGoalAnalyzer {
        return goalAnalyzer
    }
    
    func getErrorHandler() -> AnalyticsErrorHandler {
        return errorHandler
    }
    
    // MARK: - Specialized Analysis Methods
    
    func performHealthScoreAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        let validationResult = await errorHandler.validatePayslipData(payslips)
        guard validationResult.canProceedWithWarnings else { return }
        
        let cleanedPayslips = await errorHandler.attemptDataRecovery(payslips)
        financialHealthScore = await healthScoreCalculator.calculateFinancialHealthScore(payslips: cleanedPayslips)
    }
    
    func performPredictiveAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        let validationResult = await errorHandler.validatePayslipData(payslips)
        guard validationResult.canProceedWithWarnings else { return }
        
        let cleanedPayslips = await errorHandler.attemptDataRecovery(payslips)
        predictiveInsights = await predictiveAnalytics.generatePredictiveInsights(payslips: cleanedPayslips)
    }
    
    func performBenchmarkAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        let validationResult = await errorHandler.validatePayslipData(payslips)
        guard validationResult.canProceedWithWarnings else { return }
        
        let cleanedPayslips = await errorHandler.attemptDataRecovery(payslips)
        benchmarkData = await benchmarkAnalysis.performBenchmarkAnalysis(payslips: cleanedPayslips)
    }
    
    func performGoalAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        let validationResult = await errorHandler.validatePayslipData(payslips)
        guard validationResult.canProceedWithWarnings else { return }
        
        let cleanedPayslips = await errorHandler.attemptDataRecovery(payslips)
        financialGoals = await goalAnalyzer.analyzeMilestoneProgress(payslips: cleanedPayslips)
    }
    
    // MARK: - Utility Methods
    
    func clearAnalysisResults() {
        financialHealthScore = nil
        predictiveInsights = []
        professionalRecommendations = []
        advancedMetrics = nil
        benchmarkData = []
        financialGoals = []
    }
    
    func getAnalysisStatus() -> String {
        if isProcessing {
            return "Processing..."
        } else if financialHealthScore != nil {
            return "Analysis Complete"
        } else {
            return "Ready for Analysis"
        }
    }
    
    func hasValidData() -> Bool {
        return financialHealthScore != nil
    }
    
    // MARK: - Legacy Compatibility Methods
    
    /// Legacy method for backward compatibility - delegates to the error handler
    private func handleInsufficientData() async {
        let (healthScore, insights, recommendations) = await errorHandler.handleInsufficientData()
        financialHealthScore = healthScore
        predictiveInsights = insights
        professionalRecommendations = recommendations
    }
} 
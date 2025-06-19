import XCTest
import SwiftUI
@testable import PayslipMax

@MainActor
class InsightsIntegrationTests: XCTestCase {
    var dataService: MockDataService!
    var subscriptionManager: SubscriptionManager!
    var analyticsEngine: AdvancedAnalyticsEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dataService = MockDataService()
        subscriptionManager = SubscriptionManager.shared
        analyticsEngine = AdvancedAnalyticsEngine(dataService: dataService)
    }
    
    override func tearDownWithError() throws {
        dataService = nil
        subscriptionManager = nil  
        analyticsEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic InsightsView Tests
    
    func testInsightsViewModelInitialization() {
        // Given
        let viewModel = InsightsViewModel(dataService: dataService)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.insights.isEmpty)
        XCTAssertTrue(viewModel.chartData.isEmpty)
        XCTAssertEqual(viewModel.totalIncome, 0)
        XCTAssertEqual(viewModel.totalDeductions, 0)
    }
    
    func testInsightsViewModelWithSampleData() {
        // Given
        let viewModel = InsightsViewModel(dataService: dataService)
        let samplePayslips = createSamplePayslips()
        
        // When
        viewModel.refreshData(payslips: samplePayslips)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.insights.isEmpty)
        XCTAssertFalse(viewModel.chartData.isEmpty)
        XCTAssertGreaterThan(viewModel.totalIncome, 0)
        XCTAssertGreaterThan(viewModel.totalDeductions, 0)
    }
    
    func testTimeRangeFiltering() {
        // Given
        let viewModel = InsightsViewModel(dataService: dataService)
        let payslips = createPayslipsForDifferentMonths()
        viewModel.refreshData(payslips: payslips)
        
        // When
        let originalChartDataCount = viewModel.chartData.count
        viewModel.updateTimeRange(.month)
        
        // Then
        XCTAssertLessThanOrEqual(viewModel.chartData.count, originalChartDataCount)
    }
    
    // MARK: - Premium Insights Tests
    
    func testAdvancedAnalyticsEngineInitialization() {
        // Given & When
        let engine = AdvancedAnalyticsEngine(dataService: dataService)
        
        // Then
        XCTAssertNotNil(engine)
    }
    
    func testFinancialHealthScoreCalculation() async {
        // Given
        let payslips = createSamplePayslips()
        
        // When
        let healthScore = await analyticsEngine.calculateFinancialHealthScore(payslips: payslips)
        
        // Then
        XCTAssertNotNil(healthScore)
        XCTAssertGreaterThanOrEqual(healthScore.overallScore, 0)
        XCTAssertLessThanOrEqual(healthScore.overallScore, 100)
        XCTAssertFalse(healthScore.categories.isEmpty)
    }
    
    func testPredictiveInsightsGeneration() async {
        // Given
        let payslips = createLongTermPayslipHistory()
        
        // When
        let predictions = await analyticsEngine.generatePredictiveInsights(payslips: payslips)
        
        // Then
        XCTAssertFalse(predictions.isEmpty)
        for prediction in predictions {
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
        }
    }
    
    func testProfessionalRecommendations() async {
        // Given
        let payslips = createSamplePayslips()
        
        // When
        let recommendations = await analyticsEngine.generateProfessionalRecommendations(payslips: payslips)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.summary.isEmpty)
            XCTAssertFalse(recommendation.actionSteps.isEmpty)
        }
    }
    
    // MARK: - Subscription Manager Tests
    
    func testSubscriptionManagerInitialization() {
        // Given & When
        let manager = SubscriptionManager.shared
        
        // Then
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isPremiumUser) // Default state
        XCTAssertGreaterThan(manager.remainingFreeInsights, 0)
    }
    
    func testFeatureAccessControl() {
        // Given
        let manager = SubscriptionManager.shared
        
        // When & Then
        XCTAssertFalse(manager.canAccessPremiumFeature(.predictions))
        XCTAssertFalse(manager.canAccessPremiumFeature(.healthScore))
        XCTAssertTrue(manager.canAccessPremiumFeature(.basicInsights))
    }
    
    // MARK: - UI Component Tests
    
    func testFintechColorsAccess() {
        // Test that all FintechColors are accessible
        let primaryBlue = FintechColors.primaryBlue
        let successGreen = FintechColors.successGreen
        let dangerRed = FintechColors.dangerRed
        let textPrimary = FintechColors.textPrimary
        
        XCTAssertNotNil(primaryBlue)
        XCTAssertNotNil(successGreen)
        XCTAssertNotNil(dangerRed)
        XCTAssertNotNil(textPrimary)
    }
    
    func testTrendColorCalculation() {
        // Test trend color calculation
        let positiveColor = FintechColors.getTrendColor(for: 0.1) // 10% positive
        let negativeColor = FintechColors.getTrendColor(for: -0.1) // 10% negative
        let neutralColor = FintechColors.getTrendColor(for: 0.02) // 2% neutral
        
        XCTAssertEqual(positiveColor, FintechColors.successGreen)
        XCTAssertEqual(negativeColor, FintechColors.dangerRed)
        XCTAssertEqual(neutralColor, FintechColors.warningAmber)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndInsightsFlow() async {
        // Given
        let viewModel = InsightsViewModel(dataService: dataService)
        let payslips = createSamplePayslips()
        
        // When - Basic insights
        viewModel.refreshData(payslips: payslips)
        
        // Then - Basic insights should be generated
        XCTAssertFalse(viewModel.insights.isEmpty)
        XCTAssertFalse(viewModel.chartData.isEmpty)
        
        // When - Premium insights
        let healthScore = await analyticsEngine.calculateFinancialHealthScore(payslips: payslips)
        let predictions = await analyticsEngine.generatePredictiveInsights(payslips: payslips)
        let recommendations = await analyticsEngine.generateProfessionalRecommendations(payslips: payslips)
        
        // Then - Premium insights should be generated
        XCTAssertNotNil(healthScore)
        XCTAssertFalse(predictions.isEmpty)
        XCTAssertFalse(recommendations.isEmpty)
    }
    
    func testMemoryUsageOptimization() {
        // Given
        let viewModel = InsightsViewModel(dataService: dataService)
        let largePayslipSet = createLargePayslipDataset()
        
        // When
        measureMetrics([.wallClockTime]) {
            viewModel.refreshData(payslips: largePayslipSet)
        }
        
        // Then - Should complete without memory issues
        XCTAssertFalse(viewModel.insights.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePayslips() -> [PayslipItem] {
        let calendar = Calendar.current
        var payslips: [PayslipItem] = []
        
        for i in 0..<6 {
            let date = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            
            let monthName = DateFormatter().monthSymbols[month - 1]
            
            let payslip = PayslipItem(
                id: UUID(),
                timestamp: date,
                month: monthName,
                year: year,
                credits: Double.random(in: 45000...55000),
                debits: Double.random(in: 8000...12000),
                dsop: Double.random(in: 2000...3000),
                tax: Double.random(in: 3000...5000),
                earnings: [
                    "BPAY": Double.random(in: 25000...30000),
                    "DA": Double.random(in: 8000...12000),
                    "MSP": Double.random(in: 5000...8000)
                ],
                deductions: [
                    "DSOP": Double.random(in: 2000...3000),
                    "ITAX": Double.random(in: 3000...5000),
                    "AGIF": Double.random(in: 100...300)
                ],
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F"
            )
            
            payslips.append(payslip)
        }
        
        return payslips
    }
    
    private func createPayslipsForDifferentMonths() -> [PayslipItem] {
        let calendar = Calendar.current
        var payslips: [PayslipItem] = []
        
        // Create payslips for different months and years
        for year in [2022, 2023, 2024] {
            for month in 1...12 {
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = 1
                
                if let date = calendar.date(from: components) {
                    let monthName = DateFormatter().monthSymbols[month - 1]
                    
                    let payslip = PayslipItem(
                        id: UUID(),
                        timestamp: date,
                        month: monthName,
                        year: year,
                        credits: 50000,
                        debits: 10000,
                        dsop: 2500,
                        tax: 4000,
                        name: "Test User",
                        accountNumber: "1234567890",
                        panNumber: "ABCDE1234F"
                    )
                    
                    payslips.append(payslip)
                }
            }
        }
        
        return payslips
    }
    
    private func createLongTermPayslipHistory() -> [PayslipItem] {
        let calendar = Calendar.current
        var payslips: [PayslipItem] = []
        
        // Create 2 years of payslip history for better predictions
        for i in 0..<24 {
            let date = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            
            let monthName = DateFormatter().monthSymbols[month - 1]
            
            // Simulate gradual salary increase
            let baseCredits = 45000.0
            let increasePerMonth = 100.0
            let credits = baseCredits + (Double(24 - i) * increasePerMonth)
            
            let payslip = PayslipItem(
                id: UUID(),
                timestamp: date,
                month: monthName,
                year: year,
                credits: credits,
                debits: credits * 0.2, // 20% deductions
                dsop: credits * 0.05,  // 5% DSOP
                tax: credits * 0.08,   // 8% tax
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F"
            )
            
            payslips.append(payslip)
        }
        
        return payslips
    }
    
    private func createLargePayslipDataset() -> [PayslipItem] {
        var payslips: [PayslipItem] = []
        
        // Create 100 payslips for performance testing
        for i in 0..<100 {
            let payslip = PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2024,
                credits: Double.random(in: 40000...60000),
                debits: Double.random(in: 8000...15000),
                dsop: Double.random(in: 2000...4000),
                tax: Double.random(in: 3000...6000),
                name: "Test User \(i)",
                accountNumber: "123456789\(i)",
                panNumber: "ABCDE123\(i)F"
            )
            
            payslips.append(payslip)
        }
        
        return payslips
    }
}

// MARK: - Mock Data Extensions

extension MockDataService {
    func setupSampleData() {
        // This would set up any sample data needed for testing
        // Implementation depends on your MockDataService structure
    }
} 
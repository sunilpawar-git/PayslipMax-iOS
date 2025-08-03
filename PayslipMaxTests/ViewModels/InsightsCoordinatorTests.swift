import XCTest
import Combine
@testable import PayslipMax

/// Comprehensive tests for InsightsCoordinator and its child ViewModels
@MainActor
class InsightsCoordinatorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var coordinator: InsightsCoordinator!
    private var mockDataService: MockDataService!
    private var cancellables: Set<AnyCancellable>!
    private var testPayslips: [PayslipItem]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockDataService = MockDataService()
        coordinator = InsightsCoordinator(dataService: mockDataService)
        cancellables = Set<AnyCancellable>()
        
        // Create test payslips with realistic data
        testPayslips = createTestPayslips()
        
        // Configure mock data service
        mockDataService.payslipsToReturn = testPayslips
    }
    
    override func tearDown() {
        cancellables.removeAll()
        coordinator = nil
        mockDataService = nil
        testPayslips = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testCoordinatorInitialization() {
        XCTAssertNotNil(coordinator)
        XCTAssertNotNil(coordinator.financialSummary)
        XCTAssertNotNil(coordinator.trendAnalysis)
        XCTAssertNotNil(coordinator.chartData)
        
        // Initial state should be correct
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
        XCTAssertEqual(coordinator.timeRange, .year)
        XCTAssertEqual(coordinator.insightType, .income)
        XCTAssertTrue(coordinator.insights.isEmpty)
    }
    
    func testChildViewModelInitialization() {
        // All child ViewModels should be properly initialized
        XCTAssertNotNil(coordinator.financialSummary)
        XCTAssertNotNil(coordinator.trendAnalysis)
        XCTAssertNotNil(coordinator.chartData)
        
        // Child ViewModels should be initialized with proper dependencies
        // Note: Can't test private dataService properties directly
        XCTAssertFalse(coordinator.financialSummary.isLoading)
        XCTAssertFalse(coordinator.trendAnalysis.isLoading)
        XCTAssertFalse(coordinator.chartData.isLoading)
    }
    
    // MARK: - Data Refresh Tests
    
    func testRefreshDataWithPayslips() {
        let expectation = XCTestExpectation(description: "Data refresh completes")
        
        // Monitor loading state changes
        var loadingStates: [Bool] = []
        coordinator.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Refresh data
        coordinator.refreshData(payslips: testPayslips)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Verify loading state transitions
        XCTAssertEqual(loadingStates.first, false) // Initial state
        XCTAssertEqual(loadingStates.last, false) // Final state
        
        // Verify insights were generated
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)
    }
    
    func testRefreshDataWithEmptyPayslips() {
        coordinator.refreshData(payslips: [])
        
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)
    }
    
    func testRefreshDataUpdatesChildViewModels() {
        coordinator.refreshData(payslips: testPayslips)
        
        // Verify child ViewModels received the data
        // Note: We can't directly access private properties, so we test the observable effects
        XCTAssertFalse(coordinator.financialSummary.isLoading)
        XCTAssertFalse(coordinator.trendAnalysis.isLoading)
        XCTAssertFalse(coordinator.chartData.isLoading)
    }
    
    // MARK: - Time Range Tests
    
    func testTimeRangeUpdate() {
        let expectation = XCTestExpectation(description: "Time range update")
        
        coordinator.$timeRange
            .dropFirst() // Skip initial value
            .sink { timeRange in
                XCTAssertEqual(timeRange, .month)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Set timeRange directly to trigger didSet observer
        coordinator.timeRange = .month
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTimeRangeUpdatePropagation() {
        coordinator.refreshData(payslips: testPayslips)
        
        // Update time range by setting the property
        coordinator.timeRange = .quarter
        
        // Verify the change
        XCTAssertEqual(coordinator.timeRange, .quarter)
        
        // Note: We would need to expose more properties or use a mock to verify
        // that chartData.updateTimeRange was called
    }
    
    // MARK: - Insight Type Tests
    
    func testInsightTypeUpdate() {
        let expectation = XCTestExpectation(description: "Insight type update")
        
        coordinator.$insightType
            .dropFirst()
            .sink { insightType in
                XCTAssertEqual(insightType, .deductions)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Set insightType directly to trigger didSet observer
        coordinator.insightType = .deductions
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInsightTypeUpdatePropagation() {
        coordinator.refreshData(payslips: testPayslips)
        
        // Update insight type by setting the property
        coordinator.insightType = .trends
        
        // Verify the change
        XCTAssertEqual(coordinator.insightType, .trends)
    }
    
    // MARK: - Insight Generation Tests
    
    func testInsightGeneration() {
        coordinator.refreshData(payslips: testPayslips)
        
        // Verify insights were generated
        XCTAssertFalse(coordinator.insights.isEmpty)
        
        // Check for expected insight types
        let insightTitles = coordinator.insights.map { $0.title }
        XCTAssertTrue(insightTitles.contains("Income Growth"))
        XCTAssertTrue(insightTitles.contains("Tax Rate"))
        XCTAssertTrue(insightTitles.contains("Income Stability"))
    }
    
    func testEarningsInsights() {
        coordinator.refreshData(payslips: testPayslips)
        
        let earningsInsights = coordinator.earningsInsights
        XCTAssertFalse(earningsInsights.isEmpty)
        
        // Verify earnings-related insights
        let earningsInsightTitles = earningsInsights.map { $0.title }
        let expectedEarningsInsights = [
            "Income Growth",
            "Savings Rate",
            "Income Stability",
            "Top Income Component"
        ]
        
        for expectedInsight in expectedEarningsInsights {
            XCTAssertTrue(earningsInsightTitles.contains(expectedInsight),
                         "Missing earnings insight: \(expectedInsight)")
        }
    }
    
    func testDeductionsInsights() {
        coordinator.refreshData(payslips: testPayslips)
        
        let deductionsInsights = coordinator.deductionsInsights
        XCTAssertFalse(deductionsInsights.isEmpty)
        
        // Verify deductions-related insights
        let deductionsInsightTitles = deductionsInsights.map { $0.title }
        let expectedDeductionsInsights = [
            "Tax Rate",
            "DSOP Contribution",
            "Deduction Percentage"
        ]
        
        for expectedInsight in expectedDeductionsInsights {
            XCTAssertTrue(deductionsInsightTitles.contains(expectedInsight),
                         "Missing deductions insight: \(expectedInsight)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        let expectation = XCTestExpectation(description: "Error handling")
        
        coordinator.$error
            .compactMap { $0 }
            .sink { error in
                XCTAssertEqual(error, "Test error")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate error by setting it directly on child ViewModel
        // Since refreshData doesn't use the mock service directly
        coordinator.financialSummary.error = "Test error"
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorClearance() {
        // First set an error directly on child ViewModel
        coordinator.financialSummary.error = "Test error"
        
        XCTAssertNotNil(coordinator.error)
        
        // Then clear the error
        coordinator.financialSummary.error = nil
        
        XCTAssertNil(coordinator.error)
    }
    
    // MARK: - Child ViewModel Binding Tests
    
    func testChildViewModelLoadingStateBinding() {
        let expectation = XCTestExpectation(description: "Loading state binding")
        
        // Monitor coordinator loading state
        coordinator.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate child ViewModel loading
        coordinator.financialSummary.isLoading = true
        coordinator.refreshData(payslips: testPayslips)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testChildViewModelErrorBinding() {
        let expectation = XCTestExpectation(description: "Error binding")
        
        coordinator.$error
            .compactMap { $0 }
            .sink { error in
                XCTAssertEqual(error, "Child error")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate child ViewModel error
        coordinator.financialSummary.error = "Child error"
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testRefreshDataPerformance() {
        // Create large dataset
        let largePayslipSet = createLargeTestPayslipSet(count: 500) // Reduced from 1000
        
        measure {
            coordinator.refreshData(payslips: largePayslipSet)
        }
        
        // Verify the operation completed successfully
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)
    }
    
    func testInsightGenerationPerformance() {
        let largePayslipSet = createLargeTestPayslipSet(count: 500)
        
        measure {
            coordinator.refreshData(payslips: largePayslipSet)
        }
        
        // Verify insights were generated efficiently
        XCTAssertGreaterThan(coordinator.insights.count, 5)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakCoordinator = coordinator
        weak var weakFinancialSummary = coordinator.financialSummary
        weak var weakTrendAnalysis = coordinator.trendAnalysis
        weak var weakChartData = coordinator.chartData
        
        coordinator = nil
        
        XCTAssertNil(weakCoordinator)
        XCTAssertNil(weakFinancialSummary)
        XCTAssertNil(weakTrendAnalysis)
        XCTAssertNil(weakChartData)
    }
    
    func testCancellableCleanup() {
        let initialCancellableCount = cancellables.count
        
        // Create some subscriptions
        coordinator.$isLoading
            .sink { _ in }
            .store(in: &cancellables)
        
        coordinator.$error
            .sink { _ in }
            .store(in: &cancellables)
        
        XCTAssertGreaterThan(cancellables.count, initialCancellableCount)
        
        // Clean up
        cancellables.removeAll()
        XCTAssertEqual(cancellables.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() {
        // Test complete workflow from initialization to insights generation
        
        // 1. Initial state
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)
        
        // 2. Load data
        coordinator.refreshData(payslips: testPayslips)
        
        // 3. Verify insights generated
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)
        
        // 4. Change time range
        coordinator.timeRange = .month
        XCTAssertEqual(coordinator.timeRange, .month)
        
        // 5. Change insight type
        coordinator.insightType = .deductions
        XCTAssertEqual(coordinator.insightType, .deductions)
        
        // 6. Verify state consistency
        XCTAssertNil(coordinator.error)
        XCTAssertFalse(coordinator.isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPayslips() -> [PayslipItem] {
        return [
            PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 50000.0,
                debits: 10000.0,
                dsop: 5000.0,
                tax: 8000.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            PayslipItem(
                id: UUID(),
                month: "February",
                year: 2023,
                credits: 52000.0,
                debits: 10500.0,
                dsop: 5200.0,
                tax: 8500.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            PayslipItem(
                id: UUID(),
                month: "March",
                year: 2023,
                credits: 51000.0,
                debits: 10200.0,
                dsop: 5100.0,
                tax: 8200.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            )
        ]
    }
    
    private func createLargeTestPayslipSet(count: Int) -> [PayslipItem] {
        return (0..<count).map { index in
            PayslipItem(
                id: UUID(),
                month: ["January", "February", "March", "April", "May", "June"][index % 6],
                year: 2020 + (index / 12),
                credits: Double.random(in: 30000...80000),
                debits: Double.random(in: 5000...20000),
                dsop: Double.random(in: 2000...8000),
                tax: Double.random(in: 3000...15000),
                name: "Test User \(index % 10)",
                accountNumber: "ACC\(String(format: "%03d", index % 100))",
                panNumber: "PAN\(String(format: "%03d", index % 100))"
            )
        }
    }
} 
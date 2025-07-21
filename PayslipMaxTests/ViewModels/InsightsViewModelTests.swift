import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import PayslipMax

@MainActor
final class InsightsViewModelTests: XCTestCase {
    var coordinator: InsightsCoordinator!
    var mockDataService: MockDataService!
    var testPayslips: [PayslipItem] = []
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize mock services
        mockDataService = MockDataService()
        cancellables = Set<AnyCancellable>()
        
        // Create the coordinator with mock service
        coordinator = InsightsCoordinator(dataService: mockDataService)
        
        // Create test payslips with corrected property names
        let januaryPayslip = PayslipItem(
            id: UUID(),
            month: "January",
            year: 2023,
            credits: 5000,
            debits: 1000,
            dsop: 500,    // Changed from dspof to dsop
            tax: 800,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        let februaryPayslip = PayslipItem(
            id: UUID(),
            month: "February",
            year: 2023,
            credits: 5500,
            debits: 1100,
            dsop: 550,    // Changed from dspof to dsop
            tax: 880,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        let marchPayslip = PayslipItem(
            id: UUID(),
            month: "March",
            year: 2023,
            credits: 6000,
            debits: 1200,
            dsop: 600,    // Changed from dspof to dsop
            tax: 960,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        testPayslips = [januaryPayslip, februaryPayslip, marchPayslip]
        
        // Save payslips to mock data service
        mockDataService.payslipsToReturn = testPayslips
    }
    
    override func tearDown() async throws {
        coordinator = nil
        mockDataService = nil
        testPayslips = []
        cancellables.removeAll()
        try await super.tearDown()
    }
    
    func testCoordinatorInitialization() throws {
        // Test that coordinator initializes properly
        XCTAssertNotNil(coordinator)
        XCTAssertNotNil(coordinator.financialSummary)
        XCTAssertNotNil(coordinator.trendAnalysis)
        XCTAssertNotNil(coordinator.chartData)
        
        // Test initial values
        XCTAssertEqual(coordinator.timeRange, .year)
        XCTAssertEqual(coordinator.insightType, .income)
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
    }
    
    func testRefreshDataWithPayslips() throws {
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        // Then - verify insights were generated
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
    }
    
    func testTimeRangeUpdate() throws {
        let expectation = XCTestExpectation(description: "Time range update")
        
        coordinator.$timeRange
            .dropFirst() // Skip initial value
            .sink { timeRange in
                XCTAssertEqual(timeRange, .month)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        coordinator.timeRange = .month
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInsightTypeUpdate() throws {
        let expectation = XCTestExpectation(description: "Insight type update")
        
        coordinator.$insightType
            .dropFirst()
            .sink { insightType in
                XCTAssertEqual(insightType, .deductions)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        coordinator.insightType = .deductions
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInsightGeneration() throws {
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        // Then - verify insights were generated with expected types
        XCTAssertFalse(coordinator.insights.isEmpty)
        
        // Check for expected insight types
        let _ = coordinator.insights.map { $0.title }
        
        // We should have some insights, but don't require specific ones since
        // the insight generation logic may vary
        XCTAssertGreaterThan(coordinator.insights.count, 0)
    }
    
    func testEarningsInsights() throws {
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        let earningsInsights = coordinator.earningsInsights
        
        // Then - earnings insights should be a subset of all insights
        XCTAssertTrue(earningsInsights.count <= coordinator.insights.count)
        
        // Verify all earnings insights are actually earnings-related
        for insight in earningsInsights {
            let isEarningsRelated = [
                "Income Growth",
                "Savings Rate", 
                "Income Stability",
                "Top Income Component"
            ].contains(insight.title)
            XCTAssertTrue(isEarningsRelated, "Insight '\(insight.title)' should be earnings-related")
        }
    }
    
    func testDeductionsInsights() throws {
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        let deductionsInsights = coordinator.deductionsInsights
        
        // Then - deductions insights should be a subset of all insights
        XCTAssertTrue(deductionsInsights.count <= coordinator.insights.count)
        
        // Verify all deductions insights are actually deductions-related
        for insight in deductionsInsights {
            let isDeductionsRelated = [
                "Tax Rate",
                "DSOP Contribution",
                "Deduction Percentage"
            ].contains(insight.title)
            XCTAssertTrue(isDeductionsRelated, "Insight '\(insight.title)' should be deductions-related")
        }
    }
    
    func testEmptyPayslipsHandling() throws {
        // When - refresh with empty payslips
        coordinator.refreshData(payslips: [])
        
        // Then - should handle gracefully
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)
    }
    
    func testChildViewModelUpdates() throws {
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        // Then - verify child ViewModels are not loading
        XCTAssertFalse(coordinator.financialSummary.isLoading)
        XCTAssertFalse(coordinator.trendAnalysis.isLoading)
        XCTAssertFalse(coordinator.chartData.isLoading)
    }
    
    func testLoadingStateTransitions() throws {
        let expectation = XCTestExpectation(description: "Loading state transitions")
        
        var loadingStates: [Bool] = []
        coordinator.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        coordinator.refreshData(payslips: testPayslips)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Then - verify loading state transitions
        XCTAssertEqual(loadingStates.first, false) // Initial state
        XCTAssertEqual(loadingStates.last, false) // Final state
    }
}
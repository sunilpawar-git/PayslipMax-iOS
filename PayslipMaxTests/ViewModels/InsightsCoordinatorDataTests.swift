import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator data refresh and insight generation
@MainActor
class InsightsCoordinatorDataTests: XCTestCase {

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
        testPayslips = InsightsViewModelTestHelpers.createStandardTestPayslips()

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

}

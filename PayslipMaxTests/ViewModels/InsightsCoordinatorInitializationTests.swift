import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator initialization and setup
@MainActor
class InsightsCoordinatorInitializationTests: XCTestCase {

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

}

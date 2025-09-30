import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator integration and full workflow
@MainActor
class InsightsCoordinatorIntegrationTests: XCTestCase {

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

    // MARK: - Integration Tests

    func testFullWorkflow() {
        // Test complete workflow from initialization to insights generation

        // 1. Initial state
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)

        // 2. Load data
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

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

    func testWorkflowWithEmptyData() {
        // Test workflow with empty data set

        // 1. Initial state
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)

        // 2. Load empty data
        coordinator.refreshData(payslips: [])

        // 3. Verify empty state maintained
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
    }

    func testWorkflowWithErrorRecovery() {
        // Test error handling and recovery in workflow

        // 1. Load valid data first
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)

        // 2. Simulate error
        coordinator.financialSummary.error = "Test error"
        XCTAssertNotNil(coordinator.error)

        // 3. Clear error and reload
        coordinator.financialSummary.error = nil
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        // 4. Verify recovery
        XCTAssertNil(coordinator.error)
        XCTAssertFalse(coordinator.insights.isEmpty)
    }

    func testWorkflowConfigurationChanges() {
        // Test workflow with multiple configuration changes

        // 1. Load initial data
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })
        XCTAssertFalse(coordinator.insights.isEmpty)

        // 2. Change time range multiple times
        coordinator.timeRange = .month
        XCTAssertEqual(coordinator.timeRange, .month)

        coordinator.timeRange = .quarter
        XCTAssertEqual(coordinator.timeRange, .quarter)

        coordinator.timeRange = .year
        XCTAssertEqual(coordinator.timeRange, .year)

        // 3. Change insight type multiple times
        coordinator.insightType = .deductions
        XCTAssertEqual(coordinator.insightType, .deductions)

        coordinator.insightType = .trends
        XCTAssertEqual(coordinator.insightType, .trends)

        coordinator.insightType = .income
        XCTAssertEqual(coordinator.insightType, .income)

        // 4. Verify final state
        XCTAssertNil(coordinator.error)
        XCTAssertFalse(coordinator.isLoading)
    }

}

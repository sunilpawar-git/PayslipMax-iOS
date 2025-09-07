import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator configuration (time range, insight type)
@MainActor
class InsightsCoordinatorConfigurationTests: XCTestCase {

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
        testPayslips = InsightsCoordinatorTestHelpers.createStandardTestPayslips()

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

}

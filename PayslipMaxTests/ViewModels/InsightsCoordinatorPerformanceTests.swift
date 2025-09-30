import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator performance and memory management
@MainActor
class InsightsCoordinatorPerformanceTests: XCTestCase {

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

    // MARK: - Performance Tests

    func testRefreshDataPerformance() {
        // Create large dataset
        let largePayslipSet = InsightsViewModelTestHelpers.createLargeTestPayslipSet(count: 500) // Reduced from 1000

        measure {
            coordinator.refreshData(payslips: largePayslipSet.map { PayslipDTO(from: $0) })
        }

        // Verify the operation completed successfully
        XCTAssertFalse(coordinator.insights.isEmpty)
        XCTAssertNil(coordinator.error)
    }

    func testInsightGenerationPerformance() {
        let largePayslipSet = InsightsViewModelTestHelpers.createLargeTestPayslipSet(count: 500)

        measure {
            coordinator.refreshData(payslips: largePayslipSet.map { PayslipDTO(from: $0) })
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

}

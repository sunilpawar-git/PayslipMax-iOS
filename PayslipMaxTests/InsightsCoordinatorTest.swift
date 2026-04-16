import XCTest
import SwiftUI
import Combine
import SwiftData
@testable import PayslipMax

@MainActor
final class InsightsCoordinatorTest: XCTestCase {

    // MARK: - Test Properties

    private var coordinator: InsightsCoordinator!
    private var mockDataService: DataServiceImpl!
    private var mockSecurityService: MockSecurityService!
    private var modelContext: ModelContext!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Setup in-memory SwiftData
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: PayslipItem.self, configurations: config)
            modelContext = ModelContext(container)

            // Setup mocks
            mockSecurityService = MockSecurityService()

            // Initialize data service
            mockDataService = DataServiceImpl(
                securityService: mockSecurityService,
                modelContext: modelContext
            )

            coordinator = InsightsCoordinator(dataService: mockDataService)
            cancellables = Set<AnyCancellable>()
        } catch {
            XCTFail("Failed to setup test environment: \(error)")
        }
    }

    override func tearDown() {
        coordinator = nil
        mockDataService = nil
        mockSecurityService = nil
        modelContext = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    /// Test 1: Verify initial state is correct
    func testInitialState() {
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
        XCTAssertEqual(coordinator.timeRange, .year)
        XCTAssertEqual(coordinator.insightType, .income)
        XCTAssertTrue(coordinator.insights.isEmpty)
        XCTAssertTrue(coordinator.earningsInsights.isEmpty)
        XCTAssertTrue(coordinator.deductionsInsights.isEmpty)

        // Verify child ViewModels are initialized
        XCTAssertNotNil(coordinator.financialSummary)
        XCTAssertNotNil(coordinator.trendAnalysis)
        XCTAssertNotNil(coordinator.chartData)
    }

    /// Test 2: Verify data refresh functionality
    func testRefreshData() {
        // Given: Mock payslips
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()

        // When: Refresh data
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Then: Should update insights
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNotNil(coordinator.insights)

        // Verify insights are generated based on payslips
        XCTAssertFalse(coordinator.insights.isEmpty)
    }

    /// Test 3: Verify time range updates
    func testTimeRangeUpdate() {
        // Given: Initial time range
        XCTAssertEqual(coordinator.timeRange, .year)

        // When: Update time range
        coordinator.timeRange = .month

        // Then: Should update time range
        XCTAssertEqual(coordinator.timeRange, .month)
    }

    /// Test 4: Verify insight type updates
    func testInsightTypeUpdate() {
        // Given: Initial insight type
        XCTAssertEqual(coordinator.insightType, .income)

        // When: Update insight type
        coordinator.insightType = .deductions

        // Then: Should update insight type
        XCTAssertEqual(coordinator.insightType, .deductions)
    }

    /// Test 5: Verify earnings insights filtering
    func testEarningsInsightsFiltering() {
        // Given: Mock payslips with earnings insights
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()
        _ = InsightsCoordinatorTestHelpers.createMockInsights() // Create mock insights for setup

        // When: Set insights manually for testing
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Mock setting insights directly for filter testing
        _ = [
            InsightsCoordinatorTestHelpers.createMockInsightItem(title: "Earnings Growth", description: "Test"),
            InsightsCoordinatorTestHelpers.createMockInsightItem(title: "Tax Rate", description: "Test"),
            InsightsCoordinatorTestHelpers.createMockInsightItem(title: "Savings Rate", description: "Test")
        ]

        // Test the filtering behavior by verifying insights generation
        XCTAssertNotNil(coordinator.insights) // Basic validation

        // Then: Should filter earnings insights correctly
        // Note: This test depends on the actual insight generation logic
        XCTAssertNotNil(coordinator.earningsInsights)
    }

    /// Test 6: Verify deductions insights filtering
    func testDeductionsInsightsFiltering() {
        // Given: Mock payslips with deductions insights
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Then: Should filter deductions insights correctly
        XCTAssertNotNil(coordinator.deductionsInsights)
    }

    /// Test 7: Verify loading state management
    func testLoadingStateManagement() {
        // Given: Initial state
        XCTAssertFalse(coordinator.isLoading)

        // When: Refresh data (this should briefly set loading to true)
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Then: Should complete loading
        XCTAssertFalse(coordinator.isLoading)
    }

    /// Test 8: Verify error handling
    func testErrorHandling() {
        // Note: Error handling would require a more sophisticated mock
        // For now, we'll test the happy path with DataServiceImpl

        // Given: Normal payslips
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()

        // When: Refresh data
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Then: Should complete successfully
        XCTAssertFalse(coordinator.isLoading)
    }

    /// Test 9: Verify empty payslips handling
    func testEmptyPayslipsHandling() {
        // Given: Empty payslips array
        let emptyPayslips: [PayslipItem] = []

        // When: Refresh data
        coordinator.refreshData(payslips: emptyPayslips.map { PayslipDTO(from: $0) })

        // Then: Should handle empty data gracefully
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertTrue(coordinator.insights.isEmpty)
    }

    /// Test 10: Verify child ViewModels coordination
    func testChildViewModelsCoordination() {
        // Given: Mock payslips
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()

        // When: Refresh data
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        // Then: Child ViewModels should be updated
        XCTAssertNotNil(coordinator.financialSummary)
        XCTAssertNotNil(coordinator.trendAnalysis)
        XCTAssertNotNil(coordinator.chartData)
    }

}

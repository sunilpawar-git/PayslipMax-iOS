import XCTest
import SwiftUI
import Combine
import SwiftData
@testable import PayslipMax

@MainActor
final class InsightsCoordinatorEnumTests: XCTestCase {

    private var coordinator: InsightsCoordinator!
    private var mockDataService: DataServiceImpl!
    private var mockSecurityService: MockSecurityService!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: PayslipItem.self, configurations: config)
            modelContext = ModelContext(container)
            mockSecurityService = MockSecurityService()
            mockDataService = DataServiceImpl(
                securityService: mockSecurityService,
                modelContext: modelContext
            )
            coordinator = InsightsCoordinator(dataService: mockDataService)
        } catch {
            XCTFail("Failed to setup test environment: \(error)")
        }
    }

    override func tearDown() {
        coordinator = nil
        mockDataService = nil
        mockSecurityService = nil
        modelContext = nil
        super.tearDown()
    }

    func testTimeRangePropertyObserver() {
        let initialRange = coordinator.timeRange

        coordinator.timeRange = .quarter

        XCTAssertNotEqual(coordinator.timeRange, initialRange)
        XCTAssertEqual(coordinator.timeRange, .quarter)
    }

    func testInsightTypePropertyObserver() {
        let initialType = coordinator.insightType

        coordinator.insightType = .trends

        XCTAssertNotEqual(coordinator.insightType, initialType)
        XCTAssertEqual(coordinator.insightType, .trends)
    }

    func testInsightsGenerationWithMultiplePayslips() {
        let payslips = InsightsCoordinatorTestHelpers.createMultipleMockPayslips()

        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        XCTAssertFalse(coordinator.isLoading)
        XCTAssertFalse(coordinator.insights.isEmpty)
    }

    func testStateConsistencyAfterMultipleOperations() {
        let payslips = InsightsCoordinatorTestHelpers.createMockPayslips()

        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })
        coordinator.timeRange = .month
        coordinator.insightType = .deductions
        coordinator.refreshData(payslips: payslips.map { PayslipDTO(from: $0) })

        XCTAssertFalse(coordinator.isLoading)
        XCTAssertEqual(coordinator.timeRange, .month)
        XCTAssertEqual(coordinator.insightType, .deductions)
    }

    func testTimeRangeEnumValues() {
        XCTAssertEqual(TimeRange.month.rawValue, "Month")
        XCTAssertEqual(TimeRange.quarter.rawValue, "Quarter")
        XCTAssertEqual(TimeRange.year.rawValue, "Year")
        XCTAssertEqual(TimeRange.all.rawValue, "All Time")

        XCTAssertEqual(TimeRange.month.displayName, "Month")
        XCTAssertEqual(TimeRange.quarter.displayName, "Quarter")
        XCTAssertEqual(TimeRange.year.displayName, "Year")
        XCTAssertEqual(TimeRange.all.displayName, "All Time")
    }

    func testInsightTypeEnumValues() {
        XCTAssertEqual(InsightType.income.rawValue, "Earnings")
        XCTAssertEqual(InsightType.deductions.rawValue, "Deductions")
        XCTAssertEqual(InsightType.net.rawValue, "Net Remittance")
        XCTAssertEqual(InsightType.trends.rawValue, "Trends")

        XCTAssertEqual(InsightType.income.displayName, "Earnings")
        XCTAssertEqual(InsightType.deductions.displayName, "Deductions")
        XCTAssertEqual(InsightType.net.displayName, "Net Remittance")
        XCTAssertEqual(InsightType.trends.displayName, "Trends")
    }
}

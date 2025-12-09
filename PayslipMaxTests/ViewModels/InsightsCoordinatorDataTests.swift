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
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

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
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        // Verify child ViewModels received the data
        // Note: We can't directly access private properties, so we test the observable effects
        XCTAssertFalse(coordinator.financialSummary.isLoading)
        XCTAssertFalse(coordinator.trendAnalysis.isLoading)
        XCTAssertFalse(coordinator.chartData.isLoading)
    }

    // MARK: - Insight Generation Tests

    func testInsightGeneration() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        // Verify insights were generated
        XCTAssertFalse(coordinator.insights.isEmpty)

        // Check for expected insight types
        let insightTitles = coordinator.insights.map { $0.title }
        XCTAssertTrue(insightTitles.contains("Earnings Growth"))
        XCTAssertTrue(insightTitles.contains("Tax Rate"))
    }

    func testEarningsInsights() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        let earningsInsights = coordinator.earningsInsights
        XCTAssertFalse(earningsInsights.isEmpty)

        // Verify earnings-related insights
        let earningsInsightTitles = earningsInsights.map { $0.title }
        let expectedEarningsInsights = [
            "Earnings Growth",
            "Net Remittance Rate",
            "Top Income Component"
        ]

        for expectedInsight in expectedEarningsInsights {
            XCTAssertTrue(earningsInsightTitles.contains(expectedInsight),
                         "Missing earnings insight: \(expectedInsight)")
        }
    }

    func testDeductionsInsights() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        let deductionsInsights = coordinator.deductionsInsights
        XCTAssertFalse(deductionsInsights.isEmpty)

        // Verify deductions-related insights
        let deductionsInsightTitles = deductionsInsights.map { $0.title }
        let expectedDeductionsInsights = [
            "Tax Rate",
            "DSOP Contribution",
            "Deductions"
        ]

        for expectedInsight in expectedDeductionsInsights {
            XCTAssertTrue(deductionsInsightTitles.contains(expectedInsight),
                         "Missing deductions insight: \(expectedInsight)")
        }
    }

    func testDeductionsInsightIsNewestFirst() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let deductionsInsight = coordinator.insights.first(where: { $0.title == "Deductions" }) else {
            XCTFail("Deductions insight not found")
            return
        }

        let items = deductionsInsight.detailItems
        XCTAssertGreaterThan(items.count, 1, "Need multiple items to verify ordering")

        for idx in 1..<items.count {
            let previous = parsePeriod(items[idx - 1].period)
            let current = parsePeriod(items[idx].period)
            XCTAssertTrue(previous >= current, "Expected newest-first ordering, but \(items[idx - 1].period) came before \(items[idx].period)")
        }
    }

    func testDeductionsInsightUsesEarningsWording() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let deductionsInsight = coordinator.insights.first(where: { $0.title == "Deductions" }) else {
            XCTFail("Deductions insight not found")
            return
        }

        for detail in deductionsInsight.detailItems {
            if let info = detail.additionalInfo, info != "Highest month" {
                XCTAssertTrue(info.localizedCaseInsensitiveContains("earnings"),
                              "Expected wording to reference earnings, got: \(info)")
            }
        }
    }

    func testNetRemittanceInsightIsNewestFirst() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let insight = coordinator.insights.first(where: { $0.title == "Net Remittance Rate" }) else {
            XCTFail("Net Remittance Rate insight not found")
            return
        }

        let items = insight.detailItems
        XCTAssertGreaterThan(items.count, 1, "Need multiple items to verify ordering")

        for idx in 1..<items.count {
            let previous = parsePeriod(items[idx - 1].period)
            let current = parsePeriod(items[idx].period)
            XCTAssertTrue(previous >= current, "Expected newest-first ordering, but \(items[idx - 1].period) came before \(items[idx].period)")
        }
    }

    func testNetRemittanceInsightUsesEarningsWording() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let insight = coordinator.insights.first(where: { $0.title == "Net Remittance Rate" }) else {
            XCTFail("Net Remittance Rate insight not found")
            return
        }

        for detail in insight.detailItems {
            if let info = detail.additionalInfo, info != "Highest month" {
                XCTAssertTrue(info.localizedCaseInsensitiveContains("earnings"),
                              "Expected wording to reference earnings, got: \(info)")
            }
        }
    }

    func testEarningsGrowthInsightIsNewestFirst() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let insight = coordinator.insights.first(where: { $0.title == "Earnings Growth" }) else {
            XCTFail("Earnings Growth insight not found")
            return
        }

        let items = insight.detailItems
        XCTAssertGreaterThan(items.count, 1, "Need multiple items to verify ordering")

        for idx in 1..<items.count {
            let previous = parsePeriod(items[idx - 1].period)
            let current = parsePeriod(items[idx].period)
            XCTAssertTrue(previous >= current, "Expected newest-first ordering, but \(items[idx - 1].period) came before \(items[idx].period)")
        }
    }

    func testEarningsGrowthInsightUsesEarningsWording() {
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        guard let insight = coordinator.insights.first(where: { $0.title == "Earnings Growth" }) else {
            XCTFail("Earnings Growth insight not found")
            return
        }

        for detail in insight.detailItems {
            if let info = detail.additionalInfo, info != "Highest month" {
                XCTAssertTrue(info.localizedCaseInsensitiveContains("earnings"),
                              "Expected wording to reference earnings, got: \(info)")
            }
        }
    }

    // MARK: - Helpers

    private func parsePeriod(_ period: String) -> (year: Int, month: Int) {
        let parts = period.split(separator: " ")
        guard parts.count == 2,
              let year = Int(parts[1]) else {
            return (0, 0)
        }
        let monthName = String(parts[0]).lowercased()
        let monthMap = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]
        let month = monthMap[monthName] ?? 0
        return (year, month)
    }
}

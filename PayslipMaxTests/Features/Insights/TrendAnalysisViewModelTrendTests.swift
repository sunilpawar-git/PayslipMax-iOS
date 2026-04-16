import XCTest
@testable import PayslipMax

@MainActor
final class TrendAnalysisViewModelTrendTests: XCTestCase {

    private var sut: TrendAnalysisViewModel!
    private var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        sut = TrendAnalysisViewModel(dataService: mockDataService)
    }

    override func tearDown() {
        sut = nil
        mockDataService = nil
        super.tearDown()
    }

    // MARK: - Computed Properties

    func test_incomeStabilityDescription_withNoPayslips_returnsInsufficientData() {
        XCTAssertEqual(sut.incomeStabilityDescription, "Insufficient Data")
    }

    func test_incomeVariation_withNoPayslips_returnsZero() {
        XCTAssertEqual(sut.incomeVariation, 0, accuracy: 0.01)
    }

    func test_stabilityAnalysis_withNoPayslips_returnsNeedMoreData() {
        XCTAssertTrue(sut.stabilityAnalysis.contains("Need more data"))
    }

    func test_incomeStabilityDescription_withStableIncome_returnsVeryStable() {
        let payslips = (1...6).map { i in
            PayslipDTO(month: "Jan", year: 2025, credits: 50000 + Double(i))
        }
        sut.updatePayslips(payslips)

        XCTAssertEqual(sut.incomeStabilityDescription, "Very Stable")
    }

    func test_incomeStabilityDescription_withVariableIncome_returnsVariable() {
        let payslips = [
            PayslipDTO(month: "Jan", year: 2025, credits: 30000),
            PayslipDTO(month: "Feb", year: 2025, credits: 80000),
            PayslipDTO(month: "Mar", year: 2025, credits: 20000),
            PayslipDTO(month: "Apr", year: 2025, credits: 90000)
        ]
        sut.updatePayslips(payslips)

        XCTAssertEqual(sut.incomeStabilityDescription, "Variable")
    }

    // MARK: - Trend Generation

    func test_updatePayslips_withEmptyArray_setsTrendsEmpty() {
        sut.updatePayslips([])
        XCTAssertTrue(sut.trends.isEmpty)
    }

    func test_updatePayslips_withSinglePayslip_generatesTrends() {
        let payslips = [PayslipDTO(month: "Jan", year: 2025, credits: 50000)]
        sut.updatePayslips(payslips)

        XCTAssertFalse(sut.trends.isEmpty, "Should generate at least growth, stability, savings trends")
    }

    func test_updatePayslips_withTwoPayslips_includesGrowthTrend() {
        let payslips = [
            PayslipDTO(timestamp: Date(timeIntervalSince1970: 100), month: "Jan", year: 2025, credits: 50000),
            PayslipDTO(timestamp: Date(timeIntervalSince1970: 200), month: "Feb", year: 2025, credits: 55000)
        ]
        sut.updatePayslips(payslips)

        let growthTrend = sut.trends.first { $0.title == "Earnings Growth" }
        XCTAssertNotNil(growthTrend, "Should include an Earnings Growth trend")
    }

    func test_updatePayslips_withSixPayslips_includesProjectionTrend() {
        let payslips = (1...6).map { i in
            PayslipDTO(
                timestamp: Date(timeIntervalSince1970: Double(i * 100)),
                month: "Month\(i)",
                year: 2025,
                credits: 50000 + Double(i * 1000)
            )
        }
        sut.updatePayslips(payslips)

        let projectionTrend = sut.trends.first { $0.title == "Future Income Projection" }
        XCTAssertNotNil(projectionTrend, "With 6+ payslips, projection trend should be included")
    }

    func test_updatePayslips_withFivePayslips_excludesProjectionTrend() {
        let payslips = (1...5).map { i in
            PayslipDTO(
                timestamp: Date(timeIntervalSince1970: Double(i * 100)),
                month: "Month\(i)",
                year: 2025,
                credits: 50000
            )
        }
        sut.updatePayslips(payslips)

        let projectionTrend = sut.trends.first { $0.title == "Future Income Projection" }
        XCTAssertNil(projectionTrend, "With <6 payslips, projection trend should not be included")
    }

    func test_updatePayslips_alwaysIncludesStabilityAndSavings() {
        let payslips = [
            PayslipDTO(month: "Jan", year: 2025, credits: 50000),
            PayslipDTO(month: "Feb", year: 2025, credits: 55000)
        ]
        sut.updatePayslips(payslips)

        let stabilityTrend = sut.trends.first { $0.title == "Income Stability" }
        let savingsTrend = sut.trends.first { $0.title == "Savings Potential" }
        XCTAssertNotNil(stabilityTrend)
        XCTAssertNotNil(savingsTrend)
    }

    // MARK: - Color Mapping

    func test_incomeStabilityColor_withInsufficientData_returnsSecondary() {
        XCTAssertEqual(sut.incomeStabilityColor, FintechColors.textSecondary)
    }
}

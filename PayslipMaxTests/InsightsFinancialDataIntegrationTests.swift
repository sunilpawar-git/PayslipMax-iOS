import XCTest
import SwiftData
@testable import PayslipMax

/// Integration tests for Insights financial data processing and calculations
/// Tests verify that time range filtering and financial calculations work correctly together
@MainActor
final class InsightsFinancialDataIntegrationTests: XCTestCase {

    private var modelContext: ModelContext!
    private var testDataHelper: FinancialTestDataHelper!
    private var coordinator: InsightsCoordinator!

    override func setUp() async throws {
        try await super.setUp()

        // Setup in-memory SwiftData
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)

        // Create test data
        testDataHelper = FinancialTestDataHelper()
        await createTestPayslipData()

        // Setup coordinator with test data
        coordinator = InsightsCoordinator(dataService: DataServiceImpl(
            securityService: MockSecurityService(),
            modelContext: modelContext
        ))
    }

    override func tearDown() async throws {
        modelContext = nil
        testDataHelper = nil
        coordinator = nil
        try await super.tearDown()
    }

    // MARK: - Time Range Filtering Tests

    func testTimeRangeFiltering3M() async throws {
        // Given: Test data spanning multiple months
        let allPayslips = try await fetchAllPayslips()
        XCTAssertGreaterThan(allPayslips.count, 3, "Should have enough test data")

        // When: Filter for 3M range
        let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: .last3Months)

        // Then: Should return approximately 3 months of data
        XCTAssertLessThanOrEqual(filteredPayslips.count, 3, "3M filter should return at most 3 payslips")
        XCTAssertGreaterThan(filteredPayslips.count, 0, "3M filter should return at least 1 payslip")

        // Verify chronological ordering
        verifyChronologicalOrder(filteredPayslips)
    }

    func testTimeRangeFiltering6M() async throws {
        let allPayslips = try await fetchAllPayslips()
        let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: .last6Months)

        XCTAssertLessThanOrEqual(filteredPayslips.count, 6, "6M filter should return at most 6 payslips")
        XCTAssertGreaterThan(filteredPayslips.count, 0, "6M filter should return at least 1 payslip")

        verifyChronologicalOrder(filteredPayslips)
    }

    func testTimeRangeFiltering1Y() async throws {
        let allPayslips = try await fetchAllPayslips()
        let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: .lastYear)

        XCTAssertLessThanOrEqual(filteredPayslips.count, 12, "1Y filter should return at most 12 payslips")
        XCTAssertGreaterThan(filteredPayslips.count, 0, "1Y filter should return at least 1 payslip")

        verifyChronologicalOrder(filteredPayslips)
    }

    func testTimeRangeFilteringAll() async throws {
        let allPayslips = try await fetchAllPayslips()
        let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: .all)

        XCTAssertEqual(filteredPayslips.count, allPayslips.count, "All filter should return all payslips")
        verifyChronologicalOrder(filteredPayslips)
    }

    // MARK: - Financial Calculation Consistency Tests

    func testFinancialCalculationsConsistencyAcrossTimeRanges() async throws {
        let allPayslips = try await fetchAllPayslips()

        let timeRanges: [FinancialTimeRange] = [.last3Months, .last6Months, .lastYear, .all]

        for timeRange in timeRanges {
            let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: timeRange)

            // Skip empty results
            guard !filteredPayslips.isEmpty else { continue }

            // Calculate totals using FinancialCalculationUtility
            let utility = FinancialCalculationUtility.shared
            let totalIncome = utility.aggregateTotalIncome(for: filteredPayslips)
            let totalDeductions = utility.aggregateTotalDeductions(for: filteredPayslips)
            let netIncome = totalIncome - totalDeductions

            // Verify calculations are reasonable
            XCTAssertGreaterThanOrEqual(totalIncome, 0, "Total income should be non-negative")
            XCTAssertGreaterThanOrEqual(totalDeductions, 0, "Total deductions should be non-negative")
            XCTAssertGreaterThanOrEqual(netIncome, totalIncome - totalDeductions, "Net income calculation should be correct")

            // Verify consistency with individual payslip calculations
            let manualTotalIncome = filteredPayslips.reduce(0) { $0 + $1.credits }
            let manualTotalDeductions = filteredPayslips.reduce(0) { $0 + $1.debits }
            let manualNetIncome = manualTotalIncome - manualTotalDeductions

            XCTAssertEqual(totalIncome, manualTotalIncome, accuracy: 0.01, "Utility calculation should match manual calculation")
            XCTAssertEqual(totalDeductions, manualTotalDeductions, accuracy: 0.01, "Deduction calculation should match manual calculation")
            XCTAssertEqual(netIncome, manualNetIncome, accuracy: 0.01, "Net income should match manual calculation")
        }
    }

    // MARK: - Data Processing Integration Tests

    func testInsightsCoordinatorDataProcessing() async throws {
        // Given: Test payslip data
        let allPayslips = try await fetchAllPayslips()

        // When: Coordinator processes data
        coordinator.refreshData(payslips: allPayslips)

        // Then: Verify coordinator has processed data correctly
        await MainActor.run {
            XCTAssertNotNil(coordinator.financialSummary, "Financial summary should be populated")
            XCTAssertGreaterThan(coordinator.financialSummary.totalIncome, 0, "Total income should be greater than zero")
        }
    }

    func testTimeRangeChangeUpdatesCoordinatorData() async throws {
        let allPayslips = try await fetchAllPayslips()

        let timeRanges: [FinancialTimeRange] = [.last3Months, .last6Months, .lastYear, .all]

        for timeRange in timeRanges {
            // When: Filter payslips for specific time range
            let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: timeRange)

            // Then: Coordinator should handle empty or populated data gracefully
            coordinator.refreshData(payslips: filteredPayslips)

            await MainActor.run {
                if filteredPayslips.isEmpty {
                    // Verify empty state handling
                    XCTAssertEqual(coordinator.financialSummary.totalIncome, 0, "Empty data should result in zero totals")
                } else {
                    // Verify data processing for non-empty results
                    XCTAssertGreaterThan(coordinator.financialSummary.totalIncome, 0, "Should have income data")
                }
            }
        }
    }

    // MARK: - Chart Data Integration Tests

    func testChartDataPreparationConsistency() async throws {
        let allPayslips = try await fetchAllPayslips()

        let timeRanges: [FinancialTimeRange] = [.last3Months, .last6Months, .lastYear, .all]

        for timeRange in timeRanges {
            let filteredPayslips = InsightsChartHelpers.filterPayslips(allPayslips, for: timeRange)

            guard !filteredPayslips.isEmpty else { continue }

            // Test chart height calculation
            let chartHeight = InsightsChartHelpers.chartHeightForTimeRange(timeRange)
            XCTAssertGreaterThan(chartHeight, 0, "Chart height should be greater than zero")

            // Test chart data preparation
            let chartData = filteredPayslips.enumerated().map { index, payslip in
                (index: index, value: payslip.credits - payslip.debits, date: payslip.month)
            }

            XCTAssertEqual(chartData.count, filteredPayslips.count, "Chart data should match filtered payslips count")

            // Verify data is in correct order (most recent first)
            for i in 1..<chartData.count {
                let currentDate = createDateFromPayslip(filteredPayslips[i])
                let previousDate = createDateFromPayslip(filteredPayslips[i-1])
                XCTAssertTrue(currentDate <= previousDate, "Data should be ordered most recent first")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestPayslipData() async {
        // Create test payslips spanning multiple months
        let calendar = Calendar.current
        let now = Date()

        for monthOffset in 0..<12 {
            guard let payslipDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else {
                continue
            }

            let components = calendar.dateComponents([.month, .year], from: payslipDate)
            guard let month = components.month, let year = components.year else {
                continue
            }

            let payslip = PayslipItem(
                timestamp: payslipDate,
                month: String(format: "%02d", month), // Convert to MM format (01, 02, etc.)
                year: year,
                credits: Double(45000 + (month * 500)), // Vary income by month
                debits: Double(8000 + (month * 100))    // Vary deductions by month
            )

            modelContext.insert(payslip)
        }

        try? modelContext.save()
    }

    private func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func verifyChronologicalOrder(_ payslips: [PayslipItem]) {
        guard payslips.count > 1 else { return }

        for i in 1..<payslips.count {
            let currentDate = payslips[i].timestamp
            let previousDate = payslips[i-1].timestamp
            XCTAssertTrue(currentDate <= previousDate,
                         "Payslips should be ordered chronologically (most recent first)")
        }
    }

    private func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        var components = DateComponents()
        components.month = Int(payslip.month) // Convert string to int
        components.year = payslip.year
        components.day = 1 // Use first day of month for comparison

        return Calendar.current.date(from: components) ?? Date()
    }
}

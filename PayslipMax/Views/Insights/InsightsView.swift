import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var coordinator: InsightsCoordinator
    @State private var selectedTimeRange: FinancialTimeRange = .last3Months

    init(coordinator: InsightsCoordinator) {
        self._coordinator = StateObject(wrappedValue: coordinator)
    }

    // Computed property to filter payslips based on selected time range
    private var filteredPayslips: [PayslipItem] {
        return InsightsChartHelpers.filterPayslips(Array(payslips), for: selectedTimeRange)
    }

    // Map the UI picker range to the coordinator's time range used for chart grouping
    private func insightsTimeRange(for range: FinancialTimeRange) -> TimeRange {
        switch range {
        case .last3Months, .last6Months, .lastYear, .all:
            return .month
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                FintechColors.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Time range picker - Controls entire screen data
                        InsightsTimeRangePicker(selectedTimeRange: $selectedTimeRange)

                        // Enhanced integrated financial overview with charts
                        InsightsFinancialOverviewSection(
                            coordinator: coordinator,
                            filteredPayslips: filteredPayslips,
                            selectedTimeRange: selectedTimeRange
                        )

                        // Key insights
                        InsightsKeyInsightsSection(coordinator: coordinator)

                        // Detailed analysis
                        InsightsDetailedAnalysisSection(coordinator: coordinator)

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                coordinator.timeRange = insightsTimeRange(for: selectedTimeRange)
                let filtered = InsightsChartHelpers.filterPayslips(Array(payslips), for: selectedTimeRange, log: true)
                print("🔍 InsightsView onAppear: Refreshing with \(filtered.count) filtered payslips")
                coordinator.refreshData(payslips: filtered.map { PayslipDTO(from: $0) })
            }
            .onChange(of: selectedTimeRange) {
                print("🔍 InsightsView time range changed to \(selectedTimeRange): Refreshing with \(filteredPayslips.count) filtered payslips")
                coordinator.timeRange = insightsTimeRange(for: selectedTimeRange)
                let filtered = InsightsChartHelpers.filterPayslips(Array(payslips), for: selectedTimeRange, log: true)
                // Update coordinator when time range changes
                coordinator.refreshData(payslips: filtered.map { PayslipDTO(from: $0) })
            }
        }
    }

}

import Foundation
@testable import PayslipMax

// MARK: - Mock Chart Data Preparation Service

/// Mock implementation of ChartDataPreparationService for testing purposes.
/// Provides configurable behavior for chart data preparation operations.
class MockChartDataPreparationService: ChartDataPreparationService {
    var prepareChartDataCalled = false
    var mockChartData: [PayslipChartData] = []

    /// Prepares chart data in background with configurable mock results
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        prepareChartDataCalled = true
        return mockChartData
    }

    /// Resets tracking flags and mock data to default values
    func reset() {
        prepareChartDataCalled = false
        mockChartData = []
    }
}

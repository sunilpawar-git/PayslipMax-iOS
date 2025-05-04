import Foundation
@testable import PayslipMax

class MockChartDataPreparationService: ChartDataPreparationService {
    var prepareChartDataCallCount = 0
    var preparePayslipComparisonDataCallCount = 0
    var mockChartData: [ChartDataPoint] = []
    var mockComparisonData: PayslipComparisonData = PayslipComparisonData(
        earnings: [], 
        deductions: [], 
        netPay: []
    )
    
    override func prepareChartData(from payslips: [AnyPayslip]) -> [ChartDataPoint] {
        prepareChartDataCallCount += 1
        return mockChartData
    }
    
    override func preparePayslipComparisonData(from payslips: [AnyPayslip]) -> PayslipComparisonData {
        preparePayslipComparisonDataCallCount += 1
        return mockComparisonData
    }
    
    func reset() {
        prepareChartDataCallCount = 0
        preparePayslipComparisonDataCallCount = 0
        mockChartData = []
        mockComparisonData = PayslipComparisonData(
            earnings: [], 
            deductions: [], 
            netPay: []
        )
    }
} 
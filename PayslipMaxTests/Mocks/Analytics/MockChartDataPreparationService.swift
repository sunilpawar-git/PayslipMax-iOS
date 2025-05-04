import Foundation
@testable import PayslipMax

class MockChartDataPreparationService: ChartDataPreparationServiceProtocol {
    var prepareCallCount = 0
    var shouldFail = false
    var result: ChartData?
    
    func prepareChartData(from payslips: [PayslipItem]) async throws -> ChartData {
        prepareCallCount += 1
        
        if shouldFail {
            throw MockError.processingFailed
        }
        
        if let result = result {
            return result
        }
        
        // Return basic empty chart data if no specific result is set
        return ChartData(
            months: [],
            credits: [],
            debits: [],
            net: []
        )
    }
    
    func reset() {
        prepareCallCount = 0
        shouldFail = false
        result = nil
    }
} 
import Foundation

/// A service for preparing chart data from payslips
class ChartDataPreparationService {
    /// Initializes a new chart data preparation service
    init() {}
    
    /// Prepares chart data from the specified payslips
    /// - Parameter payslips: The payslips to prepare chart data from
    /// - Returns: An array of chart data items
    func prepareChartData(from payslips: [AnyPayslip]) -> [PayslipChartData] {
        var chartDataArray: [PayslipChartData] = []
        
        // Group payslips by month and year
        for payslip in payslips {
            let month = "\(payslip.month)"
            let credits = payslip.credits
            let debits = payslip.debits
            let net = credits - debits
            
            // Create chart data for this payslip
            let chartData = PayslipChartData(
                month: month,
                credits: credits,
                debits: debits,
                net: net
            )
            
            chartDataArray.append(chartData)
        }
        
        return chartDataArray
    }
    
    /// Prepares chart data asynchronously from the specified payslips
    /// - Parameter payslips: The payslips to prepare chart data from
    /// - Returns: An array of chart data items
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        // This could be more complex in the future, with filtering or processing
        // For now, we're just delegating to the synchronous method
        return prepareChartData(from: payslips)
    }
} 
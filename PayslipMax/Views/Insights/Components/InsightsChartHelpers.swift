import Foundation
import SwiftUI

/// Helper functions for InsightsView chart data preparation
struct InsightsChartHelpers {
    
    /// Creates a Date object from a payslip's period (month/year), not the creation timestamp
    /// This matches the logic used in PayslipsView for consistent date handling
    static func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        // Always use the payslip period (month/year) for insights filtering
        // not the creation timestamp which is always recent
        let monthInt = monthToInt(payslip.month)
        let year = payslip.year
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthInt > 0 ? monthInt : 1 // Default to January if month parsing fails
        dateComponents.day = 1 // Use first day of the month
        
        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
    }
    
    /// Converts month string to integer
    static func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        // Try full month name first
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Try abbreviated month name
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Try numeric month
        if let monthNum = Int(month), monthNum >= 1, monthNum <= 12 {
            return monthNum
        }
        
        return 0 // Invalid month
    }
    
    /// Calculates chart height based on time range selection
    static func chartHeightForTimeRange(_ timeRange: FinancialTimeRange) -> CGFloat {
        switch timeRange {
        case .last3Months:
            return 55
        case .last6Months:
            return 60
        case .lastYear:
            return 70
        case .all:
            return 80
        }
    }
    
    /// Filters payslips based on selected time range
    static func filterPayslips(_ payslips: [PayslipItem], for timeRange: FinancialTimeRange) -> [PayslipItem] {
        let sortedPayslips = payslips.sorted(by: { 
            let date1 = createDateFromPayslip($0)
            let date2 = createDateFromPayslip($1)
            return date1 > date2
        })
        
        // Use the latest payslip's period as the reference point instead of current date
        // This ensures we get the correct count (12 for 1Y, 6 for 6M, 3 for 3M)
        guard let latestPayslip = sortedPayslips.first else {
            print("❌ No payslips available")
            return []
        }
        
        let latestPayslipDate = createDateFromPayslip(latestPayslip)
        let calendar = Calendar.current
        
        print("🔍 InsightsView filtering: Total payslips: \(payslips.count), Selected range: \(timeRange)")
        print("📅 Latest payslip period: \(latestPayslip.month) \(latestPayslip.year)")
        
        // Debug: Print payslip date ranges using period dates (not timestamps)
        if !sortedPayslips.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let oldestDate = createDateFromPayslip(sortedPayslips.last!)
            let newestDate = createDateFromPayslip(sortedPayslips.first!)
            print("📅 Payslip period range: \(formatter.string(from: oldestDate)) to \(formatter.string(from: newestDate))")
        }
        
        switch timeRange {
        case .last3Months:
            // Calculate 3 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -2, to: latestPayslipDate) else {
                print("❌ Failed to calculate 3M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 3M filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
            return filtered
            
        case .last6Months:
            // Calculate 6 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -5, to: latestPayslipDate) else {
                print("❌ Failed to calculate 6M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 6M filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
            return filtered
            
        case .lastYear:
            // Calculate 12 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -11, to: latestPayslipDate) else {
                print("❌ Failed to calculate 1Y cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 1Y filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
            return filtered
            
        case .all:
            print("✅ ALL filter: returning all \(sortedPayslips.count) payslips")
            return sortedPayslips
        }
    }
}

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
    static func filterPayslips(_ payslips: [PayslipItem], for timeRange: FinancialTimeRange, log: Bool = false) -> [PayslipItem] {
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

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let latestPayslipDate = createDateFromPayslip(latestPayslip)
        let calendar = Calendar.current

        var filtered: [PayslipItem] = []

        switch timeRange {
        case .last3Months:
            // Calculate 3 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -2, to: latestPayslipDate) else {
                if log { print("❌ Failed to calculate 3M cutoff date") }
                return sortedPayslips
            }
            if log { self.logFilterStart(total: payslips.count, range: timeRange, latest: latestPayslipDate, formatter: formatter) }
            filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            if log { self.logFilterResult(filtered: filtered, sortedPayslips: sortedPayslips, cutoffDate: cutoffDate, formatter: formatter) }
            return filtered

        case .last6Months:
            // Calculate 6 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -5, to: latestPayslipDate) else {
                if log { print("❌ Failed to calculate 6M cutoff date") }
                return sortedPayslips
            }
            if log { self.logFilterStart(total: payslips.count, range: timeRange, latest: latestPayslipDate, formatter: formatter) }
            filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            if log { self.logFilterResult(filtered: filtered, sortedPayslips: sortedPayslips, cutoffDate: cutoffDate, formatter: formatter) }
            return filtered

        case .lastYear:
            // Calculate 12 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -11, to: latestPayslipDate) else {
                if log { print("❌ Failed to calculate 1Y cutoff date") }
                return sortedPayslips
            }
            if log { self.logFilterStart(total: payslips.count, range: timeRange, latest: latestPayslipDate, formatter: formatter) }
            filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            if log { self.logFilterResult(filtered: filtered, sortedPayslips: sortedPayslips, cutoffDate: cutoffDate, formatter: formatter) }
            return filtered

        case .all:
            if log {
                self.logFilterStart(total: payslips.count, range: timeRange, latest: latestPayslipDate, formatter: formatter)
                self.logFilterResult(filtered: sortedPayslips, sortedPayslips: sortedPayslips, cutoffDate: nil, formatter: formatter)
            }
            return sortedPayslips
        }
    }

    // MARK: - Logging helpers

    private static func logFilterStart(total: Int, range: FinancialTimeRange, latest: Date, formatter: DateFormatter) {
        print("🔍 InsightsView filtering: total=\(total), selected=\(range)")
        print("📅 Latest payslip period: \(formatter.string(from: latest))")
    }

    private static func logFilterResult(
        filtered: [PayslipItem],
        sortedPayslips: [PayslipItem],
        cutoffDate: Date?,
        formatter: DateFormatter
    ) {
        if let cutoffDate {
            print("📆 Cutoff date: \(formatter.string(from: cutoffDate))")
        }

        if let oldest = filtered.last.map(createDateFromPayslip),
           let newest = filtered.first.map(createDateFromPayslip) {
            print("📅 Filtered period range: \(formatter.string(from: oldest)) to \(formatter.string(from: newest))")
        } else if let oldest = sortedPayslips.last.map(createDateFromPayslip),
                  let newest = sortedPayslips.first.map(createDateFromPayslip) {
            // Fallback to full range if filtered is empty
            print("📅 Filtered period range: \(formatter.string(from: oldest)) to \(formatter.string(from: newest))")
        }

        print("✅ Filter result: \(filtered.count) of \(sortedPayslips.count) payslips\n")
    }
}

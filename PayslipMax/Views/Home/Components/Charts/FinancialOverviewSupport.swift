//
//  FinancialOverviewSupport.swift
//  PayslipMax
//
//  Created by GlobalDataTech on 2024
//  Architecture: MVVM-SOLID compliant business logic support
//  Lines: ~180 (well under 300-line limit)

import Foundation

/// Utility class for financial data filtering and calculations
/// Architecture: Protocol-based design, single responsibility for data processing
protocol FinancialDataProcessorProtocol {
    func filterPayslips(_ payslips: [PayslipItem], for timeRange: FinancialTimeRange) -> [PayslipItem]
    func calculateTotalNet(_ payslips: [PayslipItem]) -> Double
    func calculateAverageMonthly(_ payslips: [PayslipItem]) -> Double
    func calculateTrendDirection(_ payslips: [PayslipItem]) -> TrendDirection
    func createDateFromPayslip(_ payslip: PayslipItem) -> Date
}

/// Implementation of financial data processing logic
/// Architecture: SOLID compliant, dependency injectable
final class FinancialDataProcessor: FinancialDataProcessorProtocol {

    /// Filters payslips based on the selected time range
    /// Architecture: Pure function with clear input/output contract
    func filterPayslips(_ payslips: [PayslipItem], for timeRange: FinancialTimeRange) -> [PayslipItem] {
        let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }

        guard let latestPayslip = sortedPayslips.first else {
            print("❌ No payslips available for filtering")
            return []
        }

        let latestPayslipDate = createDateFromPayslip(latestPayslip)
        let calendar = Calendar.current

        print("🏠 FinancialDataProcessor filtering: Total payslips: \(payslips.count), Selected range: \(timeRange)")

        switch timeRange {
        case .last3Months:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -3, to: latestPayslipDate) else {
                print("❌ Failed to calculate 3 month cutoff date")
                return sortedPayslips
            }

            let filtered = sortedPayslips.filter { payslip in
                let payslipDate = createDateFromPayslip(payslip)
                return payslipDate >= cutoffDate
            }

            print("3M filtered result: \(filtered.count) payslips")
            return filtered

        case .last6Months:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -6, to: latestPayslipDate) else {
                print("❌ Failed to calculate 6 month cutoff date")
                return sortedPayslips
            }

            let filtered = sortedPayslips.filter { payslip in
                let payslipDate = createDateFromPayslip(payslip)
                return payslipDate >= cutoffDate
            }

            print("6M filtered result: \(filtered.count) payslips")
            return filtered

        case .lastYear:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: latestPayslipDate) else {
                print("❌ Failed to calculate 1 year cutoff date")
                return sortedPayslips
            }

            let filtered = sortedPayslips.filter {
                let payslipDate = createDateFromPayslip($0)
                return payslipDate >= cutoffDate
            }

            print("1Y filtered result: \(filtered.count) payslips")
            return filtered

        case .all:
            print("ALL: returning all \(sortedPayslips.count) payslips")
            return sortedPayslips
        }
    }

    /// Calculates total net remittance from payslips
    /// Architecture: Pure function, single mathematical operation
    func calculateTotalNet(_ payslips: [PayslipItem]) -> Double {
        let net = payslips.reduce(0) { $0 + ($1.credits - $1.debits) }
        print("💰 Total net from \(payslips.count) payslips: ₹\(net)")
        return net
    }

    /// Calculates average monthly remittance
    /// Architecture: Pure function, mathematical calculation
    func calculateAverageMonthly(_ payslips: [PayslipItem]) -> Double {
        guard !payslips.isEmpty else { return 0 }
        return calculateTotalNet(payslips) / Double(payslips.count)
    }

    /// Calculates trend direction based on recent vs older data
    /// Architecture: Pure function with clear algorithm
    func calculateTrendDirection(_ payslips: [PayslipItem]) -> TrendDirection {
        guard payslips.count >= 2 else { return .neutral }

        let recent = Array(payslips.prefix(3))
        let older = Array(payslips.dropFirst(3).prefix(3))

        let recentAvg = recent.reduce(0) { $0 + ($1.credits - $1.debits) } / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0) { $0 + ($1.credits - $1.debits) } / Double(older.count)

        if recentAvg > olderAvg * 1.05 {
            return .up
        } else if recentAvg < olderAvg * 0.95 {
            return .down
        } else {
            return .neutral
        }
    }

    /// Creates a Date object from a payslip's period information
    /// Architecture: Pure function, date parsing utility
    func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        let monthInt = monthToInt(payslip.month)
        let year = payslip.year

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthInt > 0 ? monthInt : 1 // Default to January if month parsing fails
        dateComponents.day = 1 // Use first day of the month

        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
    }

    /// Converts month name to integer for date calculations
    /// Architecture: Pure function, string parsing utility
    private func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }

        // Fallback for short month names
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }

        // Manual mapping for common cases
        let monthMap = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]

        return monthMap[month.lowercased()] ?? 0
    }
}

/// Extension providing convenience properties for FinancialTimeRange
/// Architecture: Clean extension pattern, single responsibility
extension FinancialTimeRange {
    /// Returns appropriate chart subtitle for time range
    var chartSubtitle: String {
        switch self {
        case .last3Months:
            return "3-month trend"
        case .last6Months:
            return "6-month trend"
        case .lastYear:
            return "Annual trend"
        case .all:
            return "Complete history"
        }
    }

    /// Returns appropriate chart height for time range
    var chartHeight: CGFloat {
        switch self {
        case .last3Months:
            return 55 // Very compact for fewer data points
        case .last6Months:
            return 60 // Compact for fewer data points
        case .lastYear:
            return 70 // Standard height
        case .all:
            return 80 // Taller for comprehensive view
        }
    }
}

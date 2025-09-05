import Foundation

/// Service responsible for grouping payslips by various criteria for presentation
class PayslipGroupingService {
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Groups payslips by month and year for sectioned display
    /// - Parameter payslips: The payslips to group
    /// - Returns: A dictionary with month/year keys and payslip arrays as values
    func groupByMonthYear(_ payslips: [AnyPayslip]) -> [String: [AnyPayslip]] {
        return Dictionary(grouping: payslips) { payslip in
            let month = payslip.month
            let year = payslip.year
            return "\(month) \(year)"
        }
    }
    
    /// Creates sorted section keys from grouped payslips (newest first)
    /// - Parameter groupedPayslips: Dictionary of grouped payslips
    /// - Returns: Array of sorted section keys
    func createSortedSectionKeys(from groupedPayslips: [String: [AnyPayslip]]) -> [String] {
        return groupedPayslips.keys.sorted {
            let date1 = createDateFromSectionKey($0)
            let date2 = createDateFromSectionKey($1)
            return date1 > date2 // Newest first (descending order)
        }
    }
    
    /// Creates a Date object from a section key (e.g., "January 2025")
    /// - Parameter key: The section key
    /// - Returns: A Date object for comparison
    private func createDateFromSectionKey(_ key: String) -> Date {
        // Try to parse with the formatter
        if let date = monthYearFormatter.date(from: key) {
            return date
        }
        
        // Fallback: Try to extract year and month manually
        let components = key.components(separatedBy: " ")
        guard components.count >= 2,
              let year = Int(components.last ?? ""),
              let monthName = components.dropLast().joined(separator: " ").isEmpty ? nil : components.dropLast().joined(separator: " ") else {
            return Date() // Fallback to current date
        }
        
        // Create date components
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        
        // Convert month name to month number
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        monthFormatter.locale = Locale(identifier: "en_US")
        
        if let monthDate = monthFormatter.date(from: monthName) {
            dateComponents.month = calendar.component(.month, from: monthDate)
        } else {
            dateComponents.month = 1 // Default to January
        }
        
        dateComponents.day = 1
        
        return calendar.date(from: dateComponents) ?? Date()
    }
}

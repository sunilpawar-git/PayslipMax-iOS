import Foundation

/// Service responsible for sorting payslips according to different criteria
class PayslipSortingService {
    
    /// Sorts payslips according to the specified sort order
    /// - Parameters:
    ///   - payslips: The payslips to sort
    ///   - sortOrder: The sort order to apply
    /// - Returns: Sorted payslips
    func sort(_ payslips: [AnyPayslip], by sortOrder: PayslipSortOrder) -> [AnyPayslip] {
        var sortedPayslips = payslips
        
        switch sortOrder {
        case .dateAscending:
            sortedPayslips.sort { lhs, rhs in
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate < rhsDate
            }
        case .dateDescending:
            sortedPayslips.sort { lhs, rhs in
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate > rhsDate
            }
        case .amountAscending:
            sortedPayslips.sort { $0.credits < $1.credits }
        case .amountDescending:
            sortedPayslips.sort { $0.credits > $1.credits }
        case .nameAscending:
            sortedPayslips.sort { $0.name < $1.name }
        case .nameDescending:
            sortedPayslips.sort { $0.name > $1.name }
        }
        
        return sortedPayslips
    }
    
    /// Creates a Date object from a payslip for comparison
    /// - Parameter payslip: The payslip to create a date from
    /// - Returns: A Date object representing the payslip's date
    private func createDateFromPayslip(_ payslip: AnyPayslip) -> Date {
        // Try to use the timestamp if available (it's not optional but check if it's meaningful)
        let timestamp = payslip.timestamp
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        if timestamp > oneYearAgo {
            return timestamp
        }
        
        // Fallback: Create date from month and year
        let monthName = payslip.month
        let year = payslip.year
        
        // Create a date formatter for month names
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        
        let dateString = "\(monthName) \(year)"
        
        // Try to parse the date
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Final fallback: Use January of the year if month parsing fails
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        
        return calendar.date(from: components) ?? Date()
    }
}

/// The sort order for payslips.
enum PayslipSortOrder: String, CaseIterable, Identifiable {
    case dateAscending = "date_ascending"
    case dateDescending = "date_descending"
    case amountAscending = "amount_ascending"
    case amountDescending = "amount_descending"
    case nameAscending = "name_ascending"
    case nameDescending = "name_descending"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dateAscending:
            return "Date (Oldest First)"
        case .dateDescending:
            return "Date (Newest First)"
        case .amountAscending:
            return "Amount (Low to High)"
        case .amountDescending:
            return "Amount (High to Low)"
        case .nameAscending:
            return "Name (A to Z)"
        case .nameDescending:
            return "Name (Z to A)"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dateAscending:
            return "calendar.badge.plus"
        case .dateDescending:
            return "calendar.badge.minus"
        case .amountAscending:
            return "arrow.up.circle"
        case .amountDescending:
            return "arrow.down.circle"
        case .nameAscending:
            return "textformat.alt"
        case .nameDescending:
            return "textformat"
        }
    }
}

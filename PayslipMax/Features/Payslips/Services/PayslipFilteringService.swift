import Foundation

/// Service responsible for filtering payslips based on search criteria
class PayslipFilteringService {
    
    /// Filters payslips based on search text
    /// - Parameters:
    ///   - payslips: The payslips to filter
    ///   - searchText: The search text to apply
    /// - Returns: Filtered payslips
    func filter(_ payslips: [AnyPayslip], searchText: String) -> [AnyPayslip] {
        guard !searchText.isEmpty else { return payslips }
        
        return payslips.filter { payslip in
            payslip.name.localizedCaseInsensitiveContains(searchText) ||
            payslip.month.localizedCaseInsensitiveContains(searchText) ||
            String(payslip.year).localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Checks if search filters are active
    /// - Parameter searchText: The current search text
    /// - Returns: True if filters are active
    func hasActiveFilters(searchText: String) -> Bool {
        return !searchText.isEmpty
    }
}

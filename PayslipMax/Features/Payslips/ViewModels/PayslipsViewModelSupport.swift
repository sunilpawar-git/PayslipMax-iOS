import Foundation

// MARK: - PayslipsViewModel Support Extension
extension PayslipsViewModel {

    // MARK: - Computed Properties

    /// The filtered and sorted payslips based on the current search text and sort order.
    var filteredPayslips: [AnyPayslip] {
        let result = filterPayslips(payslips)

        #if DEBUG
        print("PayslipsViewModel: Filtered payslips count: \(result.count), Sort order: \(sortOrder)")
        #endif

        return result
    }

    /// Whether there are active filters.
    var hasActiveFilters: Bool {
        return filteringService.hasActiveFilters(searchText: searchText)
    }

    // MARK: - Data Processing

    // MARK: - Error Handling

    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }

    // MARK: - Helper Methods

    /// Converts a month name to an integer for sorting.
    ///
    /// - Parameter month: The month name to convert.
    /// - Returns: The month as an integer (1-12), or 0 if the conversion fails.
    func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"

        if let date = formatter.date(from: month) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }

        // If month is a number string, convert directly
        if let monthNum = Int(month) {
            return monthNum
        }

        return 0 // Default for unknown month format
    }
}

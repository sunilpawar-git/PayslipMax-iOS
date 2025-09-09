import Foundation

/// Protocol for component categorization functionality
/// Part of the unified architecture for consistent categorization across the app
protocol ComponentCategorizationServiceProtocol {
    /// Called when a user categorizes an unknown component
    ///
    /// - Parameters:
    ///   - code: The component code
    ///   - category: The category to assign
    ///   - unknownComponents: The dictionary of unknown components
    ///   - payslipData: The current payslip data (will be modified)
    func categorizeComponent(
        code: String,
        asCategory category: String,
        unknownComponents: inout [String: (Double, String)],
        payslipData: inout PayslipData
    )
}

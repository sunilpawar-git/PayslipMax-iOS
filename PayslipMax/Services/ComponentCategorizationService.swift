import Foundation
// swiftlint:disable no_hardcoded_strings
/// Service responsible for categorizing unknown components in payslips
/// Part of the unified architecture for consistent categorization across the app
@MainActor
class ComponentCategorizationService: ComponentCategorizationServiceProtocol {
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
    ) {
        guard let (amount, _) = unknownComponents[code] else {
            return
        }

        // Update the category in the unknown components dictionary
        unknownComponents[code] = (amount, category)

        // Also update the appropriate earnings or deductions collection
        switch category.lowercased() {
        case "earnings":
            var updatedEarnings = payslipData.allEarnings
            updatedEarnings[code] = amount
            payslipData.allEarnings = updatedEarnings
        case "deductions":
            var updatedDeductions = payslipData.allDeductions
            updatedDeductions[code] = amount
            payslipData.allDeductions = updatedDeductions
        default:
            // Handle other categories if needed
            break
        }
    }
}
// swiftlint:enable no_hardcoded_strings

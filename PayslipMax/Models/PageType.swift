import Foundation

/// Represents the type of a payslip page
enum PageType {
    /// Page containing the main financial summary (earnings, deductions, net pay).
    case mainSummary
    /// Page detailing income tax calculations and deductions.
    case incomeTaxDetails
    /// Page detailing DSOP fund contributions, withdrawals, and balances.
    case dsopFundDetails
    /// Page containing contact information for inquiries.
    case contactDetails
    /// Any other type of page not specifically categorized.
    case other
} 
import Foundation

/// Data structure for manual entry of payslip information
struct PayslipManualEntryData {
    /// Name of the payslip owner.
    let name: String
    /// Month of the payslip period.
    let month: String
    /// Year of the payslip period.
    let year: Int
    /// Total credits (earnings) entered.
    let credits: Double
    /// Total debits (deductions) entered.
    let debits: Double
    /// Tax amount entered.
    let tax: Double
    /// DSOP contribution entered.
    let dsop: Double
} 
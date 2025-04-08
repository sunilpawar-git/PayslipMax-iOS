import Foundation

/// Data structure for manual entry of payslip information
struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let tax: Double
    let dsop: Double
} 
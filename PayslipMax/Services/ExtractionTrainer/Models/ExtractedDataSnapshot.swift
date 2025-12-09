import Foundation

/// A snapshot of extracted data.
struct ExtractedDataSnapshot: Codable {
    /// The name of the employee.
    let name: String

    /// The month of the payslip.
    let month: String

    /// The year of the payslip.
    let year: Int

    /// The credits (net pay) amount.
    let credits: Double

    /// The debits (deductions) amount.
    let debits: Double

    /// The DSOP amount.
    let dsop: Double

    /// The tax amount.
    let tax: Double

    /// The account number.
    let accountNumber: String

    /// The PAN number.
    let panNumber: String

    /// Initializes a new ExtractedDataSnapshot from a PayslipProtocol.
    ///
    /// - Parameter payslip: The payslip to create a snapshot from.
    init(from payslip: AnyPayslip) {
        self.name = payslip.name
        self.month = payslip.month
        self.year = payslip.year
        self.credits = payslip.credits
        self.debits = payslip.debits
        self.dsop = payslip.dsop
        self.tax = payslip.tax
        self.accountNumber = payslip.accountNumber
        self.panNumber = payslip.panNumber
    }
}

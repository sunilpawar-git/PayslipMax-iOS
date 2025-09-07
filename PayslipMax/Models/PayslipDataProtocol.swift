import Foundation

/// Protocol defining the financial data properties of a payslip item.
///
/// This protocol provides the financial data properties that are required
/// by all payslip items, allowing for better organization of concerns.
protocol PayslipDataProtocol: PayslipBaseProtocol {
    // MARK: - Basic Information
    
    /// The month of the payslip.
    var month: String { get set }
    
    /// The year of the payslip.
    var year: Int { get set }
    
    // MARK: - Financial Data
    
    /// The total credits (income) in the payslip.
    var credits: Double { get set }
    
    /// The total debits (expenses) in the payslip.
    var debits: Double { get set }
    
    /// The DSOP (Defense Services Officers Provident Fund) contribution.
    var dsop: Double { get set }
    
    /// The tax deduction in the payslip.
    var tax: Double { get set }
    
    /// The detailed earnings breakdown (optional).
    var earnings: [String: Double] { get set }
    
    /// The detailed deductions breakdown (optional).
    var deductions: [String: Double] { get set }
}

// MARK: - Default Implementations

extension PayslipDataProtocol {
    /// Calculates the net amount in the payslip.
    ///
    /// The net amount is calculated as credits minus debits.
    /// DSOP and tax are already included in the debits total.
    ///
    /// - Returns: The net amount.
    func calculateNetAmount() -> Double {
        return credits - debits
    }
} 
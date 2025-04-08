import Foundation

/// Protocol defining the core functionality of a payslip item.
///
/// This protocol provides a common interface for different implementations
/// of payslip items, allowing for better testability and flexibility.
protocol PayslipItemProtocol: Identifiable, Codable {
    // MARK: - Core Properties
    
    /// The unique identifier of the payslip item.
    var id: UUID { get }
    
    /// The month of the payslip.
    var month: String { get set }
    
    /// The year of the payslip.
    var year: Int { get set }
    
    /// The total credits (income) in the payslip.
    var credits: Double { get set }
    
    /// The total debits (expenses) in the payslip.
    var debits: Double { get set }
    
    /// The DSOP (Defense Services Officers Provident Fund) contribution.
    var dsop: Double { get set }
    
    /// The tax deduction in the payslip.
    var tax: Double { get set }
    
    /// The name of the employee.
    var name: String { get set }
    
    /// The account number of the employee.
    var accountNumber: String { get set }
    
    /// The PAN (Permanent Account Number) of the employee.
    var panNumber: String { get set }
    
    /// The timestamp when the payslip was created or processed.
    var timestamp: Date { get set }
    
    // MARK: - Optional Properties
    
    /// The detailed earnings breakdown (optional).
    var earnings: [String: Double] { get set }
    
    /// The detailed deductions breakdown (optional).
    var deductions: [String: Double] { get set }
    
    // MARK: - Sensitive Data Handling
    
    /// Encrypts sensitive data in the payslip.
    ///
    /// This method encrypts personal information such as name, account number,
    /// and PAN number to protect the employee's privacy.
    ///
    /// - Throws: An error if encryption fails.
    func encryptSensitiveData() throws
    
    /// Decrypts sensitive data in the payslip.
    ///
    /// This method decrypts personal information such as name, account number,
    /// and PAN number to make it readable.
    ///
    /// - Throws: An error if decryption fails.
    func decryptSensitiveData() throws
}

// MARK: - Default Implementations

extension PayslipItemProtocol {
    /// Calculates the net amount in the payslip.
    ///
    /// The net amount is calculated as credits minus debits.
    /// DSOP and tax are already included in the debits total.
    ///
    /// - Returns: The net amount.
    func calculateNetAmount() -> Double {
        return credits - debits
    }
    
    /// Creates a formatted string representation of the payslip.
    ///
    /// - Returns: A formatted string with payslip details.
    func formattedDescription() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        let creditsStr = formatter.string(from: NSNumber(value: credits)) ?? "\(credits)"
        let debitsStr = formatter.string(from: NSNumber(value: debits)) ?? "\(debits)"
        let dsopStr = formatter.string(from: NSNumber(value: dsop)) ?? "\(dsop)"
        let taxStr = formatter.string(from: NSNumber(value: tax)) ?? "\(tax)"
        let netStr = formatter.string(from: NSNumber(value: calculateNetAmount())) ?? "\(calculateNetAmount())"
        
        var description = """
        PAYSLIP DETAILS
        ---------------
        
        PERSONAL DETAILS:
        Name: \(name)
        Month: \(month)
        Year: \(year)
        
        FINANCIAL DETAILS:
        Credits: \(creditsStr)
        Debits: \(debitsStr)
        DSOP: \(dsopStr)
        Tax: \(taxStr)
        Net Amount: \(netStr)
        """
        
        // Add earnings breakdown if available
        if !earnings.isEmpty {
            description += "\n\nEARNINGS BREAKDOWN:"
            for (key, value) in earnings.sorted(by: { $0.key < $1.key }) {
                if value > 0 {
                    let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                    description += "\n\(key): \(valueStr)"
                }
            }
        }
        
        // Add deductions breakdown if available
        if !deductions.isEmpty {
            description += "\n\nDEDUCTIONS BREAKDOWN:"
            for (key, value) in deductions.sorted(by: { $0.key < $1.key }) {
                if value > 0 {
                    let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                    description += "\n\(key): \(valueStr)"
                }
            }
        }
        
        description += "\n\nGenerated by Payslip Max"
        
        return description
    }
}

// MARK: - Factory Protocol

/// A protocol for factories that create payslip items.
protocol PayslipItemFactoryProtocol {
    /// Creates an empty payslip item.
    ///
    /// - Returns: An empty payslip item.
    static func createEmpty() -> any PayslipItemProtocol
    
    /// Creates a sample payslip item for testing or preview.
    ///
    /// - Returns: A sample payslip item.
    static func createSample() -> any PayslipItemProtocol
} 
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
    
    /// The DSPOF (Defense Services Officers Provident Fund) contribution.
    var dspof: Double { get set }
    
    /// The tax deduction in the payslip.
    var tax: Double { get set }
    
    /// The location associated with the payslip.
    var location: String { get set }
    
    /// The name of the employee.
    var name: String { get set }
    
    /// The account number of the employee.
    var accountNumber: String { get set }
    
    /// The PAN (Permanent Account Number) of the employee.
    var panNumber: String { get set }
    
    /// The timestamp when the payslip was created or processed.
    var timestamp: Date { get set }
    
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
    /// The net amount is calculated as credits minus debits, DSPOF, and tax.
    ///
    /// - Returns: The net amount.
    func calculateNetAmount() -> Double {
        return credits - (debits + dspof + tax)
    }
    
    /// Creates a formatted string representation of the payslip.
    ///
    /// - Returns: A formatted string with payslip details.
    func formattedDescription() -> String {
        return """
        Payslip Details
        
        Name: \(name)
        Month: \(month)
        Year: \(year)
        
        Credits: \(credits)
        Debits: \(debits)
        DSPOF: \(dspof)
        Tax: \(tax)
        Net Amount: \(calculateNetAmount())
        
        Location: \(location)
        """
    }
}

// MARK: - Factory

/// A factory for creating payslip items.
///
/// This class provides methods for creating different types of payslip items,
/// such as empty payslips, sample payslips, or payslips from data.
class PayslipItemFactory {
    /// Creates an empty payslip item.
    ///
    /// - Returns: An empty payslip item.
    static func createEmpty() -> PayslipItemProtocol {
        // This will be implemented to return the concrete type
        fatalError("Not implemented")
    }
    
    /// Creates a sample payslip item for testing or preview.
    ///
    /// - Returns: A sample payslip item.
    static func createSample() -> PayslipItemProtocol {
        // This will be implemented to return the concrete type
        fatalError("Not implemented")
    }
} 
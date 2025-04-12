import Foundation

/// Protocol defining the encryption-related properties and methods for a payslip item.
///
/// This protocol provides the properties and methods related to sensitive data
/// and encryption operations for payslip items.
protocol PayslipEncryptionProtocol: PayslipBaseProtocol {
    // MARK: - Sensitive Data Properties
    
    /// The name of the payslip owner.
    var name: String { get set }
    
    /// The account number of the payslip owner.
    var accountNumber: String { get set }
    
    /// The PAN (Permanent Account Number) of the payslip owner.
    var panNumber: String { get set }
    
    // MARK: - Encryption Status Flags
    
    /// Flag indicating whether the name has been encrypted.
    var isNameEncrypted: Bool { get set }
    
    /// Flag indicating whether the account number has been encrypted.
    var isAccountNumberEncrypted: Bool { get set }
    
    /// Flag indicating whether the PAN number has been encrypted.
    var isPanNumberEncrypted: Bool { get set }
    
    // MARK: - Encryption Methods
    
    /// Encrypts sensitive data in the payslip.
    ///
    /// This method encrypts the name, account number, and PAN number
    /// and updates the encryption status flags accordingly.
    func encryptSensitiveData() async throws
    
    /// Decrypts sensitive data in the payslip.
    ///
    /// This method decrypts the encrypted sensitive data (if available)
    /// and updates the encryption status flags accordingly.
    func decryptSensitiveData() async throws
}

// MARK: - Default Implementation

extension PayslipEncryptionProtocol {
    /// Returns whether all sensitive fields are encrypted.
    var isFullyEncrypted: Bool {
        return isNameEncrypted && isAccountNumberEncrypted && isPanNumberEncrypted
    }
    
    /// Returns whether any sensitive fields are encrypted.
    var hasEncryptedFields: Bool {
        return isNameEncrypted || isAccountNumberEncrypted || isPanNumberEncrypted
    }
} 
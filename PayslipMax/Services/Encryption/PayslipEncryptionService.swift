import Foundation

/// Protocol defining the interface for payslip encryption services
protocol PayslipEncryptionServiceProtocol {
    /// Encrypts sensitive data in the provided payslip
    /// - Parameter payslip: The payslip containing sensitive data to encrypt
    /// - Returns: Boolean flags indicating which fields were encrypted
    /// - Throws: Error if encryption fails
    func encryptSensitiveData(in payslip: inout any PayslipItemProtocol) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool)
    
    /// Decrypts sensitive data in the provided payslip
    /// - Parameter payslip: The payslip containing encrypted data to decrypt
    /// - Returns: Boolean flags indicating which fields were decrypted
    /// - Throws: Error if decryption fails
    func decryptSensitiveData(in payslip: inout any PayslipItemProtocol) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool)
}

/// Service responsible for encrypting and decrypting payslip sensitive data.
/// This decouples encryption logic from the PayslipItem model.
class PayslipEncryptionService: PayslipEncryptionServiceProtocol {
    
    // MARK: - Properties
    
    /// The handler for sensitive data operations
    private let sensitiveDataHandler: PayslipSensitiveDataHandler
    
    // MARK: - Initialization
    
    /// Initialize with a specific sensitive data handler
    /// - Parameter sensitiveDataHandler: The handler to use for sensitive data operations
    init(sensitiveDataHandler: PayslipSensitiveDataHandler) {
        self.sensitiveDataHandler = sensitiveDataHandler
    }
    
    /// Encrypts sensitive data in the provided payslip
    /// - Parameter payslip: The payslip containing sensitive data to encrypt
    /// - Returns: Boolean flags indicating which fields were encrypted
    /// - Throws: Error if encryption fails
    func encryptSensitiveData(in payslip: inout any PayslipItemProtocol) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        // Track which fields were encrypted
        var nameEncrypted = false
        var accountNumberEncrypted = false
        var panNumberEncrypted = false
        
        // Get encrypted versions of the sensitive fields
        let encryptedFields = try sensitiveDataHandler.encryptSensitiveFields(
            name: payslip.name,
            accountNumber: payslip.accountNumber,
            panNumber: payslip.panNumber
        )
        
        // Update the payslip with the encrypted values
        payslip.name = encryptedFields.name
        payslip.accountNumber = encryptedFields.accountNumber
        payslip.panNumber = encryptedFields.panNumber
        
        // All fields were successfully encrypted
        nameEncrypted = true
        accountNumberEncrypted = true
        panNumberEncrypted = true
        
        return (nameEncrypted: nameEncrypted, accountNumberEncrypted: accountNumberEncrypted, panNumberEncrypted: panNumberEncrypted)
    }
    
    /// Decrypts sensitive data in the provided payslip
    /// - Parameter payslip: The payslip containing encrypted data to decrypt
    /// - Returns: Boolean flags indicating which fields were decrypted
    /// - Throws: Error if decryption fails
    func decryptSensitiveData(in payslip: inout any PayslipItemProtocol) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        // Track which fields were decrypted
        var nameDecrypted = false
        var accountNumberDecrypted = false
        var panNumberDecrypted = false
        
        // Get decrypted versions of the sensitive fields
        let decryptedFields = try sensitiveDataHandler.decryptSensitiveFields(
            name: payslip.name,
            accountNumber: payslip.accountNumber,
            panNumber: payslip.panNumber
        )
        
        // Update the payslip with the decrypted values
        payslip.name = decryptedFields.name
        payslip.accountNumber = decryptedFields.accountNumber
        payslip.panNumber = decryptedFields.panNumber
        
        // All fields were successfully decrypted
        nameDecrypted = true
        accountNumberDecrypted = true
        panNumberDecrypted = true
        
        return (nameDecrypted: nameDecrypted, accountNumberDecrypted: accountNumberDecrypted, panNumberDecrypted: panNumberDecrypted)
    }
}

// MARK: - Factory

extension PayslipEncryptionService {
    /// Factory for creating PayslipEncryptionService instances
    enum Factory {
        /// Creates a PayslipEncryptionService with default configuration
        static func create() throws -> PayslipEncryptionService {
            // Create a PayslipSensitiveDataHandler for encryption operations
            let sensitiveDataHandler = try PayslipSensitiveDataHandler.Factory.create()
            return PayslipEncryptionService(sensitiveDataHandler: sensitiveDataHandler)
        }
    }
} 
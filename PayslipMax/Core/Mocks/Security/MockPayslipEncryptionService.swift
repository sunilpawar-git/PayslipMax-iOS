import Foundation

/// Mock implementation of PayslipEncryptionServiceProtocol for testing purposes.
///
/// This mock service simulates payslip encryption and decryption operations using
/// simple string prefixing to indicate encrypted state. It provides controllable
/// behavior for testing encryption-related functionality.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether encryption operations should fail
    var shouldFailEncryption = false
    
    /// Controls whether decryption operations should fail
    var shouldFailDecryption = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
    }
    
    // MARK: - PayslipEncryptionServiceProtocol Implementation
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        if shouldFailEncryption {
            throw MockError.encryptionFailed
        }
        
        // Simple encryption simulation - prefix with "ENC:"
        var nameEncrypted = false
        var accountNumberEncrypted = false
        var panNumberEncrypted = false
        
        if !payslip.name.hasPrefix("ENC:") {
            payslip.name = "ENC:" + payslip.name
            nameEncrypted = true
        }
        
        if !payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = "ENC:" + payslip.accountNumber
            accountNumberEncrypted = true
        }
        
        if !payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = "ENC:" + payslip.panNumber
            panNumberEncrypted = true
        }
        
        return (nameEncrypted: nameEncrypted, accountNumberEncrypted: accountNumberEncrypted, panNumberEncrypted: panNumberEncrypted)
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        if shouldFailDecryption {
            throw MockError.decryptionFailed
        }
        
        // Simple decryption simulation - remove "ENC:" prefix
        var nameDecrypted = false
        var accountNumberDecrypted = false
        var panNumberDecrypted = false
        
        if payslip.name.hasPrefix("ENC:") {
            payslip.name = String(payslip.name.dropFirst(4))
            nameDecrypted = true
        }
        
        if payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = String(payslip.accountNumber.dropFirst(4))
            accountNumberDecrypted = true
        }
        
        if payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = String(payslip.panNumber.dropFirst(4))
            panNumberDecrypted = true
        }
        
        return (nameDecrypted: nameDecrypted, accountNumberDecrypted: accountNumberDecrypted, panNumberDecrypted: panNumberDecrypted)
    }
} 
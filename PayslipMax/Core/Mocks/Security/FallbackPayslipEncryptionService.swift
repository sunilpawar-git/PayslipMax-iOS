import Foundation

/// Fallback implementation of PayslipEncryptionServiceProtocol that always throws errors.
///
/// This service is designed to simulate scenarios where encryption services are
/// unavailable or misconfigured. It always throws the provided error for both
/// encryption and decryption operations.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class FallbackPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    
    // MARK: - Properties
    
    /// The error to throw for all operations
    private let error: Error
    
    // MARK: - Initialization
    
    /// Creates a fallback service that throws the specified error for all operations.
    /// - Parameter error: The error to throw for all encryption/decryption attempts
    init(error: Error) {
        self.error = error
    }
    
    // MARK: - PayslipEncryptionServiceProtocol Implementation
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        throw error
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        throw error
    }
} 
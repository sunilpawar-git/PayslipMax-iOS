import Foundation

/// Protocol defining the encryption service interface for the application.
///
/// This protocol establishes a contract for encryption services, enabling dependency injection
/// and mocking during testing. It defines the essential encryption and decryption operations
/// required to secure sensitive data within the application.
///
/// Implementations of this protocol are responsible for:
/// - Securely managing encryption keys
/// - Encrypting sensitive data using strong cryptographic algorithms
/// - Decrypting previously encrypted data when authorized access is needed
/// - Handling cryptographic errors appropriately
protocol EncryptionServiceProtocol: AnyObject {
    /// Encrypts the provided data using a secure encryption algorithm.
    ///
    /// - Parameter data: The raw data to encrypt
    /// - Returns: The encrypted data
    /// - Throws: Encryption-related errors (e.g., key not available, encryption failure)
    func encrypt(_ data: Data) throws -> Data
    
    /// Decrypts previously encrypted data.
    ///
    /// - Parameter data: The encrypted data to decrypt
    /// - Returns: The original, decrypted data
    /// - Throws: Decryption-related errors (e.g., key not available, invalid data, decryption failure)
    func decrypt(_ data: Data) throws -> Data
}

/// Extends EncryptionService to conform to EncryptionServiceProtocol.
///
/// This conformance allows the concrete EncryptionService implementation to be used
/// wherever an EncryptionServiceProtocol is required, supporting the application's
/// dependency injection architecture.
extension EncryptionService: EncryptionServiceProtocol {} 
import Foundation

/// Protocol for encryption service used by the sensitive data handler.
/// This typealias creates a common interface for any encryption service that will
/// be used with the sensitive data handler.
typealias SensitiveDataEncryptionService = EncryptionServiceProtocolInternal

/// Errors that can occur during sensitive data handling.
/// These error types provide specific information about what went wrong
/// during encryption or decryption operations.
enum SensitiveDataError: Error, LocalizedError {
    /// Invalid base64 data was provided for decryption.
    case invalidBase64Data(field: String)
    
    /// Failed to decode data to a string.
    case decodingFailed(field: String)
    
    /// Failed to create an encryption service.
    case encryptionServiceCreationFailed
    
    /// Error description for user-facing messages.
    var errorDescription: String? {
        switch self {
        case .invalidBase64Data(let field):
            return "Invalid base64 data for \(field)"
        case .decodingFailed(let field):
            return "Failed to decode \(field) data"
        case .encryptionServiceCreationFailed:
            return "Failed to create encryption service"
        }
    }
}

/// A class that handles encryption and decryption of sensitive payslip data.
///
/// This class serves as a specialized component in the security architecture,
/// focused specifically on protecting sensitive personal and financial information
/// within payslip objects. It provides a consistent interface for encrypting and
/// decrypting fields like names, account numbers, and PAN (Permanent Account Number) 
/// information, ensuring this data remains secure both in memory and persistent storage.
///
/// Key responsibilities:
/// - Encrypt sensitive strings using the provided encryption service
/// - Decrypt previously encrypted strings when authorized access is needed
/// - Handle encoding/decoding between encrypted data and Base64 string representation
/// - Manage batch operations for encrypting/decrypting multiple fields together
/// - Provide clear error reporting when encryption/decryption operations fail
///
/// This handler uses dependency injection to receive its encryption service,
/// allowing for different encryption implementations or mock services during testing.
class PayslipSensitiveDataHandler {
    // MARK: - Properties
    
    /// The encryption service instance used for all cryptographic operations.
    /// This service is responsible for the actual encryption and decryption algorithms.
    private let encryptionService: SensitiveDataEncryptionService
    
    // MARK: - Initialization
    
    /// Initializes a new sensitive data handler with the provided encryption service.
    ///
    /// - Parameter encryptionService: The encryption service to use for all cryptographic operations.
    ///                               Must conform to SensitiveDataEncryptionService protocol.
    init(encryptionService: SensitiveDataEncryptionService) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - Public Methods
    
    /// Encrypts a string value.
    ///
    /// This method converts the string to data, encrypts it using the encryption service,
    /// and then encodes the encrypted data as a Base64 string for storage.
    ///
    /// - Parameters:
    ///   - value: The string value to encrypt.
    ///   - fieldName: The name of the field being encrypted (for error reporting).
    /// - Returns: The encrypted string in base64 format.
    /// - Throws: An error if encryption fails.
    func encryptString(_ value: String, fieldName: String) throws -> String {
        let data = value.data(using: .utf8) ?? Data()
        do {
            let encryptedData = try encryptionService.encrypt(data)
            return encryptedData.base64EncodedString()
        } catch {
            // Propagate EncryptionService.EncryptionError directly
            if let encryptionError = error as? EncryptionService.EncryptionError {
                throw encryptionError
            }
            // For other errors, wrap them
            throw error
        }
    }
    
    /// Decrypts a base64-encoded string value.
    ///
    /// This method decodes the Base64 string to encrypted data, decrypts it using
    /// the encryption service, and then converts the decrypted data back to a string.
    ///
    /// - Parameters:
    ///   - value: The base64-encoded string to decrypt.
    ///   - fieldName: The name of the field being decrypted (for error reporting).
    /// - Returns: The decrypted string.
    /// - Throws: An error if decryption fails.
    func decryptString(_ value: String, fieldName: String) throws -> String {
        guard let data = Data(base64Encoded: value) else {
            throw SensitiveDataError.invalidBase64Data(field: fieldName)
        }
        
        do {
            let decryptedData = try encryptionService.decrypt(data)
            
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw SensitiveDataError.decodingFailed(field: fieldName)
            }
            
            return decryptedString
        } catch {
            // Propagate EncryptionService.EncryptionError directly
            if let encryptionError = error as? EncryptionService.EncryptionError {
                throw encryptionError
            }
            // For other errors, wrap them
            throw error
        }
    }
    
    /// Encrypts sensitive fields in a payslip.
    ///
    /// This method provides a convenient way to encrypt multiple sensitive fields
    /// in a single operation. It ensures consistent encryption across all fields
    /// and returns them as a tuple for easy assignment.
    ///
    /// - Parameters:
    ///   - name: The name to encrypt.
    ///   - accountNumber: The account number to encrypt.
    ///   - panNumber: The PAN number to encrypt.
    /// - Returns: A tuple containing the encrypted values.
    /// - Throws: An error if encryption fails for any field.
    func encryptSensitiveFields(name: String, accountNumber: String, panNumber: String) throws -> (name: String, accountNumber: String, panNumber: String) {
        let encryptedName = try encryptString(name, fieldName: "name")
        let encryptedAccountNumber = try encryptString(accountNumber, fieldName: "account number")
        let encryptedPanNumber = try encryptString(panNumber, fieldName: "PAN number")
        
        return (encryptedName, encryptedAccountNumber, encryptedPanNumber)
    }
    
    /// Decrypts sensitive fields in a payslip.
    ///
    /// This method provides a convenient way to decrypt multiple sensitive fields
    /// in a single operation. It ensures consistent decryption across all fields
    /// and returns them as a tuple for easy assignment.
    ///
    /// - Parameters:
    ///   - name: The encrypted name.
    ///   - accountNumber: The encrypted account number.
    ///   - panNumber: The encrypted PAN number.
    /// - Returns: A tuple containing the decrypted values.
    /// - Throws: An error if decryption fails for any field.
    func decryptSensitiveFields(name: String, accountNumber: String, panNumber: String) throws -> (name: String, accountNumber: String, panNumber: String) {
        let decryptedName = try decryptString(name, fieldName: "name")
        let decryptedAccountNumber = try decryptString(accountNumber, fieldName: "account number")
        let decryptedPanNumber = try decryptString(panNumber, fieldName: "PAN number")
        
        return (decryptedName, decryptedAccountNumber, decryptedPanNumber)
    }
}

// MARK: - Factory

extension PayslipSensitiveDataHandler {
    /// A factory for creating sensitive data handlers.
    ///
    /// This factory provides a consistent way to create PayslipSensitiveDataHandler instances
    /// with the appropriate encryption service. It supports dependency injection and testing
    /// by allowing the encryption service factory to be customized.
    class Factory {
        /// The closure used to create instances of the encryption service.
        /// Allows for injecting different encryption services (e.g., mocks for testing).
        private static var encryptionServiceFactory: () -> EncryptionServiceProtocolInternal = {
            // Instead of a fatal error, we'll return a default implementation or log a warning
            print("Warning: EncryptionService not properly configured - using default implementation")
            // Create a new instance of EncryptionService instead of trying to access it from DIContainer
            return EncryptionService()
        }
        
        /// Sets the encryption service factory function.
        ///
        /// This method allows the application to customize how encryption services are created,
        /// enabling dependency injection and testing with mock services.
        ///
        /// - Parameter factory: The factory function that creates encryption services.
        /// - Returns: An instance of the encryption service created by the new factory function.
        static func setSensitiveDataEncryptionServiceFactory(_ factory: @escaping () -> EncryptionServiceProtocolInternal) -> EncryptionServiceProtocolInternal {
            encryptionServiceFactory = factory
            return factory()
        }
        
        /// Resets the factory function to the default implementation.
        ///
        /// This method restores the default encryption service creation behavior,
        /// which creates a new instance of EncryptionService.
        static func resetSensitiveDataEncryptionServiceFactory() {
            encryptionServiceFactory = {
                // Create a new instance of EncryptionService instead of trying to access it from DIContainer
                return EncryptionService()
            }
        }
        
        /// Creates a sensitive data handler with the configured encryption service.
        ///
        /// This is the primary method for obtaining a PayslipSensitiveDataHandler instance
        /// with the appropriate encryption service configuration.
        ///
        /// - Returns: A new sensitive data handler.
        /// - Throws: An error if the encryption service cannot be created.
        static func create() throws -> PayslipSensitiveDataHandler {
            let encryptionService = encryptionServiceFactory()
            return PayslipSensitiveDataHandler(encryptionService: encryptionService)
        }
    }
}

// Initialize the encryption service factory when the app starts
extension PayslipSensitiveDataHandler.Factory {
    /// Initialize the factory with default services.
    ///
    /// This method should be called during application startup to ensure
    /// the encryption service factory is properly configured.
    static func initialize() {
        resetSensitiveDataEncryptionServiceFactory()
    }
} 
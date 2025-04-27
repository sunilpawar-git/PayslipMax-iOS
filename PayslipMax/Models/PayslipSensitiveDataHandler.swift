import Foundation

/// Protocol for encryption service used by the sensitive data handler.
typealias SensitiveDataEncryptionService = EncryptionServiceProtocolInternal

/// Errors that can occur during sensitive data handling.
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

/// A class that handles encryption and decryption of sensitive data.
///
/// This class is responsible for encrypting and decrypting sensitive data
/// such as names, account numbers, and PAN numbers.
class PayslipSensitiveDataHandler {
    // MARK: - Properties
    
    /// The encryption service instance used for all cryptographic operations.
    private let encryptionService: SensitiveDataEncryptionService
    
    // MARK: - Initialization
    
    /// Initializes a new sensitive data handler with the provided encryption service.
    ///
    /// - Parameter encryptionService: The encryption service to use.
    init(encryptionService: SensitiveDataEncryptionService) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - Public Methods
    
    /// Encrypts a string value.
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
    /// - Parameters:
    ///   - name: The name to encrypt.
    ///   - accountNumber: The account number to encrypt.
    ///   - panNumber: The PAN number to encrypt.
    /// - Returns: A tuple containing the encrypted values.
    /// - Throws: An error if encryption fails.
    func encryptSensitiveFields(name: String, accountNumber: String, panNumber: String) throws -> (name: String, accountNumber: String, panNumber: String) {
        let encryptedName = try encryptString(name, fieldName: "name")
        let encryptedAccountNumber = try encryptString(accountNumber, fieldName: "account number")
        let encryptedPanNumber = try encryptString(panNumber, fieldName: "PAN number")
        
        return (encryptedName, encryptedAccountNumber, encryptedPanNumber)
    }
    
    /// Decrypts sensitive fields in a payslip.
    ///
    /// - Parameters:
    ///   - name: The encrypted name.
    ///   - accountNumber: The encrypted account number.
    ///   - panNumber: The encrypted PAN number.
    /// - Returns: A tuple containing the decrypted values.
    /// - Throws: An error if decryption fails.
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
        /// - Parameter factory: The factory function.
        static func setSensitiveDataEncryptionServiceFactory(_ factory: @escaping () -> EncryptionServiceProtocolInternal) -> EncryptionServiceProtocolInternal {
            encryptionServiceFactory = factory
            return factory()
        }
        
        /// Resets the factory function to the default implementation.
        static func resetSensitiveDataEncryptionServiceFactory() {
            encryptionServiceFactory = {
                // Create a new instance of EncryptionService instead of trying to access it from DIContainer
                return EncryptionService()
            }
        }
        
        /// Creates a sensitive data handler with the configured encryption service.
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
    /// Initialize the factory with default services
    static func initialize() {
        resetSensitiveDataEncryptionServiceFactory()
    }
} 
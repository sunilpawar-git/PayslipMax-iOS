import Foundation

/// Errors that can occur during sensitive data protection operations
enum SensitiveDataError: LocalizedError {
    case invalidBase64Data(field: String)
    case decodingFailed(field: String)
    case encryptionServiceNotConfigured
    case encryptionFailed(field: String, underlyingError: Error)
    case decryptionFailed(field: String, underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidBase64Data(let field):
            return "Invalid base64 data for \(field)"
        case .decodingFailed(let field):
            return "Failed to decode \(field) data"
        case .encryptionServiceNotConfigured:
            return "Encryption service not properly configured"
        case .encryptionFailed(let field, let error):
            return "Failed to encrypt \(field): \(error.localizedDescription)"
        case .decryptionFailed(let field, let error):
            return "Failed to decrypt \(field): \(error.localizedDescription)"
        }
    }
}

/// Protocol for services that protect sensitive data
protocol SensitiveDataProtecting {
    /// Encrypts a string value
    /// - Parameters:
    ///   - value: The string to encrypt
    ///   - fieldName: Name of the field (for error reporting)
    /// - Returns: The encrypted string in base64 format
    /// - Throws: SensitiveDataError if encryption fails
    func encrypt(value: String, fieldName: String) throws -> String
    
    /// Decrypts a base64-encoded encrypted string
    /// - Parameters:
    ///   - value: The encrypted string in base64 format
    ///   - fieldName: Name of the field (for error reporting)
    /// - Returns: The decrypted string
    /// - Throws: SensitiveDataError if decryption fails
    func decrypt(value: String, fieldName: String) throws -> String
}

/// Service that protects sensitive data using encryption
class SensitiveDataProtector: SensitiveDataProtecting {
    // MARK: - Properties
    
    private let encryptionService: EncryptionServiceProtocolInternal
    
    // MARK: - Initialization
    
    init(encryptionService: EncryptionServiceProtocolInternal) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - SensitiveDataProtecting
    
    func encrypt(value: String, fieldName: String) throws -> String {
        let data = value.data(using: .utf8) ?? Data()
        
        do {
            let encryptedData = try encryptionService.encrypt(data)
            return encryptedData.base64EncodedString()
        } catch {
            throw SensitiveDataError.encryptionFailed(field: fieldName, underlyingError: error)
        }
    }
    
    func decrypt(value: String, fieldName: String) throws -> String {
        guard let data = Data(base64Encoded: value) else {
            throw SensitiveDataError.invalidBase64Data(field: fieldName)
        }
        
        do {
            let decryptedData = try encryptionService.decrypt(data)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw SensitiveDataError.decodingFailed(field: fieldName)
            }
            return decryptedString
        } catch let error as SensitiveDataError {
            throw error
        } catch {
            throw SensitiveDataError.decryptionFailed(field: fieldName, underlyingError: error)
        }
    }
} 
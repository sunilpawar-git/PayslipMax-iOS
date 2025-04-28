import Foundation
import LocalAuthentication
import Security

/// Manages the secure storage and retrieval of sensitive payslip data.
/// Utilizes encryption and biometric authentication to protect user data stored in the keychain.
class SecureDataManager {
    private let encryptionService = EncryptionService()
    private let biometricAuth = BiometricAuthService()
    
    private let keychainService = "com.app.payslipmax.payslips"
    
    /// Securely stores a `PayslipItem` after authenticating the user.
    /// The payslip data is encrypted before being stored in the keychain.
    /// - Parameter payslip: The `PayslipItem` to store securely.
    /// - Throws: `SecurityError.authenticationFailed` if biometric authentication fails.
    ///           An error from `JSONEncoder` if encoding fails.
    ///           An error from `EncryptionService` if encryption fails.
    ///           `SecurityError.storageError` if keychain storage fails.
    func securelyStorePayslip(_ payslip: PayslipItem) async throws {
        // Verify user identity before storing sensitive data
        var authenticated = false
        
        _ = await withCheckedContinuation { continuation in
            biometricAuth.authenticate { success, _ in
                authenticated = success
                continuation.resume(returning: success)
            }
        }
        
        guard authenticated else {
            throw SecurityError.authenticationFailed
        }
        
        // Convert to JSON
        let encoder = JSONEncoder()
        let payslipData = try encoder.encode(payslip)
        
        // Encrypt the data
        let encryptedData = try encryptionService.encrypt(payslipData)
        
        // Store encrypted data
        try await storeEncryptedData(encryptedData, for: payslip.id)
    }
    
    /// Retrieves a securely stored `PayslipItem` by its ID after authenticating the user.
    /// Fetches the encrypted data from the keychain and decrypts it.
    /// - Parameter id: The `UUID` of the payslip to retrieve.
    /// - Throws: `SecurityError.authenticationFailed` if biometric authentication fails.
    ///           `SecurityError.dataNotFound` if the data is not found in the keychain.
    ///           An error from `EncryptionService` if decryption fails.
    ///           An error from `JSONDecoder` if decoding fails.
    /// - Returns: The retrieved and decrypted `PayslipItem`.
    func retrievePayslip(id: UUID) async throws -> PayslipItem {
        // Verify user identity before accessing sensitive data
        var authenticated = false
        
        _ = await withCheckedContinuation { continuation in
            biometricAuth.authenticate { success, _ in
                authenticated = success
                continuation.resume(returning: success)
            }
        }
        
        guard authenticated else {
            throw SecurityError.authenticationFailed
        }
        
        // Retrieve encrypted data
        let encryptedData = try await fetchEncryptedData(for: id)
        
        // Decrypt the data
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Convert back to payslip
        let decoder = JSONDecoder()
        return try decoder.decode(PayslipItem.self, from: decryptedData)
    }
    
    /// Stores encrypted data in the keychain for a specific identifier.
    /// Data is stored as a generic password item accessible after the first unlock.
    /// - Parameters:
    ///   - data: The encrypted `Data` to store.
    ///   - id: The `UUID` serving as the account identifier for the keychain item.
    /// - Throws: `SecurityError.storageError` if the keychain operation fails.
    private func storeEncryptedData(_ data: Data, for id: UUID) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.storageError
        }
    }
    
    /// Fetches encrypted data from the keychain for a specific identifier.
    /// - Parameter id: The `UUID` serving as the account identifier for the keychain item.
    /// - Throws: `SecurityError.dataNotFound` if the item cannot be found or retrieved.
    /// - Returns: The encrypted `Data` retrieved from the keychain.
    private func fetchEncryptedData(for id: UUID) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw SecurityError.dataNotFound
        }
        
        return data
    }
    
    /// Errors specific to the secure data management process.
    enum SecurityError: Error {
        /// Biometric or other required user authentication failed.
        case authenticationFailed
        /// The requested data could not be found in secure storage (keychain).
        case dataNotFound
        /// An error occurred during the keychain storage operation (add, update, delete).
        case storageError
    }
} 
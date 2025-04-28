import Foundation
import CryptoKit
import Security

/// A service that provides military-grade AES-256 encryption for sensitive data.
///
/// This service manages encryption keys securely in the device Keychain and provides
/// methods for encrypting and decrypting data using AES-GCM encryption. The service
/// handles key generation, storage, retrieval, and all cryptographic operations required
/// to maintain the security of sensitive payslip data.
///
/// Key features:
/// - AES-256 encryption (military-grade security)
/// - Secure key storage in the Keychain
/// - Automatic key generation and management
/// - NIST-compliant implementation using Apple's CryptoKit
class EncryptionService {
    /// The key length for AES-256 encryption (military-grade security)
    private let keyLength = SymmetricKeySize.bits256
    
    /// The service identifier for Keychain storage
    private let keychainService = "com.app.payslipmax"
    
    /// The account identifier for Keychain storage
    private let keychainAccount = "encryption_key"
    
    /// The encryption key, loaded from Keychain or generated if not found
    ///
    /// This property automatically handles key persistence, ensuring the key is securely
    /// stored in the Keychain and consistently available for encryption/decryption operations.
    private var encryptionKey: SymmetricKey? {
        get {
            loadKeyFromKeychain() ?? generateAndStoreNewKey()
        }
    }
    
    /// Encrypts data using AES-256-GCM encryption.
    ///
    /// This method encrypts the provided data using a secure AES-GCM algorithm with
    /// a randomly generated nonce to ensure cryptographic security.
    ///
    /// - Parameter data: The data to encrypt
    /// - Returns: The encrypted data (combined nonce, ciphertext, and authentication tag)
    /// - Throws: `EncryptionError.keyNotFound` if the encryption key is not available
    ///           `EncryptionError.encryptionFailed` if the encryption operation fails
    func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotFound
        }
        
        do {
            // Create a nonce for AES-GCM
            let nonce = AES.GCM.Nonce()
            
            // Seal the data with AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            // Get the combined data (nonce + ciphertext + tag)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            
            return combined
        } catch {
            print("Encryption error: \(error.localizedDescription)")
            throw EncryptionError.encryptionFailed
        }
    }
    
    /// Decrypts data that was encrypted using AES-256-GCM.
    ///
    /// This method decrypts data that was previously encrypted by the `encrypt(_:)` method.
    /// It extracts the nonce and authentication tag from the combined data and uses them
    /// along with the encryption key to decrypt the ciphertext.
    ///
    /// - Parameter data: The encrypted data (combined nonce, ciphertext, and authentication tag)
    /// - Returns: The original, decrypted data
    /// - Throws: `EncryptionError.keyNotFound` if the encryption key is not available
    ///           `EncryptionError.decryptionFailed` if the decryption operation fails (e.g., tampered data)
    func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotFound
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Decryption error: \(error.localizedDescription)")
            throw EncryptionError.decryptionFailed
        }
    }
    
    /// Generates a new encryption key and stores it in the Keychain.
    ///
    /// This method creates a cryptographically secure random key for AES-256 encryption
    /// and persists it securely in the device Keychain for future use.
    ///
    /// - Returns: The newly generated symmetric key
    private func generateAndStoreNewKey() -> SymmetricKey {
        let key = SymmetricKey(size: keyLength)
        storeKeyInKeychain(key)
        return key
    }
    
    /// Loads the encryption key from the device Keychain.
    ///
    /// This method attempts to retrieve the previously stored encryption key from the
    /// device Keychain using the service and account identifiers.
    ///
    /// - Returns: The retrieved symmetric key, or nil if not found
    private func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Stores the encryption key securely in the device Keychain.
    ///
    /// This method saves the provided encryption key to the device Keychain using the
    /// service and account identifiers, making it available for future encryption/decryption
    /// operations even after app restarts.
    ///
    /// - Parameter key: The symmetric key to store
    private func storeKeyInKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Errors that can occur during encryption or decryption operations.
    enum EncryptionError: Error {
        /// The encryption key was not found or could not be generated
        case keyNotFound
        /// The encryption operation failed
        case encryptionFailed
        /// The decryption operation failed
        case decryptionFailed
    }
} 
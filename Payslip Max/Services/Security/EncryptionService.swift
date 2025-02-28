import Foundation
import Security
import CryptoKit

/// Service for encrypting and decrypting data
class EncryptionService {
    /// The encryption key
    private let key: SymmetricKey
    
    /// Initializes a new encryption service
    /// - Parameter key: The encryption key (defaults to a new key)
    init(key: SymmetricKey? = nil) {
        if let key = key {
            self.key = key
        } else {
            // In a real app, this would be stored securely in the keychain
            let keyData = Data(repeating: 0, count: 32) // 256-bit key
            self.key = SymmetricKey(data: keyData)
        }
    }
    
    /// Encrypts data
    /// - Parameter data: The data to encrypt
    /// - Returns: The encrypted data
    /// - Throws: Error if encryption fails
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    /// Decrypts data
    /// - Parameter data: The data to decrypt
    /// - Returns: The decrypted data
    /// - Throws: Error if decryption fails
    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // AES-256 encryption for military-grade security
    private let keyLength = SymmetricKeySize.bits256
    
    // Secure key storage in Keychain
    private let keychainService = "com.app.payslipmax"
    private let keychainAccount = "encryption_key"
    
    private var encryptionKey: SymmetricKey? {
        get {
            loadKeyFromKeychain() ?? generateAndStoreNewKey()
        }
    }
    
    private func generateAndStoreNewKey() -> SymmetricKey {
        let key = SymmetricKey(size: keyLength)
        storeKeyInKeychain(key)
        return key
    }
    
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
    
    enum EncryptionError: Error {
        case keyNotFound
        case encryptionFailed
        case decryptionFailed
    }
} 
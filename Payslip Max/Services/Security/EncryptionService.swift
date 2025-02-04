import Foundation
import CryptoKit
import Security

class EncryptionService {
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
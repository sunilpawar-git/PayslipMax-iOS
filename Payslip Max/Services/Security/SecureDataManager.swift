import Foundation
import LocalAuthentication
import Security

class SecureDataManager {
    private let encryptionService = EncryptionService()
    private let biometricAuth = BiometricAuthService()
    
    private let keychainService = "com.app.payslipmax.payslips"
    
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
    
    enum SecurityError: Error {
        case authenticationFailed
        case dataNotFound
        case storageError
    }
} 
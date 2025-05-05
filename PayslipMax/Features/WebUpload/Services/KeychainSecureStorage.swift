import Foundation
import Security

/// Implementation of SecureStorageProtocol using the Keychain
class KeychainSecureStorage: SecureStorageProtocol {
    private let serviceName: String
    
    init(serviceName: String = "com.payslipmax.webupload") {
        self.serviceName = serviceName
    }
    
    func saveData(key: String, data: Data) throws {
        // Create a query for the keychain
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw NSError(domain: "KeychainErrorDomain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save data to Keychain"])
        }
    }
    
    func getData(key: String) throws -> Data? {
        // Create a query for the keychain
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        // Get the item from the keychain
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw NSError(domain: "KeychainErrorDomain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to get data from Keychain"])
        }
        
        return item as? Data
    }
    
    func saveString(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw NSError(domain: "KeychainErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        
        try saveData(key: key, data: data)
    }
    
    func getString(key: String) throws -> String? {
        guard let data = try getData(key: key) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "KeychainErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
        }
        
        return string
    }
    
    func deleteItem(key: String) throws {
        // Create a query for the keychain
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        // Delete the item
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "KeychainErrorDomain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to delete item from Keychain"])
        }
    }
} 
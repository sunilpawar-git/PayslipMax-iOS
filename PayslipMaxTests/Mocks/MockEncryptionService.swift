import Foundation
import CryptoKit
@testable import Payslip_Max

/// A mock encryption service for testing.
class MockEncryptionService: EncryptionServiceProtocolInternal {
    private var mockKey: SymmetricKey?
    internal var shouldFailEncryption = false
    internal var shouldFailDecryption = false
    internal var shouldFailKeyManagement = false
    
    var encryptionCount = 0
    var decryptionCount = 0
    
    // A mock encryption prefix we'll use
    private let encryptionPrefix = "MOCK_ENCRYPTED_"
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        
        if let string = String(data: data, encoding: .utf8) {
            let encryptedString = encryptionPrefix + string
            return encryptedString.data(using: .utf8) ?? data
        }
        
        return data
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        if let string = String(data: data, encoding: .utf8) {
            if string.hasPrefix(encryptionPrefix) {
                let decryptedString = string.replacingOccurrences(of: encryptionPrefix, with: "")
                return decryptedString.data(using: .utf8) ?? data
            }
        }
        
        return data
    }
    
    func encryptString(_ string: String) throws -> String {
        encryptionCount += 1
        
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        
        if string.isEmpty {
            return ""
        }
        
        return encryptionPrefix + string
    }
    
    func decryptString(_ string: String) throws -> String {
        decryptionCount += 1
        
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        if string.isEmpty {
            return ""
        }
        
        if string.hasPrefix(encryptionPrefix) {
            return string.replacingOccurrences(of: encryptionPrefix, with: "")
        }
        
        return string
    }
    
    func generateAndStoreKey() throws {
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
    }
    
    func deleteKey() throws {
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
    }
    
    func reset() {
        mockKey = nil
        shouldFailEncryption = false
        shouldFailDecryption = false
        shouldFailKeyManagement = false
        encryptionCount = 0
        decryptionCount = 0
    }
    
    func setShouldFailEncryption(_ shouldFail: Bool) {
        shouldFailEncryption = shouldFail
    }
    
    func setShouldFailDecryption(_ shouldFail: Bool) {
        shouldFailDecryption = shouldFail
    }
    
    func setShouldFailKeyManagement(_ shouldFail: Bool) {
        shouldFailKeyManagement = shouldFail
    }
    
    private func getOrCreateKey() throws -> SymmetricKey {
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        
        if mockKey == nil {
            mockKey = SymmetricKey(size: .bits256)
        }
        
        return mockKey!
    }
} 
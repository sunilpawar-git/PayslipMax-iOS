#!/usr/bin/env swift

import Foundation

// Mock iOS simulator environment for testing
#if canImport(CryptoKit)
import CryptoKit
#endif

// Simple test runner for EncryptionService
print("🔒 Testing EncryptionService...")

// Copy the EncryptionService implementation for standalone testing
class TestEncryptionService {
    private let keyLength = SymmetricKeySize.bits256
    private let keychainService = "com.app.payslipmax.test"
    private let keychainAccount = "encryption_key_test"
    
    private var encryptionKey: SymmetricKey? {
        get {
            loadKeyFromKeychain() ?? generateAndStoreNewKey()
        }
    }
    
    func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw TestEncryptionError.keyNotFound
        }
        
        do {
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            guard let combined = sealedBox.combined else {
                throw TestEncryptionError.encryptionFailed
            }
            
            return combined
        } catch {
            throw TestEncryptionError.encryptionFailed
        }
    }
    
    func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw TestEncryptionError.keyNotFound
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw TestEncryptionError.decryptionFailed
        }
    }
    
    private func generateAndStoreNewKey() -> SymmetricKey {
        let key = SymmetricKey(size: keyLength)
        // Skip keychain storage for test
        return key
    }
    
    private func loadKeyFromKeychain() -> SymmetricKey? {
        return nil // Skip keychain for test
    }
    
    enum TestEncryptionError: Error {
        case keyNotFound
        case encryptionFailed
        case decryptionFailed
    }
}

// Run tests
func runTests() {
    let service = TestEncryptionService()
    var passedTests = 0
    var totalTests = 0
    
    // Test 1: Basic encryption/decryption
    totalTests += 1
    do {
        let testData = "Hello, World!".data(using: .utf8)!
        let encrypted = try service.encrypt(testData)
        let decrypted = try service.decrypt(encrypted)
        
        if decrypted == testData {
            print("✅ Test 1 PASSED: Basic encryption/decryption")
            passedTests += 1
        } else {
            print("❌ Test 1 FAILED: Data mismatch")
        }
    } catch {
        print("❌ Test 1 FAILED: \(error)")
    }
    
    // Test 2: Empty data
    totalTests += 1
    do {
        let emptyData = Data()
        let encrypted = try service.encrypt(emptyData)
        let decrypted = try service.decrypt(encrypted)
        
        if decrypted == emptyData {
            print("✅ Test 2 PASSED: Empty data encryption")
            passedTests += 1
        } else {
            print("❌ Test 2 FAILED: Empty data mismatch")
        }
    } catch {
        print("❌ Test 2 FAILED: \(error)")
    }
    
    // Test 3: Large data
    totalTests += 1
    do {
        let largeString = String(repeating: "Test", count: 1000)
        let largeData = largeString.data(using: .utf8)!
        let encrypted = try service.encrypt(largeData)
        let decrypted = try service.decrypt(encrypted)
        
        if decrypted == largeData {
            print("✅ Test 3 PASSED: Large data encryption")
            passedTests += 1
        } else {
            print("❌ Test 3 FAILED: Large data mismatch")
        }
    } catch {
        print("❌ Test 3 FAILED: \(error)")
    }
    
    print("\n🔒 Encryption Test Results: \(passedTests)/\(totalTests) tests passed")
    
    if passedTests == totalTests {
        print("🎉 All encryption tests PASSED!")
        exit(0)
    } else {
        print("💥 Some encryption tests FAILED!")
        exit(1)
    }
}

runTests()
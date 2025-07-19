import XCTest
import Foundation
import CryptoKit
import Security
@testable import PayslipMax

final class EncryptionServiceTest: XCTestCase {
    
    // MARK: - Test Properties
    
    private var encryptionService: EncryptionService!
    private var keychainCleanupItems: [(service: String, account: String)] = []
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        encryptionService = EncryptionService()
        keychainCleanupItems = []
        
        // Clean up any existing test keys from previous runs
        cleanupTestKeysFromKeychain()
    }
    
    override func tearDown() {
        // Clean up any keys created during tests
        cleanupTestKeysFromKeychain()
        encryptionService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test 1: Verify basic encryption functionality
    func testBasicEncryption() throws {
        // Given: Test data
        let testData = "Hello, Encryption!".data(using: .utf8)!
        
        // When: Encrypt data
        let encryptedData = try encryptionService.encrypt(testData)
        
        // Then: Encrypted data should be different from original and non-empty
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertTrue(encryptedData.count > 0)
        XCTAssertTrue(encryptedData.count > testData.count) // Should include nonce and tag
    }
    
    /// Test 2: Verify basic decryption functionality  
    func testBasicDecryption() throws {
        // Given: Encrypted test data
        let testData = "Hello, Decryption!".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(testData)
        
        // When: Decrypt data
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Decrypted data should match original
        XCTAssertEqual(decryptedData, testData)
        XCTAssertEqual(String(data: decryptedData, encoding: .utf8), "Hello, Decryption!")
    }
    
    /// Test 3: Verify round-trip encryption/decryption with various data types
    func testRoundTripEncryptionDecryption() throws {
        let testCases = [
            "Simple string",
            "",
            "String with special characters: !@#$%^&*()_+{}[]|\\:;\"'<>?,./",
            String(repeating: "A", count: 1000), // Large string
            "🔒🗝️💰📊", // Emoji
            "Multi\nline\nstring\nwith\ntabs\tand\rcarriage\rreturns"
        ]
        
        for testString in testCases {
            let testData = testString.data(using: .utf8)!
            
            // When: Encrypt and decrypt
            let encryptedData = try encryptionService.encrypt(testData)
            let decryptedData = try encryptionService.decrypt(encryptedData)
            
            // Then: Should get back original data
            XCTAssertEqual(decryptedData, testData, "Failed for: \(testString)")
            XCTAssertEqual(String(data: decryptedData, encoding: .utf8), testString)
        }
    }
    
    /// Test 4: Verify encryption with empty data
    func testEncryptionWithEmptyData() throws {
        // Given: Empty data
        let emptyData = Data()
        
        // When: Encrypt empty data
        let encryptedData = try encryptionService.encrypt(emptyData)
        
        // Then: Should still produce encrypted output (due to nonce and authentication tag)
        XCTAssertTrue(encryptedData.count > 0)
        
        // When: Decrypt the encrypted empty data
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should get back empty data
        XCTAssertEqual(decryptedData, emptyData)
        XCTAssertEqual(decryptedData.count, 0)
    }
    
    /// Test 5: Verify encryption produces different results with same input
    func testEncryptionNonDeterministic() throws {
        // Given: Same test data
        let testData = "Test for non-deterministic encryption".data(using: .utf8)!
        
        // When: Encrypt same data multiple times
        let encrypted1 = try encryptionService.encrypt(testData)
        let encrypted2 = try encryptionService.encrypt(testData)
        let encrypted3 = try encryptionService.encrypt(testData)
        
        // Then: Should produce different encrypted results (due to random nonce)
        XCTAssertNotEqual(encrypted1, encrypted2)
        XCTAssertNotEqual(encrypted2, encrypted3)
        XCTAssertNotEqual(encrypted1, encrypted3)
        
        // But all should decrypt to same original data
        let decrypted1 = try encryptionService.decrypt(encrypted1)
        let decrypted2 = try encryptionService.decrypt(encrypted2)
        let decrypted3 = try encryptionService.decrypt(encrypted3)
        
        XCTAssertEqual(decrypted1, testData)
        XCTAssertEqual(decrypted2, testData)
        XCTAssertEqual(decrypted3, testData)
    }
    
    /// Test 6: Verify key persistence across service instances
    func testKeyPersistenceAcrossInstances() throws {
        // Given: First service instance encrypts data
        let testData = "Persistence test".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(testData)
        
        // When: Create new service instance
        let newEncryptionService = EncryptionService()
        
        // Then: New instance should be able to decrypt data (same key from Keychain)
        let decryptedData = try newEncryptionService.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, testData)
    }
    
    /// Test 7: Verify large data encryption/decryption
    func testLargeDataEncryption() throws {
        // Given: Large data (10KB)
        let largeString = String(repeating: "Large data test", count: 700)
        let largeData = largeString.data(using: .utf8)!
        
        // When: Encrypt and decrypt large data
        let encryptedData = try encryptionService.encrypt(largeData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should handle large data correctly
        XCTAssertEqual(decryptedData, largeData)
        XCTAssertEqual(String(data: decryptedData, encoding: .utf8), largeString)
    }
    
    /// Test 8: Verify protocol conformance
    func testProtocolConformance() {
        // Given: EncryptionService instance
        let service: EncryptionServiceProtocol = encryptionService
        
        // Then: Should conform to protocol
        XCTAssertTrue(service is EncryptionService)
        XCTAssertNotNil(service) // service is already EncryptionServiceProtocol, no need to cast
    }
    
    /// Test 9: Verify decryption fails with tampered data
    func testDecryptionFailsWithTamperedData() throws {
        // Given: Encrypted data
        let testData = "Test for tampered data".data(using: .utf8)!
        var encryptedData = try encryptionService.encrypt(testData)
        
        // When: Tamper with encrypted data
        encryptedData[encryptedData.count - 1] ^= 0xFF // Flip bits in last byte
        
        // Then: Decryption should fail
        XCTAssertThrowsError(try encryptionService.decrypt(encryptedData)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .decryptionFailed)
            }
        }
    }
    
    /// Test 10: Verify decryption fails with invalid data format
    func testDecryptionFailsWithInvalidData() {
        // Given: Invalid encrypted data (too short, wrong format)
        let invalidData = Data([0x01, 0x02, 0x03]) // Too short for AES-GCM
        
        // When/Then: Decryption should fail
        XCTAssertThrowsError(try encryptionService.decrypt(invalidData)) { error in
            XCTAssertNotNil(error as? EncryptionService.EncryptionError)
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .decryptionFailed)
            }
        }
    }
    
    /// Test 11: Verify encryption error enum descriptions
    func testEncryptionErrorCases() {
        let errors: [EncryptionService.EncryptionError] = [
            .keyNotFound,
            .encryptionFailed,
            .decryptionFailed
        ]
        
        // Verify all error cases can be created and compared
        for error in errors {
            XCTAssertTrue(error is EncryptionService.EncryptionError)
        }
        
        // Verify different errors are not equal
        XCTAssertNotEqual(EncryptionService.EncryptionError.keyNotFound, .encryptionFailed)
        XCTAssertNotEqual(EncryptionService.EncryptionError.encryptionFailed, .decryptionFailed)
        XCTAssertNotEqual(EncryptionService.EncryptionError.decryptionFailed, .keyNotFound)
    }
    
    /// Test 12: Verify binary data encryption/decryption
    func testBinaryDataEncryption() throws {
        // Given: Binary data (not UTF-8 string)
        var binaryData = Data()
        for i in 0...255 {
            binaryData.append(UInt8(i))
        }
        
        // When: Encrypt and decrypt binary data
        let encryptedData = try encryptionService.encrypt(binaryData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should handle binary data correctly
        XCTAssertEqual(decryptedData, binaryData)
        XCTAssertEqual(decryptedData.count, 256)
    }
    
    /// Test 13: Verify multiple sequential encryptions produce different results
    func testMultipleEncryptions() throws {
        let testData = "Multiple test".data(using: .utf8)!
        var encryptedResults: [Data] = []
        
        // When: Perform multiple sequential encryptions
        for _ in 0..<5 {
            let encrypted = try encryptionService.encrypt(testData)
            encryptedResults.append(encrypted)
        }
        
        // Then: All encryptions should succeed and produce different results
        XCTAssertEqual(encryptedResults.count, 5)
        
        // Verify all are different (due to random nonce)
        for i in 0..<encryptedResults.count {
            for j in (i+1)..<encryptedResults.count {
                XCTAssertNotEqual(encryptedResults[i], encryptedResults[j])
            }
        }
        
        // Verify all decrypt to same original data
        for encryptedData in encryptedResults {
            let decrypted = try encryptionService.decrypt(encryptedData)
            XCTAssertEqual(decrypted, testData)
        }
    }
    
    /// Test 14: Verify service memory management
    func testServiceMemoryManagement() throws {
        weak var weakService: EncryptionService?
        let testData = "Memory test".data(using: .utf8)!
        var encryptedData: Data!
        
        try autoreleasepool {
            let service = EncryptionService()
            weakService = service
            XCTAssertNotNil(weakService)
            
            // Use the service
            encryptedData = try service.encrypt(testData)
        }
        
        // Service should be deallocated after leaving scope
        XCTAssertNil(weakService)
        
        // But new service should still be able to decrypt (key persisted in Keychain)
        let newService = EncryptionService()
        let decryptedData = try newService.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, testData)
    }
    
    /// Test 15: Verify encryption consistency over time
    func testEncryptionConsistencyOverTime() throws {
        let testData = "Consistency test".data(using: .utf8)!
        
        // Encrypt data multiple times with delays
        var encryptedResults: [Data] = []
        
        for i in 0..<5 {
            let encrypted = try encryptionService.encrypt(testData)
            encryptedResults.append(encrypted)
            
            if i < 4 {
                // Small delay between encryptions
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        
        // All should be different (due to random nonce)
        for i in 0..<encryptedResults.count {
            for j in (i+1)..<encryptedResults.count {
                XCTAssertNotEqual(encryptedResults[i], encryptedResults[j])
            }
        }
        
        // All should decrypt to same data
        for encrypted in encryptedResults {
            let decrypted = try encryptionService.decrypt(encrypted)
            XCTAssertEqual(decrypted, testData)
        }
    }
    
    /// Test 16: Verify service handles JSON data encryption
    func testJSONDataEncryption() throws {
        // Given: JSON data
        let jsonObject = [
            "name": "John Doe",
            "salary": 50000,
            "department": "Engineering",
            "sensitive": true
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        
        // When: Encrypt and decrypt JSON data
        let encryptedData = try encryptionService.encrypt(jsonData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should preserve JSON structure
        XCTAssertEqual(decryptedData, jsonData)
        
        let decryptedObject = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any]
        XCTAssertNotNil(decryptedObject)
        XCTAssertEqual(decryptedObject?["name"] as? String, "John Doe")
        XCTAssertEqual(decryptedObject?["salary"] as? Int, 50000)
    }
    
    // MARK: - Helper Methods
    
    /// Cleans up test keys from Keychain to ensure clean test state
    private func cleanupTestKeysFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.app.payslipmax",
            kSecAttrAccount as String: "encryption_key"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
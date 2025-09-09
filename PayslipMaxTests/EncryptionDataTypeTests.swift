import XCTest
import Foundation
import CryptoKit
import Security
@testable import PayslipMax

/// Test suite for encryption with different data types
///
/// This test class focuses on ensuring encryption works correctly with various
/// data formats including binary data, JSON, large datasets, and special content
/// types. Tests verify data integrity and format preservation through encryption/decryption.
final class EncryptionDataTypeTests: XCTestCase {

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

    // MARK: - Data Type Tests

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

    /// Test: Verify encryption with image-like data
    func testImageDataEncryption() throws {
        // Given: Simulated image data (binary with specific patterns)
        var imageData = Data()
        // Simulate a simple image header
        imageData.append(contentsOf: [0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        // Add some image content
        for _ in 0..<1000 {
            imageData.append(UInt8.random(in: 0...255))
        }

        // When: Encrypt and decrypt image data
        let encryptedData = try encryptionService.encrypt(imageData)
        let decryptedData = try encryptionService.decrypt(encryptedData)

        // Then: Should preserve image data exactly
        XCTAssertEqual(decryptedData, imageData)
        XCTAssertEqual(decryptedData.count, imageData.count)
        // Verify header is preserved
        XCTAssertEqual(decryptedData.prefix(4), Data([0xFF, 0xD8, 0xFF, 0xE0]))
    }

    /// Test: Verify encryption with compressed data
    func testCompressedDataEncryption() throws {
        // Given: Simulated compressed data
        var compressedData = Data()
        // Simulate gzip header
        compressedData.append(contentsOf: [0x1F, 0x8B, 0x08, 0x00])
        // Add compressed content
        for _ in 0..<500 {
            compressedData.append(UInt8.random(in: 0...255))
        }

        // When: Encrypt and decrypt compressed data
        let encryptedData = try encryptionService.encrypt(compressedData)
        let decryptedData = try encryptionService.decrypt(encryptedData)

        // Then: Should preserve compressed data structure
        XCTAssertEqual(decryptedData, compressedData)
        XCTAssertEqual(decryptedData.count, compressedData.count)
        // Verify header is preserved
        XCTAssertEqual(decryptedData.prefix(4), Data([0x1F, 0x8B, 0x08, 0x00]))
    }

    /// Test: Verify encryption with very small data
    func testVerySmallDataEncryption() throws {
        // Test with single byte
        let singleByte = Data([0x42])
        let encrypted = try encryptionService.encrypt(singleByte)
        let decrypted = try encryptionService.decrypt(encrypted)
        XCTAssertEqual(decrypted, singleByte)

        // Test with two bytes
        let twoBytes = Data([0x42, 0x43])
        let encrypted2 = try encryptionService.encrypt(twoBytes)
        let decrypted2 = try encryptionService.decrypt(encrypted2)
        XCTAssertEqual(decrypted2, twoBytes)
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

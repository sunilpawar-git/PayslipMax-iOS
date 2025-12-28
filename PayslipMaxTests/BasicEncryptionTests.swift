import XCTest
import Foundation
import CryptoKit
import Security
@testable import PayslipMax

/// Test suite for basic encryption functionality
///
/// This test class focuses on the core encryption and decryption operations,
/// ensuring the fundamental cryptographic functionality works correctly.
/// Covers basic encryption, decryption, round-trip operations, and empty data handling.
final class BasicEncryptionTests: XCTestCase {

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

    // MARK: - Basic Encryption Tests

    /// Test 1: Verify basic encryption functionality
    func testBasicEncryption() throws {
        // Given: Test data
        let testData = "Hello, Encryption!".data(using: .utf8)!

        // When: Encrypt data
        let encryptedData = try encryptionService.encrypt(testData)

        // Then: Encrypted data should be different from original and non-empty
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertFalse(encryptedData.isEmpty)
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
        XCTAssertFalse(encryptedData.isEmpty)

        // When: Decrypt the encrypted empty data
        let decryptedData = try encryptionService.decrypt(encryptedData)

        // Then: Should get back empty data
        XCTAssertEqual(decryptedData, emptyData)
        XCTAssertEqual(decryptedData.count, 0)
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

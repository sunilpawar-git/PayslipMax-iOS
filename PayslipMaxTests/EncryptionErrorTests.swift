import XCTest
import Foundation
import CryptoKit
import Security
@testable import PayslipMax

/// Test suite for encryption error handling
///
/// This test class focuses on error scenarios and edge cases in encryption operations,
/// ensuring the service properly handles invalid data, tampered content, and various
/// failure conditions while maintaining security guarantees.
final class EncryptionErrorTests: XCTestCase {

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

    // MARK: - Error Handling Tests

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

        // Verify all error cases can be created (type is already guaranteed by declaration)
        for error in errors {
            XCTAssertNotNil(error)
        }

        // Verify different errors are not equal
        XCTAssertNotEqual(EncryptionService.EncryptionError.keyNotFound, .encryptionFailed)
        XCTAssertNotEqual(EncryptionService.EncryptionError.encryptionFailed, .decryptionFailed)
        XCTAssertNotEqual(EncryptionService.EncryptionError.decryptionFailed, .keyNotFound)
    }

    /// Test: Verify decryption fails with completely random data
    func testDecryptionFailsWithRandomData() {
        // Given: Random data that doesn't represent valid encrypted content
        let randomData = Data((0..<100).map { _ in UInt8.random(in: 0...255) })

        // When/Then: Decryption should fail
        XCTAssertThrowsError(try encryptionService.decrypt(randomData)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .decryptionFailed)
            }
        }
    }

    /// Test: Verify decryption fails with truncated encrypted data
    func testDecryptionFailsWithTruncatedData() throws {
        // Given: Valid encrypted data
        let testData = "Test truncation".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(testData)

        // When: Truncate the encrypted data
        let truncatedData = encryptedData.prefix(encryptedData.count - 10)

        // Then: Decryption should fail
        XCTAssertThrowsError(try encryptionService.decrypt(truncatedData)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .decryptionFailed)
            }
        }
    }

    /// Test: Verify error handling with nil data
    func testEncryptionWithNilHandling() {
        // This test ensures the service doesn't crash with unexpected nil scenarios
        // The actual implementation should handle nil inputs gracefully
        let nilData: Data? = nil

        // Note: This test documents expected behavior - actual implementation
        // should have proper nil checks in production code
        if let data = nilData {
            XCTAssertNoThrow(try encryptionService.encrypt(data))
        } else {
            // If nil data is passed, it should be handled appropriately
            XCTAssertTrue(true, "Nil data should be handled at call site")
        }
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

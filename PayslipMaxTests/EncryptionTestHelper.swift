import Foundation
import Security
import XCTest
@testable import PayslipMax

/// Shared helper class for encryption tests
///
/// This class provides common setup, teardown, and utility methods
/// for all encryption-related test classes to reduce code duplication
/// and ensure consistent test behavior.
class EncryptionTestHelper {

    // MARK: - Properties

    private let keychainService = "com.app.payslipmax"
    private let keychainAccount = "encryption_key"

    // MARK: - Setup/Teardown Helpers

    /// Creates a fresh EncryptionService instance with clean Keychain state
    func createFreshEncryptionService() -> EncryptionService {
        cleanupTestKeysFromKeychain()
        return EncryptionService()
    }

    /// Cleans up test keys from Keychain to ensure clean test state
    func cleanupTestKeysFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Test Data Generators

    /// Generates test data of specified size with predictable pattern
    func generateTestData(size: Int, pattern: String = "Test data") -> Data {
        let repeatedString = String(repeating: pattern, count: max(1, size / pattern.count))
        let truncatedString = String(repeatedString.prefix(size))
        return truncatedString.data(using: .utf8) ?? Data()
    }

    /// Generates binary test data (non-UTF8)
    func generateBinaryTestData(size: Int) -> Data {
        return Data((0..<size).map { _ in UInt8.random(in: 0...255) })
    }

    /// Generates JSON test data
    func generateJSONTestData() throws -> Data {
        let jsonObject: [String: Any] = [
            "id": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "data": "Sensitive information",
            "metadata": [
                "version": "1.0",
                "encrypted": true
            ]
        ]
        return try JSONSerialization.data(withJSONObject: jsonObject)
    }

    /// Generates test data that looks like image data
    func generateImageLikeData(size: Int) -> Data {
        var data = Data()
        // JPEG header
        data.append(contentsOf: [0xFF, 0xD8, 0xFF, 0xE0])
        // Add random content
        for _ in 4..<size {
            data.append(UInt8.random(in: 0...255))
        }
        return data
    }

    /// Generates test data that looks like compressed data
    func generateCompressedLikeData(size: Int) -> Data {
        var data = Data()
        // Gzip-like header
        data.append(contentsOf: [0x1F, 0x8B, 0x08, 0x00])
        // Add random content
        for _ in 4..<size {
            data.append(UInt8.random(in: 0...255))
        }
        return data
    }

    // MARK: - Validation Helpers

    /// Validates that encrypted data has expected properties
    func validateEncryptedData(_ encryptedData: Data, originalData: Data) {
        // Encrypted data should be different from original
        XCTAssertNotEqual(encryptedData, originalData)

        // Encrypted data should be larger (due to nonce and tag)
        XCTAssertTrue(encryptedData.count > originalData.count)

        // Should not be empty
        XCTAssertFalse(encryptedData.isEmpty)
    }

    /// Validates round-trip encryption/decryption
    func validateRoundTrip(service: EncryptionServiceProtocol,
                          originalData: Data,
                          testName: String = "Round-trip test") throws -> Data {
        let encrypted = try service.encrypt(originalData)
        validateEncryptedData(encrypted, originalData: originalData)

        let decrypted = try service.decrypt(encrypted)
        XCTAssertEqual(decrypted, originalData, "Failed round-trip for: \(testName)")

        return decrypted
    }

    /// Validates that multiple encryptions of same data produce different results
    func validateNonDeterministicEncryption(service: EncryptionServiceProtocol,
                                          data: Data,
                                          iterations: Int = 5) throws -> [Data] {
        var results: [Data] = []

        for _ in 0..<iterations {
            let encrypted = try service.encrypt(data)
            results.append(encrypted)
        }

        // All results should be different
        for i in 0..<results.count {
            for j in (i+1)..<results.count {
                XCTAssertNotEqual(results[i], results[j], "Encryptions \(i) and \(j) should be different")
            }
        }

        // All should decrypt to same original
        for encrypted in results {
            let decrypted = try service.decrypt(encrypted)
            XCTAssertEqual(decrypted, data)
        }

        return results
    }

    // MARK: - Error Validation Helpers

    /// Validates that decryption fails with expected error type
    func validateDecryptionFailure(service: EncryptionServiceProtocol,
                                 invalidData: Data,
                                 expectedError: EncryptionService.EncryptionError = .decryptionFailed) {
        XCTAssertThrowsError(try service.decrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, expectedError)
            }
        }
    }

    // MARK: - Performance Helpers

    /// Measures execution time of a block
    func measureExecutionTime(_ block: () throws -> Void) rethrows -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        try block()
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }

    /// Validates performance is within acceptable limits
    func validatePerformance(operationName: String,
                           executionTime: TimeInterval,
                           maxTime: TimeInterval = 1.0) {
        XCTAssertTrue(executionTime < maxTime,
                     "\(operationName) took \(executionTime)s, exceeding limit of \(maxTime)s")
    }
}

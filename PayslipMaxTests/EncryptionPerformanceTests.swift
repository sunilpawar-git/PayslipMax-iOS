import XCTest
import Foundation
import CryptoKit
import Security
@testable import PayslipMax

/// Test suite for encryption performance and consistency
///
/// This test class focuses on performance characteristics, memory management,
/// and consistency of encryption operations over time. Tests verify that
/// the service maintains consistent behavior and proper resource management.
final class EncryptionPerformanceTests: XCTestCase {

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

    // MARK: - Performance Tests

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

    /// Test: Verify performance with large data sets
    func testLargeDataSetPerformance() throws {
        // Given: Multiple large data sets
        let dataSizes = [10_000, 50_000, 100_000] // bytes

        for size in dataSizes {
            let largeData = Data((0..<size).map { _ in UInt8.random(in: 0...255) })

            // Measure encryption time
            let encryptStart = CFAbsoluteTimeGetCurrent()
            let encryptedData = try encryptionService.encrypt(largeData)
            let encryptTime = CFAbsoluteTimeGetCurrent() - encryptStart

            // Measure decryption time
            let decryptStart = CFAbsoluteTimeGetCurrent()
            let decryptedData = try encryptionService.decrypt(encryptedData)
            let decryptTime = CFAbsoluteTimeGetCurrent() - decryptStart

            // Then: Verify correctness and reasonable performance
            XCTAssertEqual(decryptedData, largeData)
            XCTAssertTrue(encryptTime < 1.0, "Encryption took too long: \(encryptTime)s for \(size) bytes")
            XCTAssertTrue(decryptTime < 1.0, "Decryption took too long: \(decryptTime)s for \(size) bytes")
        }
    }

    /// Test: Verify concurrent encryption operations
    func testConcurrentEncryptionOperations() throws {
        let testData = "Concurrent test".data(using: .utf8)!
        let operationCount = 10

        // Create expectation for concurrent operations
        let expectation = XCTestExpectation(description: "Concurrent encryption operations")
        expectation.expectedFulfillmentCount = operationCount

        var results = [(encrypted: Data, index: Int)]()
        let resultsQueue = DispatchQueue(label: "results.queue")

        // Perform concurrent encryptions
        DispatchQueue.concurrentPerform(iterations: operationCount) { index in
            do {
                let encrypted = try self.encryptionService.encrypt(testData)
                resultsQueue.sync {
                    results.append((encrypted, index))
                }
            } catch {
                XCTFail("Encryption failed for operation \(index): \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify results
        XCTAssertEqual(results.count, operationCount)

        // All should decrypt to same data
        for (encrypted, _) in results {
            let decrypted = try encryptionService.decrypt(encrypted)
            XCTAssertEqual(decrypted, testData)
        }
    }

    /// Test: Verify keychain persistence across app sessions
    func testKeychainPersistenceAcrossSessions() throws {
        let testData = "Session persistence test".data(using: .utf8)!

        // Encrypt with first service instance
        let encryptedData = try encryptionService.encrypt(testData)

        // Simulate app restart by creating new service (in real scenario, this would be a new app launch)
        let newService = EncryptionService()

        // Should be able to decrypt with new service instance
        let decryptedData = try newService.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, testData)

        // Encrypt with new service and decrypt with original
        let newEncryptedData = try newService.encrypt(testData)
        let newDecryptedData = try encryptionService.decrypt(newEncryptedData)
        XCTAssertEqual(newDecryptedData, testData)
    }

    /// Test: Verify encryption/decryption with memory pressure
    func testEncryptionUnderMemoryPressure() throws {
        let testData = "Memory pressure test".data(using: .utf8)!

        // Perform many encryption operations to simulate memory pressure
        var encryptedDataArray: [Data] = []

        for i in 0..<100 {
            let dataWithIndex = testData + Data([UInt8(i)])
            let encrypted = try encryptionService.encrypt(dataWithIndex)
            encryptedDataArray.append(encrypted)

            // Verify each one can be decrypted
            let decrypted = try encryptionService.decrypt(encrypted)
            XCTAssertEqual(decrypted, dataWithIndex)
        }

        // Verify all stored encrypted data can still be decrypted
        for (index, encrypted) in encryptedDataArray.enumerated() {
            let expectedData = testData + Data([UInt8(index)])
            let decrypted = try encryptionService.decrypt(encrypted)
            XCTAssertEqual(decrypted, expectedData)
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

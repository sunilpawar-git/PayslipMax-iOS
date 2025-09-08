import XCTest
@testable import PayslipMax

/// Security service encryption and decryption edge case tests
/// Tests PIN hashing, round-trip encryption, empty data, and concurrent operations
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityEncryptionEdgeCaseTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify PIN hashing consistency
    func testPINHashingConsistency() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        let testPIN = "9876"

        // When: Setup PIN multiple times
        try await setupTestPIN(testPIN)
        let firstVerification = try await securityService.verifyPIN(pin: testPIN)

        try await setupTestPIN(testPIN)
        let secondVerification = try await securityService.verifyPIN(pin: testPIN)

        // Then: PIN verification should be consistent
        XCTAssertTrue(firstVerification)
        XCTAssertTrue(secondVerification)

        // And wrong PIN should still fail
        let wrongPINVerification = try await securityService.verifyPIN(pin: "0000")
        XCTAssertFalse(wrongPINVerification)
    }

    /// Test 2: Verify round-trip encryption/decryption with different data types
    func testEncryptionDecryptionRoundTrip() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Test with different data types
        let testCases = [
            "Simple string",
            "",
            "String with special characters: !@#$%^&*()_+{}[]|\\:;\"'<>?,./",
            String(repeating: "A", count: 1000), // Large string
            "🔒🗝️💰📊" // Emoji
        ]

        for testString in testCases {
            let testData = testString.data(using: .utf8)!

            // When: Encrypt and decrypt
            let encryptedData = try await securityService.encryptData(testData)
            let decryptedData = try await securityService.decryptData(encryptedData)

            // Then: Should get back original data
            XCTAssertEqual(decryptedData, testData)
            XCTAssertEqual(String(data: decryptedData, encoding: .utf8), testString)
        }
    }

    /// Test 3: Verify data encryption with empty data
    func testEncryptionWithEmptyData() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        let emptyData = Data()

        // When: Encrypt empty data
        let encryptedData = try await securityService.encryptData(emptyData)

        // Then: Should still produce encrypted output (due to authentication tag)
        XCTAssertTrue(encryptedData.count > 0)

        // When: Decrypt the encrypted empty data
        let decryptedData = try await securityService.decryptData(encryptedData)

        // Then: Should get back empty data
        XCTAssertEqual(decryptedData, emptyData)
        XCTAssertEqual(decryptedData.count, 0)
    }

    /// Test 7: Verify concurrent security operations
    func testConcurrentSecurityOperations() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Perform multiple security operations concurrently
        async let encryption1 = securityService.encryptData(createTestData("Data 1"))
        async let encryption2 = securityService.encryptData(createTestData("Data 2"))
        async let encryption3 = securityService.encryptData(createTestData("Data 3"))

        // Then: All operations should complete successfully
        let result1 = try await encryption1
        let result2 = try await encryption2
        let result3 = try await encryption3

        XCTAssertTrue(result1.count > 0)
        XCTAssertTrue(result2.count > 0)
        XCTAssertTrue(result3.count > 0)

        // Verify decryption works
        let decrypted1 = try await securityService.decryptData(result1)
        let decrypted2 = try await securityService.decryptData(result2)
        let decrypted3 = try await securityService.decryptData(result3)

        XCTAssertEqual(decrypted1, createTestData("Data 1"))
        XCTAssertEqual(decrypted2, createTestData("Data 2"))
        XCTAssertEqual(decrypted3, createTestData("Data 3"))
    }
}

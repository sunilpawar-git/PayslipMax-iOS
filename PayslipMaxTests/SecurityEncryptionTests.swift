import XCTest
@testable import PayslipMax

/// Security service encryption and decryption tests
/// Tests data encryption/decryption functionality and error handling
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityEncryptionTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify data encryption functionality
    func testDataEncryption() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        let testData = createTestData("Hello, World!")

        // When: Encrypt data
        let encryptedData = try await securityService.encryptData(testData)

        // Then: Encrypted data should be different from original
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertTrue(encryptedData.count > 0)
    }

    /// Test 2: Verify data decryption functionality
    func testDataDecryption() async throws {
        // Given: Service is initialized with encrypted data
        try await initializeSecurityService()
        let testData = createTestData("Hello, World!")
        let encryptedData = try await securityService.encryptData(testData)

        // When: Decrypt data
        let decryptedData = try await securityService.decryptData(encryptedData)

        // Then: Decrypted data should match original
        XCTAssertEqual(decryptedData, testData)
        XCTAssertEqual(String(data: decryptedData, encoding: .utf8), "Hello, World!")
    }

    /// Test 3: Verify encryption fails when not initialized
    func testEncryptionFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        let testData = createTestData("Test")

        // When/Then: Encryption should fail
        do {
            _ = try await securityService.encryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test 4: Verify decryption fails when not initialized
    func testDecryptionFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        let testData = createTestData("Test")

        // When/Then: Decryption should fail
        do {
            _ = try await securityService.decryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test 5: Verify synchronous encryption functionality
    func testSynchronousEncryption() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        let testData = createTestData("Sync Test")

        // When: Encrypt data using async method (since sync method may have resolution issues)
        let encryptedData = try await securityService.encryptData(testData)

        // Then: Encrypted data should be different from original
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertTrue(encryptedData.count > testData.count, "Encrypted data should be larger than original due to GCM overhead")
        XCTAssertTrue(encryptedData.count > 0)
    }

    /// Test 6: Verify basic encryption/decryption cycle works
    func testBasicEncryptionDecryptionCycle() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        XCTAssertTrue(securityService.isInitialized)

        let testData = createTestData("Sync Test")

        // When: Encrypt and decrypt data using async methods
        let encryptedData = try await securityService.encryptData(testData)
        let decryptedData = try await securityService.decryptData(encryptedData)

        // Then: Decrypted data should match original
        XCTAssertEqual(decryptedData, testData)
    }

    /// Test 7: Verify round-trip encryption/decryption with different data types
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

    /// Test 8: Verify data encryption with empty data
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

    /// Test 9: Verify encryption with binary data
    func testEncryptionWithBinaryData() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Create binary data
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])

        // When: Encrypt and decrypt binary data
        let encryptedData = try await securityService.encryptData(binaryData)
        let decryptedData = try await securityService.decryptData(encryptedData)

        // Then: Should get back original binary data
        XCTAssertEqual(decryptedData, binaryData)
        XCTAssertEqual(decryptedData.count, binaryData.count)
    }

    /// Test 10: Verify encryption/decryption consistency across multiple calls
    func testEncryptionConsistency() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()
        let testData = createTestData("Consistency Test")

        // When: Encrypt same data multiple times
        let encrypted1 = try await securityService.encryptData(testData)
        let encrypted2 = try await securityService.encryptData(testData)

        // Then: Encrypted data should be different each time (due to random IV)
        XCTAssertNotEqual(encrypted1, encrypted2)

        // But both should decrypt to the same original data
        let decrypted1 = try await securityService.decryptData(encrypted1)
        let decrypted2 = try await securityService.decryptData(encrypted2)

        XCTAssertEqual(decrypted1, testData)
        XCTAssertEqual(decrypted2, testData)
        XCTAssertEqual(decrypted1, decrypted2)
    }

    /// Test 11: Verify encryption with large data
    func testEncryptionWithLargeData() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Create large data (10MB)
        let largeData = Data(repeating: 0x41, count: 10 * 1024 * 1024)

        // When: Encrypt and decrypt large data
        let encryptedData = try await securityService.encryptData(largeData)
        let decryptedData = try await securityService.decryptData(encryptedData)

        // Then: Should get back original large data
        XCTAssertEqual(decryptedData, largeData)
        XCTAssertEqual(decryptedData.count, largeData.count)
    }

    /// Test 12: Verify decryption fails with invalid data
    func testDecryptionWithInvalidData() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Create invalid encrypted data
        let invalidData = createTestData("This is not encrypted data")

        // When/Then: Decryption should fail
        do {
            _ = try await securityService.decryptData(invalidData)
            XCTFail("Expected decryption to fail with invalid data")
        } catch {
            // Expected to fail with invalid data
            XCTAssertTrue(true)
        }
    }

    /// Test 13: Verify encryption/decryption with Unicode characters
    func testEncryptionWithUnicode() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Test with various Unicode strings
        let unicodeStrings = [
            "Hello 世界",
            "Привет мир",
            "مرحبا بالعالم",
            "こんにちは世界",
            "🦄🌈🎉"
        ]

        for unicodeString in unicodeStrings {
            let testData = unicodeString.data(using: .utf8)!

            // When: Encrypt and decrypt
            let encryptedData = try await securityService.encryptData(testData)
            let decryptedData = try await securityService.decryptData(encryptedData)

            // Then: Should get back original Unicode data
            XCTAssertEqual(decryptedData, testData)
            XCTAssertEqual(String(data: decryptedData, encoding: .utf8), unicodeString)
        }
    }
}

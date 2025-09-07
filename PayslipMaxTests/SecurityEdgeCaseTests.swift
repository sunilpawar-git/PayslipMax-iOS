import XCTest
@testable import PayslipMax

/// Security service edge case and comprehensive tests
/// Tests PIN hashing consistency, large data, and edge cases
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityEdgeCaseTests: SecurityTestBaseSetup {

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

    /// Test 4: Verify SecurityError descriptions
    func testSecurityErrorDescriptions() {
        let errors: [SecurityServiceImpl.SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }

        // Test specific error descriptions
        XCTAssertEqual(SecurityServiceImpl.SecurityError.notInitialized.errorDescription, "Security service not initialized")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.biometricsNotAvailable.errorDescription, "Biometric authentication not available")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.authenticationFailed.errorDescription, "Authentication failed")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.encryptionFailed.errorDescription, "Failed to encrypt data")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.decryptionFailed.errorDescription, "Failed to decrypt data")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.pinNotSet.errorDescription, "PIN has not been set")
    }

    /// Test 5: Verify SecurityPolicy configuration
    func testSecurityPolicyConfiguration() {
        let policy = securityService.securityPolicy

        // Test default values
        XCTAssertTrue(policy.requiresBiometricAuth)
        XCTAssertTrue(policy.requiresDataEncryption)
        XCTAssertEqual(policy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(policy.maxFailedAttempts, 3)

        // Test policy modification
        policy.requiresBiometricAuth = false
        policy.requiresDataEncryption = false
        policy.sessionTimeoutMinutes = 60
        policy.maxFailedAttempts = 5

        XCTAssertFalse(policy.requiresBiometricAuth)
        XCTAssertFalse(policy.requiresDataEncryption)
        XCTAssertEqual(policy.sessionTimeoutMinutes, 60)
        XCTAssertEqual(policy.maxFailedAttempts, 5)
    }

    /// Test 6: Verify SecurityViolation enum cases
    func testSecurityViolationEnumCases() {
        let violations: [SecurityViolation] = [
            .unauthorizedAccess,
            .tooManyFailedAttempts,
            .sessionTimeout
        ]

        // Verify all cases exist and can be created
        XCTAssertEqual(violations.count, 3)

        // Test that each violation can be handled
        for violation in violations {
            // Should not crash when handling violations
            securityService.handleSecurityViolation(violation)
        }
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

    /// Test 8: Verify memory pressure handling
    func testMemoryPressureHandling() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Process large amounts of data
        var encryptedResults: [Data] = []
        let largeData = Data(repeating: 0x41, count: 100 * 1024) // 100KB per item

        for i in 0..<10 {
            let data = createTestData("Large data \(i)") + largeData
            let encrypted = try await securityService.encryptData(data)
            encryptedResults.append(encrypted)
        }

        // Then: All operations should succeed and be decryptable
        for (index, encrypted) in encryptedResults.enumerated() {
            let expectedData = createTestData("Large data \(index)") + largeData
            let decrypted = try await securityService.decryptData(encrypted)
            XCTAssertEqual(decrypted, expectedData)
        }
    }

    /// Test 9: Verify service recovery after failures
    func testServiceRecoveryAfterFailures() async throws {
        // Given: Service experiences multiple failures
        XCTAssertFalse(securityService.isInitialized)

        // When: Try operations that fail due to uninitialized state
        do {
            _ = try await securityService.encryptData(createTestData("test"))
            XCTFail("Should have failed")
        } catch {
            // Expected failure
        }

        do {
            _ = try await securityService.setupPIN(pin: "1234")
            XCTFail("Should have failed")
        } catch {
            // Expected failure
        }

        // Then: Service should still be recoverable
        try await initializeSecurityService()
        XCTAssertTrue(securityService.isInitialized)

        // And operations should work after initialization
        let testData = createTestData("Recovery test")
        let encrypted = try await securityService.encryptData(testData)
        let decrypted = try await securityService.decryptData(encrypted)
        XCTAssertEqual(decrypted, testData)
    }

    /// Test 10: Verify cross-platform compatibility
    func testCrossPlatformCompatibility() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Test data that might behave differently across platforms
        let testStrings = [
            "ASCII: Hello World",
            "Unicode: 你好世界 🌍",
            "Control chars: \n\t\r",
            "Numbers: 1234567890",
            "Symbols: !@#$%^&*()_+-=[]{}|;:,.<>?",
            "Empty: ",
            "Very long: " + String(repeating: "x", count: 10000)
        ]

        for testString in testStrings {
            let testData = testString.data(using: .utf8)!

            // When: Encrypt and decrypt
            let encrypted = try await securityService.encryptData(testData)
            let decrypted = try await securityService.decryptData(encrypted)

            // Then: Should get back original data
            XCTAssertEqual(decrypted, testData)
            XCTAssertEqual(String(data: decrypted, encoding: .utf8), testString)
        }
    }

    /// Test 11: Verify service state consistency
    func testServiceStateConsistency() async throws {
        // Given: Various service states
        XCTAssertFalse(securityService.isInitialized)
        XCTAssertFalse(securityService.isSessionValid)
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)

        // When: Initialize service
        try await initializeSecurityService()

        // Then: State should be consistent
        XCTAssertTrue(securityService.isInitialized)
        XCTAssertFalse(securityService.isSessionValid) // Session not started yet
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)

        // When: Start session
        securityService.startSecureSession()

        // Then: Session state should be consistent
        XCTAssertTrue(securityService.isInitialized)
        XCTAssertTrue(securityService.isSessionValid)
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)
    }

    /// Test 12: Verify operation idempotency
    func testOperationIdempotency() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        let testData = createTestData("Idempotency test")
        let key = "idempotent_key"

        // When: Perform same operation multiple times
        for _ in 0..<5 {
            // Store same data multiple times
            let storeResult = securityService.storeSecureData(testData, forKey: key)
            XCTAssertTrue(storeResult)

            // Retrieve should always return same data
            let retrieved = securityService.retrieveSecureData(forKey: key)
            XCTAssertEqual(retrieved, testData)
        }

        // When: Delete multiple times
        for _ in 0..<3 {
            let deleteResult = securityService.deleteSecureData(forKey: key)
            XCTAssertTrue(deleteResult) // Should succeed even if already deleted
        }

        // Then: Data should be gone
        let finalRetrieved = securityService.retrieveSecureData(forKey: key)
        XCTAssertNil(finalRetrieved)
    }

    /// Test 13: Verify service behavior under stress
    func testServiceUnderStress() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Perform many rapid operations
        let operationCount = 100
        var results: [Data] = []

        for i in 0..<operationCount {
            let data = createTestData("Stress test \(i)")
            let encrypted = try await securityService.encryptData(data)
            results.append(encrypted)
        }

        // Then: All results should be valid and decryptable
        for (index, encrypted) in results.enumerated() {
            let expected = createTestData("Stress test \(index)")
            let decrypted = try await securityService.decryptData(encrypted)
            XCTAssertEqual(decrypted, expected)
        }
    }

    /// Test 14: Verify service isolation between instances
    func testServiceIsolation() async throws {
        // Given: Two service instances
        let service1 = SecurityServiceImpl()
        let service2 = SecurityServiceImpl()

        // When: Initialize both
        try await service1.initialize()
        try await service2.initialize()

        // Then: They should operate independently
        let data1 = createTestData("Service 1 data")
        let data2 = createTestData("Service 2 data")

        let encrypted1 = try await service1.encryptData(data1)
        let encrypted2 = try await service2.encryptData(data2)

        // Cross-service decryption should fail (different keys)
        do {
            _ = try await service1.decryptData(encrypted2)
            XCTFail("Cross-service decryption should fail")
        } catch {
            // Expected to fail
        }

        do {
            _ = try await service2.decryptData(encrypted1)
            XCTFail("Cross-service decryption should fail")
        } catch {
            // Expected to fail
        }

        // Same-service decryption should work
        let decrypted1 = try await service1.decryptData(encrypted1)
        let decrypted2 = try await service2.decryptData(encrypted2)

        XCTAssertEqual(decrypted1, data1)
        XCTAssertEqual(decrypted2, data2)
    }
}

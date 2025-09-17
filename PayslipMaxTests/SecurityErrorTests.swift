import XCTest
@testable import PayslipMax

/// Security service error handling tests
/// Tests error descriptions, error cases, and error message consistency
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityErrorTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify SecurityError descriptions
    func testSecurityErrorDescriptions() {
        let errors: [SecurityError] = [
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
        XCTAssertEqual(SecurityError.notInitialized.errorDescription, "Security service not initialized")
        XCTAssertEqual(SecurityError.biometricsNotAvailable.errorDescription, "Biometric authentication not available")
        XCTAssertEqual(SecurityError.authenticationFailed.errorDescription, "Authentication failed")
        XCTAssertEqual(SecurityError.encryptionFailed.errorDescription, "Failed to encrypt data")
        XCTAssertEqual(SecurityError.decryptionFailed.errorDescription, "Failed to decrypt data")
        XCTAssertEqual(SecurityError.pinNotSet.errorDescription, "PIN has not been set")
    }

    /// Test 2: Verify error descriptions are localized
    func testErrorDescriptionsAreLocalized() {
        let errors: [SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]

        for error in errors {
            let description = error.errorDescription!
            // Verify descriptions are user-friendly and not just raw enum names
            XCTAssertFalse(description.contains("SecurityError"))
            XCTAssertFalse(description.contains("_"))
            XCTAssertTrue(description.count > 5) // Reasonable minimum length
            XCTAssertTrue(description.first!.isUppercase) // Should start with capital letter
        }
    }

    /// Test 3: Verify error equality
    func testErrorEquality() {
        let error1 = SecurityError.notInitialized
        let error2 = SecurityError.notInitialized
        let error3 = SecurityError.authenticationFailed

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    /// Test 4: Verify error hash values
    func testErrorHashValues() {
        let error1 = SecurityError.notInitialized
        let error2 = SecurityError.notInitialized
        let error3 = SecurityError.authenticationFailed

        XCTAssertEqual(error1.hashValue, error2.hashValue)
        XCTAssertNotEqual(error1.hashValue, error3.hashValue)
    }

    /// Test 5: Verify error case iterability
    func testErrorCaseIterability() {
        // Test that we can iterate through all error cases
        let allCases: [SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]

        XCTAssertEqual(allCases.count, 6)

        // Verify each case has a unique description
        let descriptions = allCases.map { $0.errorDescription! }
        let uniqueDescriptions = Set(descriptions)
        XCTAssertEqual(uniqueDescriptions.count, allCases.count)
    }

    /// Test 6: Verify error descriptions don't change unexpectedly
    func testErrorDescriptionsConsistency() {
        // This test ensures error descriptions remain consistent across versions
        let expectedDescriptions: [SecurityError: String] = [
            .notInitialized: "Security service not initialized",
            .biometricsNotAvailable: "Biometric authentication not available",
            .authenticationFailed: "Authentication failed",
            .encryptionFailed: "Failed to encrypt data",
            .decryptionFailed: "Failed to decrypt data",
            .pinNotSet: "PIN has not been set"
        ]

        for (error, expectedDescription) in expectedDescriptions {
            XCTAssertEqual(error.errorDescription, expectedDescription)
        }
    }

    /// Test 7: Verify error string conversion
    func testErrorStringConversion() {
        let errors: [SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]

        for error in errors {
            let stringValue = String(describing: error)
            XCTAssertFalse(stringValue.isEmpty)
            XCTAssertTrue(stringValue.contains("notInitialized") ||
                         stringValue.contains("biometricsNotAvailable") ||
                         stringValue.contains("authenticationFailed") ||
                         stringValue.contains("encryptionFailed") ||
                         stringValue.contains("decryptionFailed") ||
                         stringValue.contains("pinNotSet"))
        }
    }

    /// Test 8: Verify error handling in async contexts
    func testErrorHandlingInAsyncContext() async throws {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)

        // When/Then: Encryption should fail with proper error
        do {
            let testData = createTestData("Test")
            _ = try await securityService.encryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected error
            XCTAssertEqual(SecurityError.notInitialized.errorDescription,
                          "Security service not initialized")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Test 9: Verify error propagation in combined operations
    func testErrorPropagationInCombinedOperations() async throws {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)

        // When: Try multiple operations that should fail
        let testData = createTestData("Test")
        _ = "test_key" // Key not needed for these tests

        // All operations should fail with the same error
        do {
            _ = try await securityService.encryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected
        }

        do {
            _ = try await securityService.decryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected
        }

        do {
            _ = try await securityService.setupPIN(pin: "1234")
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected
        }

        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected
        }
    }

    /// Test 10: Verify error recovery after initialization
    func testErrorRecoveryAfterInitialization() async throws {
        // Given: Service is not initialized, operations fail
        XCTAssertFalse(securityService.isInitialized)

        do {
            let testData = createTestData("Test")
            _ = try await securityService.encryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityError.notInitialized {
            // Expected error before initialization
        }

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Operations should now succeed
        let testData = createTestData("Test Data")
        let encryptedData = try await securityService.encryptData(testData)
        XCTAssertNotEqual(encryptedData, testData)

        let decryptedData = try await securityService.decryptData(encryptedData)
        XCTAssertEqual(decryptedData, testData)
    }

    /// Test 11: Verify error context preservation
    func testErrorContextPreservation() async throws {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)

        // When: Try to perform operations
        let operations = [
            "encryption": { _ = try await self.securityService.encryptData(self.createTestData("test")) },
            "decryption": { _ = try await self.securityService.decryptData(self.createTestData("test")) },
            "pin_setup": { _ = try await self.securityService.setupPIN(pin: "1234") },
            "pin_verify": { _ = try await self.securityService.verifyPIN(pin: "1234") }
        ] as [String: () async throws -> Void]

        // Then: All operations should fail with the same error type
        for (operationName, operation) in operations {
            do {
                try await operation()
                XCTFail("Expected SecurityError.notInitialized for \(operationName)")
            } catch SecurityError.notInitialized {
                // Expected - error context is preserved
            } catch {
                XCTFail("Unexpected error type for \(operationName): \(error)")
            }
        }
    }

    /// Test 12: Verify error message formatting
    func testErrorMessageFormatting() {
        let errors: [SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]

        for error in errors {
            let description = error.errorDescription!

            // Verify formatting standards
            XCTAssertFalse(description.hasPrefix(" "))
            XCTAssertFalse(description.hasSuffix(" "))
            XCTAssertFalse(description.contains("  ")) // No double spaces
            XCTAssertTrue(description.last! == "." || description.last!.isLetter || description.last!.isNumber)
        }
    }
}

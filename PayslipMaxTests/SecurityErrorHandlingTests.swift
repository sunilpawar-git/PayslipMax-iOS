import XCTest
@testable import PayslipMax

/// Security service error handling and description tests
/// Tests SecurityError enum cases and error descriptions
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityErrorHandlingTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

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
}

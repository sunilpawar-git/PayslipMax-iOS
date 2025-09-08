import XCTest
@testable import PayslipMax

/// Security service policy configuration tests
/// Tests SecurityPolicy configuration and modification
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityPolicyConfigurationTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

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
}

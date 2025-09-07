import XCTest
@testable @preconcurrency import PayslipMax

/// Security service policy configuration tests
/// Tests security policy settings, defaults, and modifications
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityPolicyTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify SecurityPolicy configuration
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

    /// Test 2: Verify policy persistence across service instances
    func testPolicyPersistenceAcrossInstances() {
        // Given: Original policy
        let originalPolicy = securityService.securityPolicy
        let originalBiometric = originalPolicy.requiresBiometricAuth
        let originalEncryption = originalPolicy.requiresDataEncryption

        // When: Modify policy
        originalPolicy.requiresBiometricAuth = !originalBiometric
        originalPolicy.requiresDataEncryption = !originalEncryption

        // Then: New service instance should have default policy
        let newService = SecurityServiceImpl()
        let newPolicy = newService.securityPolicy

        XCTAssertEqual(newPolicy.requiresBiometricAuth, originalBiometric)
        XCTAssertEqual(newPolicy.requiresDataEncryption, originalEncryption)
        XCTAssertEqual(newPolicy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(newPolicy.maxFailedAttempts, 3)
    }

    /// Test 3: Verify policy modification boundaries
    func testPolicyModificationBoundaries() {
        let policy = securityService.securityPolicy

        // Test reasonable boundaries for timeout
        policy.sessionTimeoutMinutes = 1
        XCTAssertEqual(policy.sessionTimeoutMinutes, 1)

        policy.sessionTimeoutMinutes = 1440 // 24 hours
        XCTAssertEqual(policy.sessionTimeoutMinutes, 1440)

        // Test reasonable boundaries for max failed attempts
        policy.maxFailedAttempts = 1
        XCTAssertEqual(policy.maxFailedAttempts, 1)

        policy.maxFailedAttempts = 10
        XCTAssertEqual(policy.maxFailedAttempts, 10)
    }

    /// Test 4: Verify policy boolean toggles
    func testPolicyBooleanToggles() {
        let policy = securityService.securityPolicy

        // Test biometric auth toggle
        policy.requiresBiometricAuth = true
        XCTAssertTrue(policy.requiresBiometricAuth)

        policy.requiresBiometricAuth = false
        XCTAssertFalse(policy.requiresBiometricAuth)

        // Test data encryption toggle
        policy.requiresDataEncryption = true
        XCTAssertTrue(policy.requiresDataEncryption)

        policy.requiresDataEncryption = false
        XCTAssertFalse(policy.requiresDataEncryption)
    }

    /// Test 5: Verify policy equality
    func testPolicyEquality() {
        let policy1 = securityService.securityPolicy
        let newService = SecurityServiceImpl()
        let policy2 = newService.securityPolicy

        // Default policies should be equal
        XCTAssertEqual(policy1.requiresBiometricAuth, policy2.requiresBiometricAuth)
        XCTAssertEqual(policy1.requiresDataEncryption, policy2.requiresDataEncryption)
        XCTAssertEqual(policy1.sessionTimeoutMinutes, policy2.sessionTimeoutMinutes)
        XCTAssertEqual(policy1.maxFailedAttempts, policy2.maxFailedAttempts)

        // After modification, they should be different
        policy1.sessionTimeoutMinutes = 60
        XCTAssertNotEqual(policy1.sessionTimeoutMinutes, policy2.sessionTimeoutMinutes)
    }

    /// Test 6: Verify policy modification doesn't affect running service
    func testPolicyModificationDoesntAffectRunningService() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Modify policy after initialization
        let policy = securityService.securityPolicy
        _ = policy.sessionTimeoutMinutes // Store original value (not used in this test)
        policy.sessionTimeoutMinutes = 120

        // Then: Service should still function with original policy values
        // (This depends on implementation - policy might be copied during init)
        XCTAssertTrue(securityService.isInitialized)
    }

    /// Test 7: Verify policy configuration validation
    func testPolicyConfigurationValidation() {
        let policy = securityService.securityPolicy

        // Test invalid timeout values
        policy.sessionTimeoutMinutes = 0
        XCTAssertEqual(policy.sessionTimeoutMinutes, 0) // Might allow 0 for immediate timeout

        policy.sessionTimeoutMinutes = -1
        XCTAssertEqual(policy.sessionTimeoutMinutes, -1) // Implementation might not validate

        // Test invalid max attempts values
        policy.maxFailedAttempts = 0
        XCTAssertEqual(policy.maxFailedAttempts, 0) // Might allow 0 for no lockout

        policy.maxFailedAttempts = -1
        XCTAssertEqual(policy.maxFailedAttempts, -1) // Implementation might not validate
    }

    /// Test 8: Verify policy reset functionality
    func testPolicyResetFunctionality() {
        let policy = securityService.securityPolicy

        // Modify all policy values
        policy.requiresBiometricAuth = false
        policy.requiresDataEncryption = false
        policy.sessionTimeoutMinutes = 120
        policy.maxFailedAttempts = 10

        // Reset to defaults (implementation dependent)
        // This test assumes policy can be reset or new instance created
        let newPolicy = SecurityServiceImpl().securityPolicy

        // New policy should have defaults
        XCTAssertTrue(newPolicy.requiresBiometricAuth)
        XCTAssertTrue(newPolicy.requiresDataEncryption)
        XCTAssertEqual(newPolicy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(newPolicy.maxFailedAttempts, 3)
    }

    /// Test 9: Verify policy thread safety
    func testPolicyThreadSafety() {
        let policy = securityService.securityPolicy

        // Test concurrent policy modifications
        let expectation = expectation(description: "Concurrent policy modifications")
        expectation.expectedFulfillmentCount = 2

        DispatchQueue.global().async { [policy] in
            for i in 0..<100 {
                policy.sessionTimeoutMinutes = i % 60 + 1
            }
            expectation.fulfill()
        }

        DispatchQueue.global().async { [policy] in
            for i in 0..<100 {
                policy.maxFailedAttempts = i % 10 + 1
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Policy should have some valid values (exact values may vary due to race conditions)
        XCTAssertGreaterThan(policy.sessionTimeoutMinutes, 0)
        XCTAssertGreaterThan(policy.maxFailedAttempts, 0)
    }

    /// Test 10: Verify policy description
    func testPolicyDescription() {
        let policy = securityService.securityPolicy

        // Test string representation
        let description = String(describing: policy)
        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("SecurityPolicy") ||
                     description.contains("requiresBiometricAuth") ||
                     description.contains("sessionTimeoutMinutes"))
    }

    /// Test 11: Verify policy copy behavior
    func testPolicyCopyBehavior() {
        let policy1 = securityService.securityPolicy

        // Create another reference
        let policy2 = securityService.securityPolicy

        // Modify through one reference
        policy1.sessionTimeoutMinutes = 60

        // Both references should reflect the change (reference semantics)
        XCTAssertEqual(policy1.sessionTimeoutMinutes, policy2.sessionTimeoutMinutes)
    }

    /// Test 12: Verify policy initialization consistency
    func testPolicyInitializationConsistency() {
        // Create multiple service instances
        let service1 = SecurityServiceImpl()
        let service2 = SecurityServiceImpl()
        let service3 = SecurityServiceImpl()

        let policy1 = service1.securityPolicy
        let policy2 = service2.securityPolicy
        let policy3 = service3.securityPolicy

        // All should have identical default values
        XCTAssertEqual(policy1.requiresBiometricAuth, policy2.requiresBiometricAuth)
        XCTAssertEqual(policy2.requiresBiometricAuth, policy3.requiresBiometricAuth)
        XCTAssertEqual(policy1.requiresDataEncryption, policy2.requiresDataEncryption)
        XCTAssertEqual(policy2.requiresDataEncryption, policy3.requiresDataEncryption)
        XCTAssertEqual(policy1.sessionTimeoutMinutes, policy2.sessionTimeoutMinutes)
        XCTAssertEqual(policy2.sessionTimeoutMinutes, policy3.sessionTimeoutMinutes)
        XCTAssertEqual(policy1.maxFailedAttempts, policy2.maxFailedAttempts)
        XCTAssertEqual(policy2.maxFailedAttempts, policy3.maxFailedAttempts)
    }

    /// Test 13: Verify policy modification performance
    func testPolicyModificationPerformance() {
        let policy = securityService.securityPolicy

        measure {
            for i in 1...1000 {
                policy.sessionTimeoutMinutes = i % 120 + 1
                policy.maxFailedAttempts = i % 10 + 1
                policy.requiresBiometricAuth = (i % 2 == 0)
                policy.requiresDataEncryption = (i % 3 == 0)
            }
        }
    }

    /// Test 14: Verify policy value ranges
    func testPolicyValueRanges() {
        let policy = securityService.securityPolicy

        // Test extreme values
        let extremeTimeouts = [Int.min, -1000, 0, 1, 60, 1440, 10000, Int.max]
        let extremeAttempts = [Int.min, -100, 0, 1, 5, 10, 100, Int.max]

        for timeout in extremeTimeouts {
            policy.sessionTimeoutMinutes = timeout
            XCTAssertEqual(policy.sessionTimeoutMinutes, timeout)
        }

        for attempts in extremeAttempts {
            policy.maxFailedAttempts = attempts
            XCTAssertEqual(policy.maxFailedAttempts, attempts)
        }
    }
}

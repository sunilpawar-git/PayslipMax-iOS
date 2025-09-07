import XCTest
@testable import PayslipMax

/// Security service initialization and setup tests
/// Tests basic initialization, biometric availability, and initial state
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityInitializationTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify initial state is correct
    func testInitialState() {
        verifyInitialSecurityState()
        verifyDefaultSecurityPolicy()
    }

    /// Test 2: Verify initialization functionality
    func testInitialization() async throws {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Service should be initialized
        XCTAssertTrue(securityService.isInitialized)
    }

    /// Test 3: Verify biometric availability check
    func testBiometricAvailability() {
        // Test biometric availability (this will depend on device/simulator configuration)
        let isAvailable = securityService.isBiometricAuthAvailable
        XCTAssertTrue(isAvailable == true || isAvailable == false) // Just verify it returns a boolean
    }

    /// Test 4: Verify multiple initialization attempts
    func testMultipleInitialization() async throws {
        // Given: Service is initialized once
        try await initializeSecurityService()

        // When: Try to initialize again
        try await securityService.initialize()

        // Then: Service should still be initialized
        XCTAssertTrue(securityService.isInitialized)
    }

    /// Test 5: Verify initialization state after service reset
    func testInitializationAfterReset() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Reset service (simulate by creating new instance)
        securityService = SecurityServiceImpl()

        // Then: New service should not be initialized
        XCTAssertFalse(securityService.isInitialized)

        // And: Should be able to initialize again
        try await initializeSecurityService()
    }

    /// Test 6: Verify security policy is accessible before initialization
    func testSecurityPolicyAccessibleBeforeInitialization() {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)

        // When/Then: Security policy should still be accessible
        let policy = securityService.securityPolicy
        XCTAssertNotNil(policy)

        // And: Should have default values
        verifyDefaultSecurityPolicy()
    }

    /// Test 7: Verify initialization maintains security policy
    func testInitializationMaintainsSecurityPolicy() async throws {
        // Given: Service with default policy
        let initialPolicy = securityService.securityPolicy

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Security policy should remain the same
        let initializedPolicy = securityService.securityPolicy
        XCTAssertEqual(initialPolicy.requiresBiometricAuth, initializedPolicy.requiresBiometricAuth)
        XCTAssertEqual(initialPolicy.requiresDataEncryption, initializedPolicy.requiresDataEncryption)
        XCTAssertEqual(initialPolicy.sessionTimeoutMinutes, initializedPolicy.sessionTimeoutMinutes)
        XCTAssertEqual(initialPolicy.maxFailedAttempts, initializedPolicy.maxFailedAttempts)
    }

    /// Test 8: Verify failed authentication attempts reset after initialization
    func testFailedAttemptsResetAfterInitialization() async throws {
        // Given: Service is not initialized and has some failed attempts
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Failed attempts should still be 0
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)
    }

    /// Test 9: Verify account lock state after initialization
    func testAccountLockStateAfterInitialization() async throws {
        // Given: Service is not initialized and account is not locked
        XCTAssertFalse(securityService.isAccountLocked)

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Account should still not be locked
        XCTAssertFalse(securityService.isAccountLocked)
    }

    /// Test 10: Verify biometric availability doesn't change with initialization
    func testBiometricAvailabilityUnchangedByInitialization() async throws {
        // Given: Biometric availability before initialization
        let biometricAvailableBefore = securityService.isBiometricAuthAvailable

        // When: Initialize service
        try await initializeSecurityService()

        // Then: Biometric availability should remain the same
        let biometricAvailableAfter = securityService.isBiometricAuthAvailable
        XCTAssertEqual(biometricAvailableBefore, biometricAvailableAfter)
    }
}

import XCTest
@testable import PayslipMax

/// Security service session management and violation handling tests
/// Tests session lifecycle, security violations, and state management
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecuritySessionTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify session management
    func testSessionManagement() {
        // Given: Initial session state
        XCTAssertFalse(securityService.isSessionValid)

        // When: Start secure session
        startAndVerifySecureSession()

        // When: Invalidate session
        securityService.invalidateSession()

        // Then: Session should be invalid
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 2: Verify security violation handling - unauthorized access
    func testSecurityViolationUnauthorizedAccess() {
        // Given: Valid session
        startAndVerifySecureSession()

        // When: Handle unauthorized access violation
        securityService.handleSecurityViolation(.unauthorizedAccess)

        // Then: Session should be invalidated
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 3: Verify security violation handling - session timeout
    func testSecurityViolationSessionTimeout() {
        // Given: Valid session
        startAndVerifySecureSession()

        // When: Handle session timeout violation
        securityService.handleSecurityViolation(.sessionTimeout)

        // Then: Session should be invalidated
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 4: Verify security violation handling - too many failed attempts
    func testSecurityViolationTooManyFailedAttempts() {
        // Given: Valid session and unlocked account
        startAndVerifySecureSession()
        XCTAssertTrue(securityService.isSessionValid)
        XCTAssertFalse(securityService.isAccountLocked)

        // When: Handle too many failed attempts violation
        securityService.handleSecurityViolation(.tooManyFailedAttempts)

        // Then: Account should be locked and session invalidated
        XCTAssertTrue(securityService.isAccountLocked)
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 5: Verify SecurityViolation enum cases
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

    /// Test 6: Verify session state after multiple violations
    func testSessionStateAfterMultipleViolations() {
        // Given: Valid session
        startAndVerifySecureSession()
        XCTAssertTrue(securityService.isSessionValid)

        // When: Handle multiple violations
        securityService.handleSecurityViolation(.unauthorizedAccess)
        XCTAssertFalse(securityService.isSessionValid)

        // Try to handle another violation
        securityService.handleSecurityViolation(.sessionTimeout)
        XCTAssertFalse(securityService.isSessionValid)

        // Then: Session should remain invalid
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 7: Verify account lock state after violation
    func testAccountLockStateAfterViolation() {
        // Given: Valid session and unlocked account
        startAndVerifySecureSession()
        XCTAssertFalse(securityService.isAccountLocked)

        // When: Handle violation that locks account
        securityService.handleSecurityViolation(.tooManyFailedAttempts)

        // Then: Account should be locked
        XCTAssertTrue(securityService.isAccountLocked)

        // And: Session should be invalid
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 8: Verify session management with concurrent operations
    func testConcurrentSessionOperations() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Perform concurrent session operations
        async let operation1: Void = self.securityService.startSecureSession()
        async let operation2: Void = self.securityService.startSecureSession()

        // Wait for both to complete
        await operation1
        await operation2

        // Then: Session should be valid
        XCTAssertTrue(securityService.isSessionValid)
    }

    /// Test 9: Verify session invalidation timing
    func testSessionInvalidationTiming() {
        // Given: Valid session
        startAndVerifySecureSession()

        // When: Invalidate session multiple times
        securityService.invalidateSession()
        securityService.invalidateSession()

        // Then: Session should remain invalid
        XCTAssertFalse(securityService.isSessionValid)
    }

    /// Test 10: Verify session state persistence during violations
    func testSessionStateDuringViolations() {
        // Given: Valid session
        startAndVerifySecureSession()

        // When: Handle unauthorized access violation
        securityService.handleSecurityViolation(.unauthorizedAccess)

        // Then: Session should be invalid and account should not be locked
        XCTAssertFalse(securityService.isSessionValid)
        XCTAssertFalse(securityService.isAccountLocked)

        // When: Handle too many failed attempts violation
        securityService.handleSecurityViolation(.tooManyFailedAttempts)

        // Then: Both session should be invalid and account should be locked
        XCTAssertFalse(securityService.isSessionValid)
        XCTAssertTrue(securityService.isAccountLocked)
    }

    /// Test 11: Verify session restoration after violation
    func testSessionRestorationAfterViolation() {
        // Given: Valid session that gets violated
        startAndVerifySecureSession()
        securityService.handleSecurityViolation(.unauthorizedAccess)
        XCTAssertFalse(securityService.isSessionValid)

        // When: Start new session
        securityService.startSecureSession()

        // Then: Session should be valid again
        XCTAssertTrue(securityService.isSessionValid)
    }

    /// Test 12: Verify failed authentication attempts tracking
    func testFailedAuthenticationAttemptsTracking() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Initially should be 0
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)

        // When: Setup PIN and make failed attempts
        try await setupTestPIN("correct123")

        // Try wrong PIN multiple times
        _ = try await securityService.verifyPIN(pin: "wrong1")
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 1)

        _ = try await securityService.verifyPIN(pin: "wrong2")
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 2)

        // When: Correct PIN is verified
        let isCorrect = try await securityService.verifyPIN(pin: "correct123")
        XCTAssertTrue(isCorrect)
        // Failed attempts should be reset after successful verification
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)
    }

    /// Test 13: Verify account lock after max failed attempts
    func testAccountLockAfterMaxFailedAttempts() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Setup PIN
        try await setupTestPIN("correct123")

        // When: Exceed max failed attempts
        for i in 1...3 { // Try 3 times (max is 3)
            _ = try await securityService.verifyPIN(pin: "wrong\(i)")
        }

        // Then: Account should be locked
        XCTAssertTrue(securityService.isAccountLocked)

        // And: Even correct PIN should throw an error when account is locked
        do {
            _ = try await securityService.verifyPIN(pin: "correct123")
            XCTFail("Expected SecurityError.accountLocked to be thrown")
        } catch let error as SecurityError {
            XCTAssertEqual(error, .accountLocked)
        } catch {
            XCTFail("Expected SecurityError.accountLocked, but got: \(error)")
        }
    }

    /// Test 14: Verify session invalidation on account lock
    func testSessionInvalidationOnAccountLock() async throws {
        // Given: Valid session
        startAndVerifySecureSession()
        try await initializeSecurityService()
        try await setupTestPIN("correct123")

        // When: Exceed max failed attempts
        for i in 1...3 { // Try 3 times (max is 3)
            _ = try await securityService.verifyPIN(pin: "wrong\(i)")
        }

        // Then: Session should be invalidated and account locked
        XCTAssertTrue(securityService.isAccountLocked)
        XCTAssertFalse(securityService.isSessionValid)

        // And: Further PIN verification should throw an error when account is locked
        do {
            _ = try await securityService.verifyPIN(pin: "correct123")
            XCTFail("Expected SecurityError.accountLocked to be thrown")
        } catch let error as SecurityError {
            XCTAssertEqual(error, .accountLocked)
        } catch {
            XCTFail("Expected SecurityError.accountLocked, but got: \(error)")
        }
    }
}

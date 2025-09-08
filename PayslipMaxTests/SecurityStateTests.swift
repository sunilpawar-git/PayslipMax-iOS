import XCTest
@testable import PayslipMax

/// Security service state consistency tests
/// Tests service state management and transitions
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityStateTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

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
}

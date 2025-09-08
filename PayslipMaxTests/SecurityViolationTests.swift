import XCTest
@testable import PayslipMax

/// Security service violation handling tests
/// Tests SecurityViolation enum cases and handling
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityViolationTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

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
}

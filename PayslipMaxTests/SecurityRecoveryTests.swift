import XCTest
@testable import PayslipMax

/// Security service recovery and failure handling tests
/// Tests service recovery after failures and error conditions
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityRecoveryTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

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
}

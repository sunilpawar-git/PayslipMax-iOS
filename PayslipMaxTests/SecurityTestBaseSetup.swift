import XCTest
import Foundation
@testable import PayslipMax

/// Base test setup class for security tests
/// Provides common setup/teardown logic and test utilities
/// Follows SOLID principles with protocol-based design
@MainActor
class SecurityTestBaseSetup: XCTestCase {

    // MARK: - Test Properties

    var securityService: SecurityServiceImpl!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        securityService = SecurityServiceImpl()

        // Clear any existing PIN from UserDefaults to ensure clean test state
        UserDefaults.standard.removeObject(forKey: "app_pin")

        // Clear any secure data from previous tests
        let keysToRemove = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("secure_") }
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        securityService = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Helper method to initialize security service with error handling
    func initializeSecurityService() async throws {
        XCTAssertFalse(securityService.isInitialized, "Service should not be initialized initially")
        try await securityService.initialize()
        XCTAssertTrue(securityService.isInitialized, "Service should be initialized after setup")
    }

    /// Helper method to setup PIN with validation
    func setupTestPIN(_ pin: String = "1234") async throws {
        try await securityService.setupPIN(pin: pin)
    }

    /// Helper method to verify initial security state
    func verifyInitialSecurityState() {
        XCTAssertFalse(securityService.isInitialized)
        XCTAssertFalse(securityService.isSessionValid)
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)
        XCTAssertFalse(securityService.isAccountLocked)
        XCTAssertNotNil(securityService.securityPolicy)
    }

    /// Helper method to verify default security policy
    func verifyDefaultSecurityPolicy() {
        let policy = securityService.securityPolicy
        XCTAssertTrue(policy.requiresBiometricAuth)
        XCTAssertTrue(policy.requiresDataEncryption)
        XCTAssertEqual(policy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(policy.maxFailedAttempts, 3)
    }

    /// Helper method to create test data
    func createTestData(_ content: String = "Test Data") -> Data {
        return content.data(using: .utf8)!
    }

    /// Helper method to start and verify secure session
    func startAndVerifySecureSession() {
        XCTAssertFalse(securityService.isSessionValid, "Session should not be valid initially")

        securityService.startSecureSession()

        XCTAssertTrue(securityService.isSessionValid, "Session should be valid after starting")
    }

    /// Helper method to clear all secure data for clean test state
    func clearAllSecureData() {
        let keysToRemove = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("secure_") }
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

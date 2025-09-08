import Foundation
@testable import PayslipMax

/// Mock security service for testing
/// Implements SecurityServiceProtocol with configurable failure modes
/// Follows SOLID principles with single responsibility for security mocking
public class MockSecurityService: SecurityServiceProtocol {
    public var isInitialized: Bool = true
    public var shouldFailAuth = false
    public var shouldFail = false  // Added for test compatibility
    public var authenticateCallCount = 0

    // MARK: - SecurityServiceProtocol Properties
    public var isBiometricAuthAvailable: Bool = true
    public var isSessionValid: Bool = true
    public var failedAuthenticationAttempts: Int = 0
    public var isAccountLocked: Bool = false
    public var securityPolicy: SecurityPolicy = SecurityPolicy()

    // MARK: - ServiceProtocol Methods
    public func initialize() async throws {
        if shouldFailAuth || shouldFail {
            isInitialized = false
            throw MockError.initializationFailed
        }
        isInitialized = true
    }

    // MARK: - Authentication Methods
    public func authenticateWithBiometrics() async throws -> Bool {
        authenticateCallCount += 1
        if shouldFailAuth { throw MockError.authenticationFailed }
        return true
    }

    public func authenticateWithBiometrics(reason: String) async throws {
        authenticateCallCount += 1
        if shouldFailAuth { throw MockError.authenticationFailed }
    }

    public func setupPIN(pin: String) async throws {
        if shouldFailAuth { throw MockError.authenticationFailed }
    }

    public func verifyPIN(pin: String) async throws -> Bool {
        if shouldFailAuth { throw MockError.authenticationFailed }
        return true
    }

    // MARK: - Encryption Methods
    public func encryptData(_ data: Data) async throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }

    public func decryptData(_ data: Data) async throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }

    public func encryptData(_ data: Data) throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }

    public func decryptDataSync(_ data: Data) throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }

    // MARK: - Session Management
    public func startSecureSession() {
        isSessionValid = true
    }

    public func invalidateSession() {
        isSessionValid = false
    }

    // MARK: - Keychain Operations
    public func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        return !shouldFailAuth
    }

    public func retrieveSecureData(forKey key: String) -> Data? {
        return shouldFailAuth ? nil : Data("mock secure data".utf8)
    }

    public func deleteSecureData(forKey key: String) -> Bool {
        return !shouldFailAuth
    }

    // MARK: - Security Violations
    public func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .tooManyFailedAttempts:
            isAccountLocked = true
        case .sessionTimeout:
            isSessionValid = false
        case .unauthorizedAccess:
            invalidateSession()
        }
    }
}

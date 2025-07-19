import Foundation

// Import the protocols and types we need from the main module
// Note: Since this is in the main module, we can access types directly

/// Mock implementation of SecurityServiceProtocol for testing purposes.
///
/// This mock service provides controllable behavior for testing security-related functionality
/// without requiring actual biometric authentication or encryption operations.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class CoreMockSecurityService: SecurityServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether the service is considered initialized
    var isInitialized: Bool = false
    
    /// Controls whether authentication operations should succeed
    var shouldAuthenticateSuccessfully = true
    
    /// Controls whether operations should fail with errors
    var shouldFail = false
    
    /// The result data to return from encryption operations
    var encryptionResult: Data?
    
    /// The result data to return from decryption operations
    var decryptionResult: Data?
    
    /// Controls whether biometric authentication is available
    var isBiometricAuthAvailable: Bool = true
    
    /// Session validity status
    var isSessionValid: Bool = false
    
    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int = 0
    
    /// Account locked status
    var isAccountLocked: Bool = false
    
    /// Security policy configuration
    var securityPolicy: SecurityPolicy = SecurityPolicy()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        isInitialized = false
        shouldAuthenticateSuccessfully = true
        shouldFail = false
        encryptionResult = nil
        decryptionResult = nil
        isBiometricAuthAvailable = true
    }
    
    // MARK: - SecurityServiceProtocol Implementation
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
    
    func setupPIN(pin: String) async throws {
        if shouldFail {
            throw MockError.setupPINFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        if shouldFail {
            throw MockError.verifyPINFailed
        }
        return pin == "1234" // Simple mock implementation
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockError.encryptionFailed
        }
        // If encryptionResult is explicitly set, return it
        if let result = encryptionResult {
            return result
        }
        // Otherwise, simulate encryption by adding a prefix
        let prefix = "ENCRYPTED:".data(using: .utf8)!
        return prefix + data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockError.decryptionFailed
        }
        // If decryptionResult is explicitly set, return it
        if let result = decryptionResult {
            return result
        }
        // Otherwise, simulate decryption by removing the "ENCRYPTED:" prefix
        let prefix = "ENCRYPTED:".data(using: .utf8)!
        if data.starts(with: prefix) {
            return Data(data.dropFirst(prefix.count))
        }
        // If data doesn't have the expected prefix, just return it as-is
        return data
    }
    
    func authenticateWithBiometrics(reason: String) async throws {
        if shouldFail {
            throw MockError.authenticationFailed
        }
    }
    
    func encryptData(_ data: Data) throws -> Data {
        if shouldFail {
            throw MockError.encryptionFailed
        }
        // If encryptionResult is explicitly set, return it
        if let result = encryptionResult {
            return result
        }
        // Otherwise, simulate encryption by adding a prefix
        let prefix = "ENCRYPTED:".data(using: .utf8)!
        return prefix + data
    }
    
    func decryptData(_ data: Data) throws -> Data {
        if shouldFail {
            throw MockError.decryptionFailed
        }
        // If decryptionResult is explicitly set, return it
        if let result = decryptionResult {
            return result
        }
        // Otherwise, simulate decryption by removing the "ENCRYPTED:" prefix
        let prefix = "ENCRYPTED:".data(using: .utf8)!
        if data.starts(with: prefix) {
            return Data(data.dropFirst(prefix.count))
        }
        // If data doesn't have the expected prefix, just return it as-is
        return data
    }
    
    func startSecureSession() {
        isSessionValid = true
    }
    
    func invalidateSession() {
        isSessionValid = false
    }
    
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        return !shouldFail
    }
    
    func retrieveSecureData(forKey key: String) -> Data? {
        return shouldFail ? nil : "mock_data".data(using: .utf8)
    }
    
    func deleteSecureData(forKey key: String) -> Bool {
        return !shouldFail
    }
    
    func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .unauthorizedAccess, .sessionTimeout:
            invalidateSession()
        case .tooManyFailedAttempts:
            isAccountLocked = true
            invalidateSession()
        }
    }
} 
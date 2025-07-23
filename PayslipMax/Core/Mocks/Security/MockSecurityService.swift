import Foundation

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
        if let result = encryptionResult {
            return result
        }
        // Return a modified version of the data to simulate encryption
        var modifiedData = data
        modifiedData.append(contentsOf: [0xFF, 0xEE, 0xDD, 0xCC]) // Add some bytes
        return modifiedData
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Remove the extra bytes that were added during encryption
        if data.count >= 4 {
            return Data(data.dropLast(4))
        }
        // Fallback if the data is too short
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
        if let result = encryptionResult {
            return result
        }
        // Return a modified version of the data to simulate encryption
        var modifiedData = data
        modifiedData.append(contentsOf: [0xFF, 0xEE, 0xDD, 0xCC]) // Add some bytes
        return modifiedData
    }
    
    func decryptData(_ data: Data) throws -> Data {
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Remove the extra bytes that were added during encryption
        if data.count >= 4 {
            return Data(data.dropLast(4))
        }
        // Fallback if the data is too short
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
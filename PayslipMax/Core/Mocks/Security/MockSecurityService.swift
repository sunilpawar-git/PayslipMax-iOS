import Foundation

/// Mock implementation of SecurityServiceProtocol for testing purposes.
///
/// This mock service provides controllable behavior for testing security-related functionality
/// without requiring actual biometric authentication or encryption operations.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockSecurityService: SecurityServiceProtocol {
    
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
        return encryptionResult ?? data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockError.decryptionFailed
        }
        return decryptionResult ?? data
    }
} 
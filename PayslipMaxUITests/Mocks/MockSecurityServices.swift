import Foundation

// MARK: - Service Protocols

/// Base protocol for all services
protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

/// Protocol for security-related services
protocol SecurityServiceProtocol: ServiceProtocol {
    var isBiometricAuthAvailable: Bool { get }
    
    func encrypt(_ data: String) throws -> String
    func decrypt(_ data: String) throws -> String
    func authenticate() -> Bool
    func logout()
    func authenticateWithBiometrics() async throws -> Bool
    func setupPIN(pin: String) async throws
    func verifyPIN(pin: String) async throws -> Bool
    func encryptData(_ data: Data) async throws -> Data
    func decryptData(_ data: Data) async throws -> Data
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isAuthenticated = false
    var encryptionError: Error?
    var decryptionError: Error?
    var isValidBiometricAuth = true
    var isInitialized: Bool = true
    var isBiometricAuthAvailable: Bool = true
    
    func reset() {
        isAuthenticated = false
        encryptionError = nil
        decryptionError = nil
        isValidBiometricAuth = true
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func encrypt(_ data: String) throws -> String {
        if let error = encryptionError {
            throw error
        }
        return "ENCRYPTED_\(data)"
    }
    
    func decrypt(_ data: String) throws -> String {
        if let error = decryptionError {
            throw error
        }
        return data.replacingOccurrences(of: "ENCRYPTED_", with: "")
    }
    
    func authenticate() -> Bool {
        isAuthenticated = true
        return isAuthenticated
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        if isValidBiometricAuth {
            isAuthenticated = true
            return true
        } else {
            throw NSError(domain: "com.payslipmax.auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication failed"])
        }
    }
    
    func setupPIN(pin: String) async throws {
        // No-op implementation for testing
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        return true // Always return true for testing
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        if let error = encryptionError {
            throw error
        }
        return data // Mock implementation for testing
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if let error = decryptionError {
            throw error
        }
        return data // Mock implementation for testing
    }
} 
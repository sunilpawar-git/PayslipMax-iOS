import Foundation
import LocalAuthentication

/// Errors that can occur during authentication
enum AuthError: LocalizedError {
    case invalidPINLength
    case invalidPIN
    case biometricsNotAvailable
    case authenticationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidPINLength:
            return "PIN must be 4 digits"
        case .invalidPIN:
            return "Invalid PIN"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}

/// Protocol defining authentication operations
protocol AuthenticationService {
    /// Authenticates the user
    /// - Returns: A boolean indicating whether authentication was successful
    /// - Throws: An error if authentication fails
    func authenticate() async throws -> Bool
    
    /// Validates a PIN code
    /// - Parameter pin: The PIN code to validate
    /// - Returns: A boolean indicating whether the PIN is valid
    /// - Throws: An error if validation fails
    func validatePIN(_ pin: String) async throws -> Bool
}

/// Default implementation of AuthenticationService using SecurityServiceProtocol
class DefaultAuthenticationService: AuthenticationService {
    private let securityService: SecurityServiceProtocol
    
    init(securityService: SecurityServiceProtocol) {
        self.securityService = securityService
    }
    
    func authenticate() async throws -> Bool {
        do {
            return try await securityService.authenticate()
        } catch {
            throw AuthError.authenticationFailed(error)
        }
    }
    
    func validatePIN(_ pin: String) async throws -> Bool {
        guard pin.count == 4 else {
            throw AuthError.invalidPINLength
        }
        
        // In a real implementation, this would validate against a stored PIN
        // For now, we'll just check if it's all digits
        guard pin.allSatisfy({ $0.isNumber }) else {
            throw AuthError.invalidPIN
        }
        
        return true
    }
} 
import Foundation
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published var pinCode: String = ""
    @Published var isBiometricAuthEnabled: Bool = false
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    
    var isBiometricAvailable: Bool {
        return securityService.isBiometricAuthAvailable
    }
    
    // MARK: - Initialization
    init(securityService: SecurityServiceProtocol? = nil) {
        self.securityService = securityService ?? DIContainer.shared.securityService
    }
    
    // MARK: - Public Methods
    func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            isAuthenticated = try await securityService.authenticateWithBiometrics()
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    func validatePIN() async throws -> Bool {
        guard pinCode.count == 4 else {
            throw AuthError.invalidPINLength
        }
        
        // Use the security service to verify the PIN
        return try await securityService.verifyPIN(pin: pinCode)
    }
    
    func setupPIN() async throws {
        guard pinCode.count == 4 else {
            throw AuthError.invalidPINLength
        }
        
        // Use the security service to set up the PIN
        try await securityService.setupPIN(pin: pinCode)
    }
    
    func logout() {
        isAuthenticated = false
        pinCode = ""
    }
}

// MARK: - Supporting Types
extension AuthViewModel {
    enum AuthError: LocalizedError {
        case invalidPINLength
        case invalidPIN
        case biometricsNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .invalidPINLength:
                return "PIN must be 4 digits"
            case .invalidPIN:
                return "Invalid PIN"
            case .biometricsNotAvailable:
                return "Biometric authentication is not available"
            }
        }
    }
} 
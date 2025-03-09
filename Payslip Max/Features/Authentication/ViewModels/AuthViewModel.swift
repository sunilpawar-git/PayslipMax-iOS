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
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
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
            isAuthenticated = try await securityService.authenticate()
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    func validatePIN() async throws {
        guard pinCode.count == 4 else {
            throw AuthError.invalidPINLength
        }
        // Add PIN validation logic
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
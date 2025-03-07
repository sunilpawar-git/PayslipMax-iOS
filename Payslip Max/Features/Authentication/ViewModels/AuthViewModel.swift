import Foundation
import LocalAuthentication

/// View model for handling authentication
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Indicates whether the user is authenticated
    @Published private(set) var isAuthenticated = false
    
    /// Indicates whether an authentication operation is in progress
    @Published private(set) var isLoading = false
    
    /// The error that occurred during the last authentication attempt, if any
    @Published var error: Error?
    
    /// The PIN code entered by the user
    @Published var pinCode: String = ""
    
    // MARK: - Properties
    
    /// The service used for authentication
    private let authService: AuthenticationService
    
    // MARK: - Initialization
    
    /// Initializes the view model with the specified authentication service
    /// - Parameter authService: The service to use for authentication (defaults to a service created from the DI container)
    init(authService: AuthenticationService? = nil) {
        if let authService = authService {
            self.authService = authService
        } else {
            let securityService = DIContainer.shared.resolve(SecurityServiceProtocol.self)
            self.authService = DefaultAuthenticationService(securityService: securityService)
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticates the user
    func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            isAuthenticated = try await authService.authenticate()
            error = nil
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    /// Validates the current PIN code
    func validatePIN() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            isAuthenticated = try await authService.validatePIN(pinCode)
            error = nil
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    /// Logs the user out
    func logout() {
        isAuthenticated = false
        pinCode = ""
        error = nil
    }
    
    // MARK: - Helper Methods
    
    /// Clears the current PIN code
    func clearPIN() {
        pinCode = ""
    }
    
    /// Adds a digit to the PIN code
    /// - Parameter digit: The digit to add
    func addDigit(_ digit: String) {
        guard pinCode.count < 4, digit.count == 1, digit.allSatisfy({ $0.isNumber }) else {
            return
        }
        
        pinCode += digit
    }
    
    /// Removes the last digit from the PIN code
    func removeLastDigit() {
        guard !pinCode.isEmpty else {
            return
        }
        
        pinCode.removeLast()
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
import Foundation
import LocalAuthentication

/// A view model responsible for handling user authentication, including PIN and biometric authentication.
/// It manages the authentication state and interacts with the security service.
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Indicates whether the user is currently authenticated.
    @Published private(set) var isAuthenticated = false

    /// Indicates if an authentication operation is in progress.
    @Published private(set) var isLoading = false

    /// Holds any error that occurred during authentication.
    @Published var error: Error?

    /// The PIN code entered by the user.
    @Published var pinCode: String = ""

    /// Indicates if the user has enabled biometric authentication.
    @Published var isBiometricAuthEnabled: Bool = false
    
    // MARK: - Properties

    /// The security service used for authentication operations.
    private let securityService: SecurityServiceProtocol
    
    /// Indicates if biometric authentication (Face ID or Touch ID) is available on the device.
    var isBiometricAvailable: Bool {
        return securityService.isBiometricAuthAvailable
    }
    
    // MARK: - Initialization

    /// Initializes the AuthViewModel.
    /// - Parameter securityService: The security service to use for authentication operations.
    ///                                If `nil`, it resolves the default service from `DIContainer.shared`.
    init(securityService: SecurityServiceProtocol? = nil) {
        self.securityService = securityService ?? DIContainer.shared.securityService
    }
    
    // MARK: - Public Methods

    /// Attempts to authenticate the user using biometrics (Face ID or Touch ID).
    /// Updates `isAuthenticated` and `error` properties based on the outcome.
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
    
    /// Validates the entered PIN code.
    ///
    /// - Throws: `AuthError.invalidPINLength` if the PIN is not 4 digits.
    ///           Also rethrows any error produced by `securityService.verifyPIN`.
    ///
    /// - Returns: `true` if the PIN is verified successfully, `false` otherwise (though typically throws on failure).
    func validatePIN() async throws -> Bool {
        guard pinCode.count == 4 else {
            throw AuthError.invalidPINLength
        }
        
        // Use the security service to verify the PIN
        return try await securityService.verifyPIN(pin: pinCode)
    }
    
    /// Sets up a new PIN code for the user.
    ///
    /// - Throws: `AuthError.invalidPINLength` if the PIN is not 4 digits.
    ///           Also rethrows any error produced by `securityService.setupPIN`.
    func setupPIN() async throws {
        guard pinCode.count == 4 else {
            throw AuthError.invalidPINLength
        }
        
        // Use the security service to set up the PIN
        try await securityService.setupPIN(pin: pinCode)
    }
    
    /// Logs the user out by resetting the authentication state.
    func logout() {
        isAuthenticated = false
        pinCode = ""
    }
}

// MARK: - Supporting Types
extension AuthViewModel {
    /// Defines errors specific to the authentication process.
    enum AuthError: LocalizedError {
        /// Error indicating the entered PIN does not have the required length (4 digits).
        case invalidPINLength
        /// Error indicating the entered PIN is incorrect.
        case invalidPIN
        /// Error indicating that biometric authentication is not available or configured on the device.
        case biometricsNotAvailable
        
        /// Provides a user-friendly description for each authentication error.
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
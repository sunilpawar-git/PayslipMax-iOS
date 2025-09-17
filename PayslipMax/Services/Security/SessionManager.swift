import Foundation

/// Protocol defining session management operations
@MainActor
protocol SessionManagerProtocol {
    /// Session validity status
    var isSessionValid: Bool { get }

    /// Starts a secure session
    func startSecureSession()

    /// Invalidates the current session
    func invalidateSession()

    /// Handles security violations and takes appropriate actions
    func handleSecurityViolation(_ violation: SecurityViolation)
}

/// Manager responsible for session management and security violation handling.
/// Tracks session state and handles security events that may require session invalidation.
/// This component is isolated for better testability and single responsibility.
@MainActor
final class SessionManager: SessionManagerProtocol {
    /// Session validity status
    var isSessionValid: Bool = false

    /// Default initializer.
    init() {}

    /// Starts a secure session
    func startSecureSession() {
        isSessionValid = true
    }

    /// Invalidates the current session
    func invalidateSession() {
        isSessionValid = false
    }

    /// Handles security violations and takes appropriate actions
    /// - Parameter violation: The type of security violation that occurred
    func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .unauthorizedAccess, .sessionTimeout:
            invalidateSession()
        case .tooManyFailedAttempts:
            invalidateSession()
            // Note: Account locking is handled by PINAuthenticationManager
        }
    }
}

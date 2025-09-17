import Foundation
import LocalAuthentication

/// Protocol defining biometric authentication operations
@MainActor
protocol BiometricAuthenticationManagerProtocol {
    /// Checks if biometric authentication is available on the device
    var isBiometricAuthAvailable: Bool { get }

    /// Authenticates the user using device biometrics
    func authenticateWithBiometrics() async throws -> Bool

    /// Authenticates the user using device biometrics with custom reason
    func authenticateWithBiometrics(reason: String) async throws
}

/// Manager responsible for biometric authentication operations.
/// Handles Face ID, Touch ID, and other biometric authentication methods.
/// This component is isolated for better testability and single responsibility.
@MainActor
final class BiometricAuthenticationManager: BiometricAuthenticationManagerProtocol {
    /// The LocalAuthentication context used for biometric checks.
    private let context = LAContext()

    /// Indicates whether biometric authentication (like Face ID or Touch ID) is available on the device.
    var isBiometricAuthAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Default initializer.
    init() {}

    /// Attempts to authenticate the user using device biometrics (Face ID, Touch ID).
    /// - Returns: `true` if authentication is successful, `false` otherwise.
    /// - Throws: `SecurityError.biometricsNotAvailable` if biometrics are not configured or available.
    ///         `SecurityError.authenticationFailed` if the authentication attempt fails for other reasons.
    func authenticateWithBiometrics() async throws -> Bool {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricsNotAvailable
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access payslip data"
            )
        } catch {
            throw SecurityError.authenticationFailed
        }
    }

    /// Authenticates the user using biometrics with a custom reason
    /// - Parameter reason: The localized reason to display during authentication
    /// - Throws: `SecurityError.biometricsNotAvailable` if biometrics are not configured or available.
    ///         `SecurityError.authenticationFailed` if the authentication attempt fails.
    func authenticateWithBiometrics(reason: String) async throws {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricsNotAvailable
        }

        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !result {
                throw SecurityError.authenticationFailed
            }
        } catch {
            throw SecurityError.authenticationFailed
        }
    }
}

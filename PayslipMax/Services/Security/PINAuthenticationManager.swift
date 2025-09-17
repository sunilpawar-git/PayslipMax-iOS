import Foundation
import CryptoKit

/// Protocol defining PIN authentication operations
@MainActor
protocol PINAuthenticationManagerProtocol {
    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int { get }

    /// Account locked status
    var isAccountLocked: Bool { get }

    /// Security policy configuration
    var securityPolicy: SecurityPolicy { get set }

    /// Sets up or updates the application PIN. The PIN is hashed using SHA256 before being stored securely.
    func setupPIN(pin: String) async throws

    /// Verifies a provided PIN against the stored, hashed PIN.
    func verifyPIN(pin: String) async throws -> Bool

    /// Resets the failed authentication attempts counter
    func resetFailedAttempts()

    /// Locks the account due to too many failed attempts
    func lockAccount()

    /// Unlocks the account (for testing purposes)
    func unlockAccount()
}

/// Manager responsible for PIN-based authentication operations.
/// Handles PIN setup, verification, and security policy enforcement.
/// This component is isolated for better testability and single responsibility.
@MainActor
final class PINAuthenticationManager: PINAuthenticationManagerProtocol {
    /// Standard UserDefaults instance for storing the hashed PIN.
    private let userDefaults = UserDefaults.standard
    /// The UserDefaults key for storing the hashed application PIN.
    private let pinKey = "app_pin"

    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int = 0

    /// Account locked status
    var isAccountLocked: Bool = false

    /// Security policy configuration
    var securityPolicy: SecurityPolicy

    /// Default initializer.
    init() {
        self.securityPolicy = SecurityPolicy()
    }

    /// Sets up or updates the application PIN. The PIN is hashed using SHA256 before being stored securely.
    /// - Parameter pin: The plain text PIN string provided by the user.
    func setupPIN(pin: String) async throws {
        // Hash the PIN before storing it
        let pinData = Data(pin.utf8)
        let hashedPin = SHA256.hash(data: pinData)
        let hashedPinString = hashedPin.compactMap { String(format: "%02x", $0) }.joined()

        // Store the hashed PIN
        userDefaults.set(hashedPinString, forKey: pinKey)
    }

    /// Verifies a provided PIN against the stored, hashed PIN.
    /// - Parameter pin: The plain text PIN string to verify.
    /// - Returns: `true` if the provided PIN matches the stored PIN, `false` otherwise.
    /// - Throws: `SecurityError.pinNotSet` if no PIN has been stored previously.
    ///         `SecurityError.accountLocked` if the account is locked due to too many failed attempts.
    func verifyPIN(pin: String) async throws -> Bool {
        // Check if account is locked
        guard !isAccountLocked else {
            throw SecurityError.accountLocked
        }

        // Hash the input PIN
        let pinData = Data(pin.utf8)
        let hashedPin = SHA256.hash(data: pinData)
        let hashedPinString = hashedPin.compactMap { String(format: "%02x", $0) }.joined()

        // Retrieve stored PIN
        guard let storedPin = userDefaults.string(forKey: pinKey) else {
            throw SecurityError.pinNotSet
        }

        // Compare the hashed PINs
        let isValid = storedPin == hashedPinString

        if isValid {
            // Reset failed attempts on successful verification
            failedAuthenticationAttempts = 0
        } else {
            // Increment failed attempts on failed verification
            failedAuthenticationAttempts += 1

            // Check if max attempts reached
            if failedAuthenticationAttempts >= securityPolicy.maxFailedAttempts {
                isAccountLocked = true
            }
        }

        return isValid
    }

    /// Resets the failed authentication attempts counter
    func resetFailedAttempts() {
        failedAuthenticationAttempts = 0
    }

    /// Locks the account due to too many failed attempts
    func lockAccount() {
        isAccountLocked = true
    }

    /// Unlocks the account (for testing purposes)
    func unlockAccount() {
        isAccountLocked = false
        failedAuthenticationAttempts = 0
    }
}

import Foundation
import LocalAuthentication
import CryptoKit

// Adding @MainActor attribute to ensure this class conforms to the @MainActor protocol
/// Provides implementation for security-related operations like biometric authentication, PIN management, and data encryption/decryption.
/// This class is designed to run on the main actor.
@MainActor
final class SecurityServiceImpl: SecurityServiceProtocol {
    /// The LocalAuthentication context used for biometric checks.
    private let context = LAContext()
    /// The symmetric key used for AES-GCM encryption/decryption. Generated on initialization.
    private var symmetricKey: SymmetricKey?
    /// Standard UserDefaults instance for storing the hashed PIN.
    private let userDefaults = UserDefaults.standard
    /// The UserDefaults key for storing the hashed application PIN.
    private let pinKey = "app_pin"
    /// Instance-specific storage for secure data (simulates isolated storage per service instance)
    private var secureDataStorage: [String: Data] = [:]

    /// Indicates whether biometric authentication (like Face ID or Touch ID) is available on the device.
    var isBiometricAuthAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Flag indicating whether the security service has been initialized (encryption key generated).
    var isInitialized: Bool = false

    /// Session validity status
    var isSessionValid: Bool = false

    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int = 0

    /// Account locked status
    var isAccountLocked: Bool = false

    /// Security policy configuration
    var securityPolicy: SecurityPolicy = SecurityPolicy()

    /// Default initializer.
    init() {}

    /// Initializes the security service by generating the symmetric encryption key.
    /// Must be called before performing encryption or decryption operations.
    /// Sets the `isInitialized` flag to true upon successful completion.
    /// - Throws: Does not currently throw, but signature allows for future initialization errors.
    func initialize() async throws {
        // Generate or retrieve encryption key
        symmetricKey = SymmetricKey(size: .bits256)
        isInitialized = true
    }

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

    /// Sets up or updates the application PIN. The PIN is hashed using SHA256 before being stored securely.
    /// Requires the service to be initialized first.
    /// - Parameter pin: The plain text PIN string provided by the user.
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    func setupPIN(pin: String) async throws {
        guard isInitialized else {
            throw SecurityError.notInitialized
        }

        // Hash the PIN before storing it
        let pinData = Data(pin.utf8)
        let hashedPin = SHA256.hash(data: pinData)
        let hashedPinString = hashedPin.compactMap { String(format: "%02x", $0) }.joined()

        // Store the hashed PIN
        userDefaults.set(hashedPinString, forKey: pinKey)
    }

    /// Verifies a provided PIN against the stored, hashed PIN.
    /// Requires the service to be initialized and a PIN to be set.
    /// - Parameter pin: The plain text PIN string to verify.
    /// - Returns: `true` if the provided PIN matches the stored PIN, `false` otherwise.
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    ///         `SecurityError.pinNotSet` if no PIN has been stored previously.
    ///         `SecurityError.accountLocked` if the account is locked due to too many failed attempts.
    func verifyPIN(pin: String) async throws -> Bool {
        guard isInitialized else {
            throw SecurityError.notInitialized
        }

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
                invalidateSession()
            }
        }

        return isValid
    }

    /// Encrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the service to be initialized.
    /// - Parameter data: The raw `Data` to encrypt.
    /// - Returns: The encrypted data (combined nonce, ciphertext, and tag).
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    ///         `SecurityError.encryptionFailed` if the AES-GCM sealing process fails.
    ///         CryptoKit errors if sealing fails.
    func encryptData(_ data: Data) async throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return encrypted
    }

    /// Decrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the service to be initialized.
    /// - Parameter data: The encrypted data (combined nonce, ciphertext, and tag) to decrypt.
    /// - Returns: The original raw `Data`.
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    ///         `SecurityError.decryptionFailed` if the AES-GCM opening process fails (e.g., data tampered).
    ///         CryptoKit errors if opening fails.
    func decryptData(_ data: Data) async throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Authenticates the user using biometrics with reason
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
                failedAuthenticationAttempts += 1
                if failedAuthenticationAttempts >= securityPolicy.maxFailedAttempts {
                    isAccountLocked = true
                    invalidateSession()
                }
                throw SecurityError.authenticationFailed
            }
            failedAuthenticationAttempts = 0
        } catch {
            failedAuthenticationAttempts += 1
            if failedAuthenticationAttempts >= securityPolicy.maxFailedAttempts {
                isAccountLocked = true
                invalidateSession()
            }
            throw SecurityError.authenticationFailed
        }
    }

    /// Synchronous encryption for tests
    func encryptData(_ data: Data) throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return encrypted
    }

    /// Synchronous decryption for tests
    func decryptDataSync(_ data: Data) throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return decrypted
        } catch {
            throw SecurityError.decryptionFailed
        }
    }

    /// Starts a secure session
    func startSecureSession() {
        isSessionValid = true
    }

    /// Invalidates the current session
    func invalidateSession() {
        isSessionValid = false
    }

    /// Stores secure data in instance-specific storage
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        // Instance-specific storage for test isolation
        secureDataStorage[key] = data
        return true
    }

    /// Retrieves secure data from instance-specific storage
    func retrieveSecureData(forKey key: String) -> Data? {
        return secureDataStorage[key]
    }

    /// Deletes secure data from instance-specific storage
    func deleteSecureData(forKey key: String) -> Bool {
        secureDataStorage.removeValue(forKey: key)
        return true
    }

    /// Handles security violations
    func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .unauthorizedAccess, .sessionTimeout:
            invalidateSession()
        case .tooManyFailedAttempts:
            isAccountLocked = true
            invalidateSession()
        }
    }

    // MARK: - Error Types
    enum SecurityError: LocalizedError {
        case notInitialized
        case biometricsNotAvailable
        case authenticationFailed
        case encryptionFailed
        case decryptionFailed
        case pinNotSet
        case accountLocked

        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Security service not initialized"
            case .biometricsNotAvailable:
                return "Biometric authentication not available"
            case .authenticationFailed:
                return "Authentication failed"
            case .encryptionFailed:
                return "Failed to encrypt data"
            case .decryptionFailed:
                return "Failed to decrypt data"
            case .pinNotSet:
                return "PIN has not been set"
            case .accountLocked:
                return "Account is locked due to too many failed attempts"
            }
        }
    }
}

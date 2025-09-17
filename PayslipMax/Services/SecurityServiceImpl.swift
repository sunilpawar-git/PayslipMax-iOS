import Foundation
import LocalAuthentication
import CryptoKit

/// Security service implementation providing biometric authentication, PIN management, and data encryption/decryption.
/// This class is designed to run on the main actor and follows the facade pattern by coordinating multiple specialized components.

// Adding @MainActor attribute to ensure this class conforms to the @MainActor protocol
/// Provides implementation for security-related operations like biometric authentication, PIN management, and data encryption/decryption.
/// This class is designed to run on the main actor and acts as a facade coordinating multiple specialized security components.
@MainActor
final class SecurityServiceImpl: SecurityServiceProtocol {
    // MARK: - Component Managers

    /// Manager responsible for biometric authentication operations
    private let biometricManager: BiometricAuthenticationManagerProtocol

    /// Manager responsible for PIN authentication operations
    private var pinManager: PINAuthenticationManagerProtocol

    /// Manager responsible for encryption and decryption operations
    private let encryptionManager: EncryptionManagerProtocol

    /// Manager responsible for session management
    private let sessionManager: SessionManagerProtocol

    /// Manager responsible for secure data storage
    private let secureStorageManager: SecureStorageManagerProtocol

    // MARK: - Computed Properties

    /// Indicates whether biometric authentication (like Face ID or Touch ID) is available on the device.
    var isBiometricAuthAvailable: Bool {
        biometricManager.isBiometricAuthAvailable
    }

    /// Flag indicating whether the security service has been initialized (encryption key generated).
    var isInitialized: Bool {
        encryptionManager.isInitialized
    }

    /// Session validity status
    var isSessionValid: Bool {
        sessionManager.isSessionValid
    }

    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int {
        pinManager.failedAuthenticationAttempts
    }

    /// Account locked status
    var isAccountLocked: Bool {
        pinManager.isAccountLocked
    }

    /// Security policy configuration
    var securityPolicy: SecurityPolicy {
        get { pinManager.securityPolicy }
        set { pinManager.securityPolicy = newValue }
    }

    /// Default initializer that creates all security component managers.
    init() {
        self.biometricManager = BiometricAuthenticationManager()
        self.pinManager = PINAuthenticationManager()
        self.encryptionManager = EncryptionManager()
        self.sessionManager = SessionManager()
        self.secureStorageManager = SecureStorageManager()
    }

    /// Initializes the security service by generating the symmetric encryption key.
    /// Must be called before performing encryption or decryption operations.
    /// Sets the `isInitialized` flag to true upon successful completion.
    /// - Throws: Does not currently throw, but signature allows for future initialization errors.
    func initialize() async throws {
        try await encryptionManager.initialize()
    }

    /// Attempts to authenticate the user using device biometrics (Face ID, Touch ID).
    /// - Returns: `true` if authentication is successful, `false` otherwise.
    /// - Throws: `SecurityError.biometricsNotAvailable` if biometrics are not configured or available.
    ///         `SecurityError.authenticationFailed` if the authentication attempt fails for other reasons.
    func authenticateWithBiometrics() async throws -> Bool {
        try await biometricManager.authenticateWithBiometrics()
    }

    /// Sets up or updates the application PIN. The PIN is hashed using SHA256 before being stored securely.
    /// Requires the service to be initialized first.
    /// - Parameter pin: The plain text PIN string provided by the user.
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    func setupPIN(pin: String) async throws {
        guard isInitialized else {
            throw SecurityError.notInitialized
        }

        try await pinManager.setupPIN(pin: pin)
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

        let result = try await pinManager.verifyPIN(pin: pin)

        // If verification fails and account gets locked, invalidate session
        if pinManager.isAccountLocked {
            sessionManager.invalidateSession()
        }

        return result
    }

    /// Encrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the service to be initialized.
    /// - Parameter data: The raw `Data` to encrypt.
    /// - Returns: The encrypted data (combined nonce, ciphertext, and tag).
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    ///         `SecurityError.encryptionFailed` if the AES-GCM sealing process fails.
    ///         CryptoKit errors if sealing fails.
    func encryptData(_ data: Data) async throws -> Data {
        try await encryptionManager.encryptData(data)
    }

    /// Decrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the service to be initialized.
    /// - Parameter data: The encrypted data (combined nonce, ciphertext, and tag) to decrypt.
    /// - Returns: The original raw `Data`.
    /// - Throws: `SecurityError.notInitialized` if the service is not initialized.
    ///         `SecurityError.decryptionFailed` if the AES-GCM opening process fails (e.g., data tampered).
    ///         CryptoKit errors if opening fails.
    func decryptData(_ data: Data) async throws -> Data {
        try await encryptionManager.decryptData(data)
    }

    /// Authenticates the user using biometrics with reason
    func authenticateWithBiometrics(reason: String) async throws {
        try await biometricManager.authenticateWithBiometrics(reason: reason)

        // Reset failed attempts on successful biometric authentication
        // Note: This logic was moved to the biometric manager
    }

    /// Synchronous encryption for tests
    func encryptData(_ data: Data) throws -> Data {
        try encryptionManager.encryptData(data)
    }

    /// Synchronous decryption for tests
    func decryptDataSync(_ data: Data) throws -> Data {
        try encryptionManager.decryptDataSync(data)
    }

    /// Starts a secure session
    func startSecureSession() {
        sessionManager.startSecureSession()
    }

    /// Invalidates the current session
    func invalidateSession() {
        sessionManager.invalidateSession()
    }

    /// Stores secure data in instance-specific storage
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        secureStorageManager.storeSecureData(data, forKey: key)
    }

    /// Retrieves secure data from instance-specific storage
    func retrieveSecureData(forKey key: String) -> Data? {
        secureStorageManager.retrieveSecureData(forKey: key)
    }

    /// Deletes secure data from instance-specific storage
    func deleteSecureData(forKey key: String) -> Bool {
        secureStorageManager.deleteSecureData(forKey: key)
    }

    /// Handles security violations
    func handleSecurityViolation(_ violation: SecurityViolation) {
        sessionManager.handleSecurityViolation(violation)

        // Handle account locking for too many failed attempts
        if violation == .tooManyFailedAttempts {
            pinManager.lockAccount()
        }
    }

}

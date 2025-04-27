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
    
    /// Indicates whether biometric authentication (like Face ID or Touch ID) is available on the device.
    var isBiometricAuthAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Flag indicating whether the security service has been initialized (encryption key generated).
    var isInitialized: Bool = false
    
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
    func verifyPIN(pin: String) async throws -> Bool {
        guard isInitialized else {
            throw SecurityError.notInitialized
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
        return storedPin == hashedPinString
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
    
    // MARK: - Error Types
    enum SecurityError: LocalizedError {
        case notInitialized
        case biometricsNotAvailable
        case authenticationFailed
        case encryptionFailed
        case decryptionFailed
        case pinNotSet
        
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
            }
        }
    }
} 
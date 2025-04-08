import Foundation
import LocalAuthentication
import CryptoKit

// Adding @MainActor attribute to ensure this class conforms to the @MainActor protocol
@MainActor
final class SecurityServiceImpl: SecurityServiceProtocol {
    private let context = LAContext()
    private var symmetricKey: SymmetricKey?
    private let userDefaults = UserDefaults.standard
    private let pinKey = "app_pin"
    
    var isBiometricAuthAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var isInitialized: Bool = false
    
    init() {}
    
    func initialize() async throws {
        // Generate or retrieve encryption key
        symmetricKey = SymmetricKey(size: .bits256)
        isInitialized = true
    }
    
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
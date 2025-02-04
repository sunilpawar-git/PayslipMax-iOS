import Foundation
import LocalAuthentication
import CryptoKit

final class SecurityServiceImpl: SecurityServiceProtocol {
    private let context = LAContext()
    private var symmetricKey: SymmetricKey?
    
    var isInitialized: Bool = false
    
    init() {}
    
    func initialize() async throws {
        // Generate or retrieve encryption key
        symmetricKey = SymmetricKey(size: .bits256)
        isInitialized = true
    }
    
    func authenticate() async throws -> Bool {
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
    
    func encrypt(_ data: Data) async throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return encrypted
    }
    
    func decrypt(_ data: Data) async throws -> Data {
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
            }
        }
    }
} 
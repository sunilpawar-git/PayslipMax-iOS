import Foundation

/// Security-related error types for the security service
public enum SecurityError: LocalizedError {
    case notInitialized
    case biometricsNotAvailable
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case pinNotSet
    case accountLocked

    public var errorDescription: String? {
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

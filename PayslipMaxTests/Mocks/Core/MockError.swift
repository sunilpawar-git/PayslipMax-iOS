import Foundation

// MARK: - Mock Error Types
enum MockError: LocalizedError, Equatable {
    case initializationFailed
    case encryptionFailed
    case decryptionFailed
    case authenticationFailed
    case saveFailed
    case fetchFailed
    case deleteFailed
    case clearAllDataFailed
    case unlockFailed
    case setupPINFailed
    case verifyPINFailed
    case clearFailed
    case processingFailed
    case incorrectPassword
    case extractionFailed
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed: return "Initialization failed"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed"
        case .authenticationFailed: return "Authentication failed"
        case .saveFailed: return "Save failed"
        case .fetchFailed: return "Fetch failed"
        case .deleteFailed: return "Delete failed"
        case .clearAllDataFailed: return "Clear all data failed"
        case .unlockFailed: return "Unlock failed"
        case .setupPINFailed: return "Setup PIN failed"
        case .verifyPINFailed: return "Verify PIN failed"
        case .clearFailed: return "Clear failed"
        case .processingFailed: return "Processing failed"
        case .incorrectPassword: return "Incorrect password"
        case .extractionFailed: return "Extraction failed"
        }
    }
} 
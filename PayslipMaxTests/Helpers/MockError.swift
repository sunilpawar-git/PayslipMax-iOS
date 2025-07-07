import Foundation

/// Mock error types used across all mock services for testing purposes.
/// 
/// This enum provides standardized error cases that mock services can use to simulate
/// various failure scenarios during testing. Each error case represents a common
/// failure point in the PayslipMax application.
///
/// - Note: This is exclusively for testing and should never be used in production code.
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
    
    /// Localized error descriptions for each mock error case.
    var errorDescription: String? {
        switch self {
        case .initializationFailed: return "Mock initialization failed"
        case .encryptionFailed: return "Mock encryption failed"
        case .decryptionFailed: return "Mock decryption failed"
        case .authenticationFailed: return "Mock authentication failed"
        case .saveFailed: return "Mock save operation failed"
        case .fetchFailed: return "Mock fetch operation failed"
        case .deleteFailed: return "Mock delete operation failed"
        case .clearAllDataFailed: return "Mock clear all data operation failed"
        case .unlockFailed: return "Mock unlock operation failed"
        case .setupPINFailed: return "Mock PIN setup failed"
        case .verifyPINFailed: return "Mock PIN verification failed"
        case .clearFailed: return "Mock clear operation failed"
        case .processingFailed: return "Mock processing operation failed"
        case .incorrectPassword: return "Mock incorrect password error"
        case .extractionFailed: return "Mock extraction operation failed"
        }
    }
}
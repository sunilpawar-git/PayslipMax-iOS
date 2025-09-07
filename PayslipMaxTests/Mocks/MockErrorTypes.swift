import Foundation

/// Mock error types for testing various failure scenarios
/// Implements Error and LocalizedError protocols for comprehensive error testing
/// Follows SOLID principles with single responsibility for error type definitions
public enum MockError: Error, LocalizedError {
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case processingFailed
    case extractionFailed
    case initializationFailed
    case saveFailed
    case fetchFailed
    case deleteFailed
    case clearAllDataFailed
    case unlockFailed
    case setupPINFailed
    case verifyPINFailed
    case clearFailed
    case incorrectPassword

    public var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "Mock authentication failed"
        case .encryptionFailed: return "Mock encryption failed"
        case .decryptionFailed: return "Mock decryption failed"
        case .processingFailed: return "Mock processing failed"
        case .extractionFailed: return "Mock extraction failed"
        case .initializationFailed: return "Mock initialization failed"
        case .saveFailed: return "Mock save failed"
        case .fetchFailed: return "Mock fetch failed"
        case .deleteFailed: return "Mock delete failed"
        case .clearAllDataFailed: return "Mock clear all data failed"
        case .unlockFailed: return "Mock unlock failed"
        case .setupPINFailed: return "Mock setup PIN failed"
        case .verifyPINFailed: return "Mock verify PIN failed"
        case .clearFailed: return "Mock clear failed"
        case .incorrectPassword: return "Mock incorrect password"
        }
    }
}

// MARK: - Supporting Types Documentation
/*
Note: The following types are referenced in mock implementations but defined elsewhere:

1. ValidationResult - Defined in TestDataValidator.swift
   Used by: MockPayslipValidationService (currently commented out)

2. SecurityViolation - Defined in Security frameworks
   Used by: MockSecurityService.handleSecurityViolation()

3. SecurityPolicy - Defined in Security frameworks
   Used by: MockSecurityService.securityPolicy property

These types are intentionally not duplicated here to maintain single source of truth
and avoid circular dependencies. They should be imported from their respective modules.
*/

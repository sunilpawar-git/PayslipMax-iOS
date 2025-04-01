import Foundation
@testable import Payslip_Max

// Define a MockError in the test target to fix the linker error
enum MockError: Error, Equatable {
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
    
    // Errors specific to MockPDFService
    case processingFailed
    case incorrectPassword
    case extractionFailed
} 
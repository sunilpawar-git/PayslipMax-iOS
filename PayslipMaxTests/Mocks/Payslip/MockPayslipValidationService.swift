import Foundation
import PDFKit
@testable import Payslip_Max

/// Mock implementation of PayslipValidationServiceProtocol for testing
class MockPayslipValidationService: PayslipValidationServiceProtocol {
    // MARK: - Properties
    
    var validateStructureCallCount = 0
    var validateContentCallCount = 0
    var isPasswordProtectedCallCount = 0
    var structureIsValid = true
    var contentIsValid = true
    var contentConfidence = 0.8
    var isPasswordProtected = false
    var lastValidatedData: Data?
    var lastValidatedText: String?
    
    // MARK: - Initialization
    
    init(structureIsValid: Bool = true, contentIsValid: Bool = true, isPasswordProtected: Bool = false) {
        self.structureIsValid = structureIsValid
        self.contentIsValid = contentIsValid
        self.isPasswordProtected = isPasswordProtected
    }
    
    // MARK: - Methods
    
    func reset() {
        validateStructureCallCount = 0
        validateContentCallCount = 0
        isPasswordProtectedCallCount = 0
        lastValidatedData = nil
        lastValidatedText = nil
    }
    
    func validatePDFStructure(_ data: Data) -> Bool {
        validateStructureCallCount += 1
        lastValidatedData = data
        return structureIsValid
    }
    
    func validatePayslipContent(_ text: String) -> ValidationResult {
        validateContentCallCount += 1
        lastValidatedText = text
        
        return ValidationResult(
            isValid: contentIsValid,
            confidence: contentConfidence,
            detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
            missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
        )
    }
    
    func isPDFPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        lastValidatedData = data
        return isPasswordProtected
    }
} 
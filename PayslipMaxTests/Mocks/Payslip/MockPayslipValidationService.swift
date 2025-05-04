import Foundation
import PDFKit
@testable import PayslipMax

/// Mock implementation of PayslipValidationServiceProtocol for testing
class MockPayslipValidationService: PayslipValidationServiceProtocol {
    // MARK: - Properties
    
    var validateStructureCallCount = 0
    var validateContentCallCount = 0
    var isPasswordProtectedCallCount = 0
    var validatePayslipCallCount = 0
    var deepValidatePayslipCallCount = 0
    var structureIsValid = true
    var contentIsValid = true
    var contentConfidence = 0.8
    var isPasswordProtected = false
    var payslipIsValid = true
    var lastValidatedData: Data?
    var lastValidatedText: String?
    var lastValidatedPayslip: (any PayslipProtocol)?
    
    // MARK: - Initialization
    
    init(structureIsValid: Bool = true, contentIsValid: Bool = true, isPasswordProtected: Bool = false, payslipIsValid: Bool = true) {
        self.structureIsValid = structureIsValid
        self.contentIsValid = contentIsValid
        self.isPasswordProtected = isPasswordProtected
        self.payslipIsValid = payslipIsValid
    }
    
    // MARK: - Methods
    
    func reset() {
        validateStructureCallCount = 0
        validateContentCallCount = 0
        isPasswordProtectedCallCount = 0
        validatePayslipCallCount = 0
        deepValidatePayslipCallCount = 0
        lastValidatedData = nil
        lastValidatedText = nil
        lastValidatedPayslip = nil
    }
    
    func validatePDFStructure(_ data: Data) -> Bool {
        validateStructureCallCount += 1
        lastValidatedData = data
        return structureIsValid
    }
    
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        validateContentCallCount += 1
        lastValidatedText = text
        
        return PayslipContentValidationResult(
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
    
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        validatePayslipCallCount += 1
        lastValidatedPayslip = payslip
        
        return BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
    }
    
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        deepValidatePayslipCallCount += 1
        lastValidatedPayslip = payslip
        
        let basicValidation = BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
        
        var pdfValidationSuccess = false
        var pdfValidationMessage = "No PDF data available"
        var contentValidation: PayslipContentValidationResult? = nil
        
        if let pdfData = payslip.pdfData {
            pdfValidationSuccess = structureIsValid
            pdfValidationMessage = structureIsValid ? "PDF structure is valid" : "PDF structure is invalid"
            
            if structureIsValid {
                contentValidation = PayslipContentValidationResult(
                    isValid: contentIsValid,
                    confidence: contentConfidence,
                    detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
                    missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
                )
            }
        }
        
        return PayslipDeepValidationResult(
            basicValidation: basicValidation,
            pdfValidationSuccess: pdfValidationSuccess,
            pdfValidationMessage: pdfValidationMessage,
            contentValidation: contentValidation
        )
    }
} 
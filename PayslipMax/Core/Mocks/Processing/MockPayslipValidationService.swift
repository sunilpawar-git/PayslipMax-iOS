import Foundation

/// Mock implementation of PayslipValidationServiceProtocol for testing purposes.
///
/// This mock service provides controllable validation behavior for testing
/// various validation scenarios including structure validation, content validation,
/// and deep validation with configurable success/failure modes.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPayslipValidationService: PayslipValidationServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether structure validation succeeds
    var structureIsValid = true
    
    /// Controls whether content validation succeeds
    var contentIsValid = true
    
    /// The confidence level to return for content validation
    var contentConfidence = 0.8
    
    /// Controls whether PDFs are considered password protected
    var isPasswordProtected = false
    
    /// Controls whether payslip validation succeeds
    var payslipIsValid = true
    
    // MARK: - Initialization
    
    /// Creates a mock validation service with configurable behavior.
    /// - Parameters:
    ///   - structureIsValid: Whether structure validation should succeed
    ///   - contentIsValid: Whether content validation should succeed
    ///   - isPasswordProtected: Whether PDFs should be considered password protected
    ///   - payslipIsValid: Whether payslip validation should succeed
    init(structureIsValid: Bool = true, contentIsValid: Bool = true, isPasswordProtected: Bool = false, payslipIsValid: Bool = true) {
        self.structureIsValid = structureIsValid
        self.contentIsValid = contentIsValid
        self.isPasswordProtected = isPasswordProtected
        self.payslipIsValid = payslipIsValid
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        structureIsValid = true
        contentIsValid = true
        contentConfidence = 0.8
        isPasswordProtected = false
        payslipIsValid = true
    }
    
    // MARK: - PayslipValidationServiceProtocol Implementation
    
    func validatePDFStructure(_ data: Data) -> Bool {
        return structureIsValid
    }
    
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        return PayslipContentValidationResult(
            isValid: contentIsValid,
            confidence: contentConfidence,
            detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
            missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
        )
    }
    
    func isPDFPasswordProtected(_ data: Data) -> Bool {
        return isPasswordProtected
    }
    
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        return BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
    }
    
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        let basicValidation = BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
        
        var pdfValidationSuccess = false
        var pdfValidationMessage = "No PDF data available"
        var contentValidation: PayslipContentValidationResult? = nil
        
        if payslip.pdfData != nil {
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
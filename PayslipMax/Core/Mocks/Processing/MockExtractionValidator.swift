import Foundation

/// Mock implementation of ExtractionValidatorProtocol for testing purposes.
class MockExtractionValidator: SimpleExtractionValidatorProtocol {
    
    /// Controls whether essential data validation should succeed
    var shouldPassEssentialDataValidation: Bool = true
    
    /// Controls whether PayslipItem validation should succeed
    var shouldPassPayslipValidation: Bool = true
    
    /// The error to throw when essential data validation fails
    var essentialDataError: Error = ModularExtractionError.insufficientData
    
    /// Tracks the last data passed to validateEssentialData
    var lastValidatedData: [String: String] = [:]
    
    /// Tracks the last PayslipItem passed to validatePayslipItem
    var lastValidatedPayslip: PayslipItem?
    
    /// Number of times validateEssentialData was called
    var essentialDataValidationCallCount = 0
    
    /// Number of times validatePayslipItem was called
    var payslipValidationCallCount = 0
    
    /// Validates that essential data fields are present and valid.
    /// - Parameter data: Dictionary of extracted data to validate
    /// - Throws: ModularExtractionError if shouldPassEssentialDataValidation is false
    func validateEssentialData(_ data: [String: String]) throws {
        essentialDataValidationCallCount += 1
        lastValidatedData = data
        
        guard shouldPassEssentialDataValidation else {
            throw essentialDataError
        }
    }
    
    /// Validates a PayslipItem for completeness and data integrity.
    /// - Parameter payslip: The PayslipItem to validate
    /// - Returns: Value of shouldPassPayslipValidation
    func validatePayslipItem(_ payslip: PayslipItem) -> Bool {
        payslipValidationCallCount += 1
        lastValidatedPayslip = payslip
        
        return shouldPassPayslipValidation
    }
    
    /// Resets the mock to its initial state
    func reset() {
        shouldPassEssentialDataValidation = true
        shouldPassPayslipValidation = true
        essentialDataError = ModularExtractionError.insufficientData
        lastValidatedData = [:]
        lastValidatedPayslip = nil
        essentialDataValidationCallCount = 0
        payslipValidationCallCount = 0
    }
}
import Foundation
import PDFKit

/// Protocol for payslip validation service
protocol PayslipValidationServiceProtocol {
    /// Validates basic PDF structure
    /// - Parameter data: The PDF data to validate
    /// - Returns: A result indicating if the PDF is structurally valid
    func validatePDFStructure(_ data: Data) -> Bool
    
    /// Validates that the text content contains a valid payslip
    /// - Parameter text: The text content to validate
    /// - Returns: A validation result with confidence score and detected fields
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult
    
    /// Checks if a PDF document is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: True if the PDF is password protected, false otherwise
    func isPDFPasswordProtected(_ data: Data) -> Bool
    
    /// Validates a payslip object for required fields and data consistency
    /// - Parameter payslip: The payslip to validate
    /// - Returns: A validation result with any errors found
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult
    
    /// Performs a deep validation of payslip data including PDF content validation
    /// - Parameter payslip: The payslip to validate
    /// - Returns: A comprehensive validation result
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult
}

/// Validation result for payslip content
struct PayslipContentValidationResult {
    let isValid: Bool
    let confidence: Double
    let detectedFields: [String]
    let missingRequiredFields: [String]
} 
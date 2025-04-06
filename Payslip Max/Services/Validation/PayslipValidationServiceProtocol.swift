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
    func validatePayslipContent(_ text: String) -> ValidationResult
    
    /// Checks if a PDF document is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: True if the PDF is password protected, false otherwise
    func isPDFPasswordProtected(_ data: Data) -> Bool
} 
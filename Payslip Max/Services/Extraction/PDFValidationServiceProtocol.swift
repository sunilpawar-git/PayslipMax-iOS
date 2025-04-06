import Foundation
import PDFKit

/// Protocol for validating PDF documents
protocol PDFValidationServiceProtocol {
    /// Validates a PDF document
    /// - Parameter pdfDocument: The PDF document to validate
    /// - Throws: An error if the PDF is invalid
    func validatePDF(_ pdfDocument: PDFDocument) throws
    
    /// Checks if a PDF document contains a valid payslip
    /// - Parameter pdfDocument: The PDF document to check
    /// - Returns: A validation result with confidence score
    func validatePayslipContent(_ pdfDocument: PDFDocument) -> PayslipValidationResult
} 
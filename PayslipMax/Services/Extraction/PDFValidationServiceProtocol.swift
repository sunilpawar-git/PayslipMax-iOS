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
    
    /// Checks if the provided data is a valid PDF
    /// - Parameter data: The PDF data to validate
    /// - Returns: True if the data represents a valid PDF
    func isPDFValid(data: Data) -> Bool
    
    /// Check if this is a military PDF format
    /// - Parameter data: The PDF data to check
    /// - Returns: True if the data appears to be a military PDF
    func checkForMilitaryPDFFormat(_ data: Data) -> Bool
} 
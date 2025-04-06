import Foundation
import PDFKit

/// Service for validating PDF documents
class PDFValidationService: PDFValidationServiceProtocol {
    // MARK: - Public Methods
    
    /// Validates a PDF document
    /// - Parameter pdfDocument: The PDF document to validate
    /// - Throws: An error if the PDF is invalid
    func validatePDF(_ pdfDocument: PDFDocument) throws {
        // Check if PDF has pages
        guard pdfDocument.pageCount > 0 else {
            print("PDFValidationService: PDF has no pages")
            throw AppError.pdfExtractionFailed("PDF has no pages")
        }
        
        // Check if the PDF is locked/encrypted
        if pdfDocument.isLocked {
            print("PDFValidationService: PDF is locked")
            throw AppError.pdfExtractionFailed("PDF is password protected")
        }
        
        // Validate PDF structure
        if !hasMeaningfulContent(pdfDocument) {
            print("PDFValidationService: PDF has no meaningful content")
            throw AppError.pdfExtractionFailed("PDF has no meaningful content")
        }
    }
    
    /// Checks if a PDF document contains a valid payslip
    /// - Parameter pdfDocument: The PDF document to check
    /// - Returns: A validation result with confidence score
    func validatePayslipContent(_ pdfDocument: PDFDocument) -> PayslipValidationResult {
        let fullText = pdfDocument.string ?? ""
        
        // Check for key payslip indicators
        let hasNameIndicator = fullText.contains("Name:") || fullText.contains("SERVICE NO & NAME") || fullText.contains("ARMY NO AND NAME")
        let hasFinancialIndicator = fullText.contains("Pay") || fullText.contains("Salary") || fullText.contains("EARNINGS") || fullText.contains("CREDIT")
        let hasDeductionIndicator = fullText.contains("Deduction") || fullText.contains("DEDUCTION") || fullText.contains("Tax") || fullText.contains("DEBITS")
        
        // Calculate confidence score (simple version)
        var confidenceScore = 0.0
        if hasNameIndicator { confidenceScore += 0.3 }
        if hasFinancialIndicator { confidenceScore += 0.4 }
        if hasDeductionIndicator { confidenceScore += 0.3 }
        
        // Create validation result
        let result = PayslipValidationResult(
            isValid: confidenceScore >= 0.5,
            confidenceScore: confidenceScore,
            message: confidenceScore >= 0.5 ? "Valid payslip detected" : "Document may not be a payslip"
        )
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Checks if the PDF has meaningful content
    /// - Parameter pdfDocument: The PDF document to check
    /// - Returns: True if the document has meaningful content
    private func hasMeaningfulContent(_ pdfDocument: PDFDocument) -> Bool {
        // Check if there's any text content
        if let fullText = pdfDocument.string, !fullText.isEmpty {
            // Check if the text has a minimum length (arbitrary threshold)
            return fullText.count >= 50
        }
        
        // If no text, check if there are images or other content
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), !page.annotations.isEmpty {
                return true
            }
        }
        
        // No meaningful content found
        return false
    }
}

/// Represents the result of a validation check
struct PayslipValidationResult {
    /// Whether the document is valid
    let isValid: Bool
    
    /// Confidence score (0.0-1.0)
    let confidenceScore: Double
    
    /// Optional message describing the validation result
    let message: String
} 
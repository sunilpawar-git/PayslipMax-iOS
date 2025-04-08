import Foundation
import PDFKit

/// Service for validating PDF documents
class PDFValidationService: PDFValidationServiceProtocol {
    // MARK: - Singleton Instance
    static let shared = PDFValidationService()
    
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
    
    /// Checks if the provided data is a valid PDF
    func isPDFValid(data: Data) -> Bool {
        // Quick check for PDF header
        let pdfHeaderCheck = data.prefix(5).map { UInt8($0) }
        let validHeader: [UInt8] = [37, 80, 68, 70, 45] // %PDF-
        
        if pdfHeaderCheck != validHeader {
            Logger.warning("Invalid PDF header", category: "PDFValidation")
            return false
        }
        
        // Try creating a PDFDocument
        if let document = PDFDocument(data: data), document.pageCount > 0 {
            Logger.info("Valid PDF with \(document.pageCount) pages", category: "PDFValidation")
            
            // Check if the document has any text content to ensure it's not corrupt
            let firstPageText = document.page(at: 0)?.string ?? ""
            
            // If the document has suspicious encoded characters, treat as invalid
            for pattern in PDFValidationConfig.suspiciousPatterns {
                if firstPageText.contains(pattern) {
                    Logger.warning("PDF contains suspicious encoded content: \(pattern)", category: "PDFValidation")
                    return false
                }
            }
            
            // Check if there's any readable text
            if !firstPageText.isEmpty && firstPageText.count > 20 {
                // Count readable characters (alphanumeric, punctuation, spaces)
                let readableCharCount = firstPageText.filter { $0.isLetter || $0.isNumber || $0.isPunctuation || $0.isWhitespace }.count
                let readableRatio = Double(readableCharCount) / Double(firstPageText.count)
                
                // Check if the ratio meets the minimum threshold
                if readableRatio < PDFValidationConfig.minimumReadableRatio {
                    Logger.warning("PDF has low readable text ratio (\(readableRatio)), likely corrupted", category: "PDFValidation")
                    return false
                }
            }
            
            return true
        }
        
        Logger.warning("Could not create PDF document from data", category: "PDFValidation")
        return false
    }
    
    /// Check if this is a military PDF format
    func checkForMilitaryPDFFormat(_ data: Data) -> Bool {
        // Check for common military PDF identifiers
        guard let dataString = String(data: data.prefix(10000), encoding: .ascii) ?? 
                               String(data: data.prefix(10000), encoding: .utf8) else {
            return false
        }
        
        // Military-specific keywords
        let militaryKeywords = [
            "MILITARY PAY", "DFAS", "Defense Finance", "Army", "Navy", "Marines", "Air Force",
            "LES", "Leave and Earnings", "MyPay", "Armed Forces", "Basic Pay", "COLA", "BAH", "BAS",
            "Department of Defense", "DoD", "Service Member", "Military Department"
        ]
        
        for keyword in militaryKeywords {
            if dataString.contains(keyword) {
                return true
            }
        }
        
        // Check for PDF security features often found in military PDFs
        if dataString.contains("/Encrypt") {
            return true
        }
        
        return false
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
    
    // MARK: - Private Constants
    
    /// Configuration for PDF validation
    private struct PDFValidationConfig {
        /// Patterns that indicate corrupted or specially encoded military PDFs
        static let suspiciousPatterns = [
            "MILPDF:", "jZUdqY", "BaXSGIz", "cmCV3wK", "MG/9Qxz", "k8eUKJd"
        ]
        
        /// Minimum ratio of readable text to total text to consider a PDF valid
        /// Lower values allow more encoded content, higher values require more readable text
        static let minimumReadableRatio: Double = 0.6
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
import Foundation
import PDFKit

/// Service for validating payslip PDFs
class PayslipValidationService: PayslipValidationServiceProtocol {
    
    // MARK: - Dependencies
    
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the validation service with dependencies
    /// - Parameter textExtractionService: Service for extracting text from PDFs
    init(textExtractionService: PDFTextExtractionServiceProtocol) {
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - Public Methods
    
    /// Validates basic PDF structure
    /// - Parameter data: The PDF data to validate
    /// - Returns: A result indicating if the PDF is structurally valid
    func validatePDFStructure(_ data: Data) -> Bool {
        print("[PayslipValidationService] Validating PDF structure")
        
        // Check for empty data
        guard !data.isEmpty else {
            print("[PayslipValidationService] PDF data is empty")
            return false
        }
        
        // Check for minimal valid PDF structure using string check
        let pdfString = String(data: data, encoding: .utf8) ?? ""
        let hasPDFHeader = pdfString.contains("%PDF-")
        let hasPDFFooter = pdfString.contains("%%EOF")
        
        guard hasPDFHeader && hasPDFFooter else {
            print("[PayslipValidationService] Invalid PDF structure (missing header or footer)")
            return false
        }
        
        // Create a PDF document to verify it can be parsed
        guard let document = PDFDocument(data: data) else {
            print("[PayslipValidationService] Failed to create PDF document from data")
            return false
        }
        
        // Check if document has pages
        guard document.pageCount > 0 else {
            print("[PayslipValidationService] PDF has no pages")
            return false
        }
        
        return true
    }
    
    /// Validates that the text content contains a valid payslip
    /// - Parameter text: The text content to validate
    /// - Returns: A validation result with confidence score and detected fields
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        print("[PayslipValidationService] Validating payslip content from \(text.count) characters")
        
        // Define required fields
        let requiredFields = ["name", "month", "year", "earnings", "deductions"]
        
        // Check for key payslip indicators
        var detectedFields: [String] = []
        var missingFields: [String] = []
        
        // Check for name field
        if text.range(of: "Name:", options: .caseInsensitive) != nil {
            detectedFields.append("name")
        } else {
            missingFields.append("name")
        }
        
        // Check for month/date field
        if text.range(of: "Month:|Date:|Period:", options: .regularExpression) != nil {
            detectedFields.append("month")
        } else {
            missingFields.append("month")
        }
        
        // Check for year field
        if text.range(of: "Year:|20[0-9]{2}", options: .regularExpression) != nil {
            detectedFields.append("year")
        } else {
            missingFields.append("year")
        }
        
        // Check for earnings indicators
        let earningsTerms = ["Earnings", "Credits", "Salary", "Pay", "Income", "Allowances"]
        for term in earningsTerms {
            if text.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("earnings")
                break
            }
        }
        if !detectedFields.contains("earnings") {
            missingFields.append("earnings")
        }
        
        // Check for deductions indicators
        let deductionsTerms = ["Deductions", "Debits", "Tax", "DSOP", "Fund", "Recovery"]
        for term in deductionsTerms {
            if text.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("deductions")
                break
            }
        }
        if !detectedFields.contains("deductions") {
            missingFields.append("deductions")
        }
        
        // Calculate confidence score based on detected fields
        let confidence = Double(detectedFields.count) / Double(requiredFields.count)
        
        // Document is valid if it has at least 3 required fields
        let isValid = detectedFields.count >= 3
        
        print("[PayslipValidationService] Payslip validation - valid: \(isValid), confidence: \(confidence)")
        
        return PayslipContentValidationResult(
            isValid: isValid,
            confidence: confidence,
            detectedFields: detectedFields,
            missingRequiredFields: missingFields
        )
    }
    
    /// Checks if a PDF document is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: True if the PDF is password protected, false otherwise
    func isPDFPasswordProtected(_ data: Data) -> Bool {
        guard let document = PDFDocument(data: data) else {
            return false
        }
        let isLocked = document.isLocked
        print("[PayslipValidationService] Is password protected: \(isLocked)")
        return isLocked
    }
    
    /// Validates a payslip object for required fields and data consistency
    /// - Parameter payslip: The payslip to validate
    /// - Returns: A validation result with any errors found
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        var errors: [PayslipValidationError] = []
        
        // Check basic fields
        if payslip.month.isEmpty {
            errors.append(.missingRequiredField("month"))
        }
        
        if payslip.year <= 0 {
            errors.append(.invalidValue("year", "Year must be a positive number"))
        }
        
        // Check financial data
        if payslip.credits < 0 {
            errors.append(.invalidValue("credits", "Credits should not be negative"))
        }
        
        if payslip.debits < 0 {
            errors.append(.invalidValue("debits", "Debits should not be negative"))
        }
        
        // Check sensitive data fields if not encrypted
        if !payslip.isNameEncrypted && payslip.name.isEmpty {
            errors.append(.missingRequiredField("name"))
        }
        
        if !payslip.isAccountNumberEncrypted && payslip.accountNumber.isEmpty {
            errors.append(.missingRequiredField("accountNumber"))
        }
        
        // More comprehensive validation could be added here
        
        return BasicPayslipValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    /// Performs a deep validation of payslip data including PDF content validation
    /// - Parameter payslip: The payslip to validate
    /// - Returns: A comprehensive validation result
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        // First perform basic validation
        let basicResult = validatePayslip(payslip)
        
        // Check PDF data if available
        var pdfValidationSuccess = false
        var pdfValidationMessage = "No PDF data available"
        var contentValidation: PayslipContentValidationResult? = nil
        
        if let pdfData = payslip.pdfData {
            if validatePDFStructure(pdfData) {
                pdfValidationSuccess = true
                pdfValidationMessage = "PDF structure is valid"
                
                // Extract and validate content
                if let document = PDFDocument(data: pdfData),
                   let extractedText = textExtractionService.extractText(from: document, callback: nil) {
                    contentValidation = validatePayslipContent(extractedText)
                }
            } else {
                pdfValidationMessage = "PDF structure is invalid"
            }
        }
        
        return PayslipDeepValidationResult(
            basicValidation: basicResult,
            pdfValidationSuccess: pdfValidationSuccess,
            pdfValidationMessage: pdfValidationMessage,
            contentValidation: contentValidation
        )
    }
}

// MARK: - Validation Result Models

/// Represents errors that can occur during payslip validation
enum PayslipValidationError: Error, Equatable {
    case missingRequiredField(String)
    case invalidValue(String, String)
    case inconsistentData(String)
}

/// Result of validating a payslip
struct BasicPayslipValidationResult {
    let isValid: Bool
    let errors: [PayslipValidationError]
}

/// Result of deep validation including PDF content analysis
struct PayslipDeepValidationResult {
    let basicValidation: BasicPayslipValidationResult
    let pdfValidationSuccess: Bool
    let pdfValidationMessage: String
    let contentValidation: PayslipContentValidationResult?
    
    var isFullyValid: Bool {
        return basicValidation.isValid && pdfValidationSuccess && (contentValidation?.isValid ?? false)
    }
} 
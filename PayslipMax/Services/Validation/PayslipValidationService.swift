import Foundation
import PDFKit

/// Service responsible for validating payslip data at various stages.
///
/// This includes validating the basic structure of PDF files, checking PDF content
/// for payslip-specific keywords, verifying the integrity of extracted `Payslip` data,
/// and performing deep validation combining multiple checks.
class PayslipValidationService: PayslipValidationServiceProtocol {
    
    // MARK: - Dependencies
    
    /// Service used for extracting text content from PDF documents during content validation.
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
        
        // Relaxed validation: If we have a valid PDFDocument with pages, consider it valid
        // This is more accommodating for military PDFs that might not have standard PDF markers
        return true
    }
    
    /// Validates that the text content contains a valid payslip
    /// - Parameter text: The text content to validate
    /// - Returns: A validation result with confidence score and detected fields
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        print("[PayslipValidationService] Validating payslip content from \(text.count) characters")
        print("[PayslipValidationService] DEBUG - First 200 characters: \(String(text.prefix(200)))")
        
        // Define required fields
        let requiredFields = ["name", "month", "year", "earnings", "deductions"]
        
        // Check for key payslip indicators
        var detectedFields: [String] = []
        var missingFields: [String] = []
        
        // Check for name field - Enhanced for military and civilian payslips
        let namePatterns = [
            "Name:", "NAME:", "ARMY NO AND NAME", "SERVICE NO & NAME", 
            "Employee Name", "Name of Employee", "EMPLOYEE", "SERVICE NO"
        ]
        var nameFound = false
        for pattern in namePatterns {
            if text.range(of: pattern, options: .caseInsensitive) != nil {
                detectedFields.append("name")
                nameFound = true
                print("[PayslipValidationService] ✅ Name field detected with pattern: \(pattern)")
                break
            }
        }
        if !nameFound {
            missingFields.append("name")
            print("[PayslipValidationService] ❌ Name field not found")
        }
        
        // Check for month/date field - Enhanced for military date formats
        let monthPatterns = [
            "Month:", "Date:", "Period:", "PAY PERIOD", "FOR THE MONTH", 
            "Mar\\s+20[0-9]{2}", "Feb\\s+20[0-9]{2}", "Jan\\s+20[0-9]{2}",
            "Apr\\s+20[0-9]{2}", "May\\s+20[0-9]{2}", "Jun\\s+20[0-9]{2}",
            "Jul\\s+20[0-9]{2}", "Aug\\s+20[0-9]{2}", "Sep\\s+20[0-9]{2}",
            "Oct\\s+20[0-9]{2}", "Nov\\s+20[0-9]{2}", "Dec\\s+20[0-9]{2}"
        ]
        var monthFound = false
        for pattern in monthPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                detectedFields.append("month")
                monthFound = true
                print("[PayslipValidationService] ✅ Month field detected with pattern: \(pattern)")
                break
            }
        }
        if !monthFound {
            missingFields.append("month")
            print("[PayslipValidationService] ❌ Month field not found")
        }
        
        // Check for year field - Enhanced patterns
        let yearPatterns = ["Year:", "20[0-9]{2}", "202[0-9]"]
        var yearFound = false
        for pattern in yearPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                detectedFields.append("year")
                yearFound = true
                print("[PayslipValidationService] ✅ Year field detected with pattern: \(pattern)")
                break
            }
        }
        if !yearFound {
            missingFields.append("year")
            print("[PayslipValidationService] ❌ Year field not found")
        }
        
        // Check for earnings indicators - Enhanced for military payslips
        let earningsTerms = [
            "Earnings", "Credits", "Salary", "Pay", "Income", "Allowances",
            "CREDIT", "BASIC PAY", "DA", "SPECIAL PAY", "TRANSPORT ALLOWANCE",
            "KIT MAINTENANCE", "WASHING", "COMPENSATORY", "FIELD AREA",
            "Total Credits", "GROSS PAY"
        ]
        var earningsFound = false
        for term in earningsTerms {
            if text.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("earnings")
                earningsFound = true
                print("[PayslipValidationService] ✅ Earnings field detected with term: \(term)")
                break
            }
        }
        if !earningsFound {
            missingFields.append("earnings")
            print("[PayslipValidationService] ❌ Earnings field not found")
        }
        
        // Check for deductions indicators - Enhanced for military payslips
        let deductionsTerms = [
            "Deductions", "Debits", "Tax", "DSOP", "Fund", "Recovery",
            "DEBIT", "INCOME TAX", "PROFESSIONAL TAX", "DSOP FUND",
            "BENEVOLENT FUND", "Total Debits", "TOTAL DEDUCTIONS",
            "CGHS", "CSD", "CANTEEN", "NPS"
        ]
        var deductionsFound = false
        for term in deductionsTerms {
            if text.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("deductions")
                deductionsFound = true
                print("[PayslipValidationService] ✅ Deductions field detected with term: \(term)")
                break
            }
        }
        if !deductionsFound {
            missingFields.append("deductions")
            print("[PayslipValidationService] ❌ Deductions field not found")
        }
        
        // Calculate confidence score based on detected fields
        let confidence = Double(detectedFields.count) / Double(requiredFields.count)
        
        // Document is valid if it has at least 2 required fields (lowered threshold for military payslips)
        let isValid = detectedFields.count >= 2
        
        print("[PayslipValidationService] Detected fields: \(detectedFields)")
        print("[PayslipValidationService] Missing fields: \(missingFields)")
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

/// Represents specific errors that can occur during payslip data validation.
enum PayslipValidationError: Error, Equatable {
    /// Indicates a required field is missing from the payslip data.
    /// - Parameter String: The name of the missing field.
    case missingRequiredField(String)
    
    /// Indicates a field contains an invalid or unexpected value.
    /// - Parameter String: The name of the field with the invalid value.
    /// - Parameter String: A description of why the value is invalid.
    case invalidValue(String, String)
    
    /// Indicates an inconsistency detected between different pieces of data within the payslip.
    /// - Parameter String: A description of the inconsistency.
    case inconsistentData(String)
}

/// Represents the result of basic validation performed on a `Payslip` object's data fields.
struct BasicPayslipValidationResult {
    /// `true` if the payslip passed all basic validation checks, `false` otherwise.
    let isValid: Bool
    /// An array of `PayslipValidationError` detailing any issues found during validation. Empty if `isValid` is `true`.
    let errors: [PayslipValidationError]
}

/// Represents the comprehensive result of a deep validation, combining basic data validation and PDF content checks.
struct PayslipDeepValidationResult {
    /// The result of basic field validation performed on the payslip data.
    let basicValidation: BasicPayslipValidationResult
    /// `true` if the associated PDF data was successfully validated for structure, `false` otherwise.
    let pdfValidationSuccess: Bool
    /// A message indicating the outcome of the PDF structure validation (e.g., "PDF structure is valid", "No PDF data available").
    let pdfValidationMessage: String
    /// The result of content validation performed on the text extracted from the PDF, if applicable. `nil` if PDF data was missing or invalid.
    let contentValidation: PayslipContentValidationResult?
    
    /// A computed property indicating if the payslip passed all validation stages (basic data, PDF structure, and content).
    var isFullyValid: Bool {
        return basicValidation.isValid && pdfValidationSuccess && (contentValidation?.isValid ?? false)
    }
} 
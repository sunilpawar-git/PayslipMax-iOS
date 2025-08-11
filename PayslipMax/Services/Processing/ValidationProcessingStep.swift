import Foundation
import PDFKit

/// A concrete processing step for PDF validation.
///
/// This processing step serves as the initial gatekeeping stage in the payslip processing pipeline,
/// responsible for ensuring that input PDF data is valid, properly structured, and accessible.
/// It performs several important validation checks:
///
/// 1. Verifies that the data represents a valid PDF structure
/// 2. Checks if the PDF is password-protected, which would prevent further processing
///
/// By validating documents early in the pipeline, this step prevents downstream errors
/// and provides clear feedback about document issues that might otherwise cause
/// cryptic failures in later processing stages.
final class ValidationProcessingStep: PayslipProcessingStep {
    typealias Input = Data
    typealias Output = Data
    
    /// The validation service used for validation
    private let validationService: PayslipValidationServiceProtocol
    
    /// Initialize with a validation service
    /// - Parameter validationService: The service to use for validation
    init(validationService: PayslipValidationServiceProtocol) {
        self.validationService = validationService
    }
    
    /// Process the input data by validating it
    /// - Parameter input: The PDF data to validate
    /// - Returns: Success with validated data or failure with error
    /// - Note: This method logs performance metrics and returns detailed error codes for validation failures
    func process(_ input: Data) async -> Result<Data, PDFProcessingError> {
        let startTime = Date()
        defer {
            print("[ValidationStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }
        
        // Validate that this is a valid PDF structure
        guard validationService.validatePDFStructure(input) else {
            print("[ValidationStep] Invalid PDF structure")
            return .failure(.invalidPDFStructure)
        }
        
        // Check if the PDF is password-protected
        if validationService.isPDFPasswordProtected(input) {
            print("[ValidationStep] PDF is password-protected")
            return .failure(.passwordProtected)
        }
        
        return .success(input)
    }
} 
import Foundation
import PDFKit

/// A concrete processing step for PDF validation
@MainActor
class ValidationProcessingStep: PayslipProcessingStep {
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
import Foundation
import PDFKit

/// A concrete processing step for text extraction from PDFs.
///
/// This processing step is responsible for extracting raw text content from PDF documents
/// and validating that the content appears to be payslip-related. It serves as a crucial 
/// bridge between the initial PDF validation and subsequent format-specific processing.
///
/// The step uses specialized text extraction services to handle different PDF structures
/// and ensure optimal content extraction. After extraction, it performs preliminary content
/// validation to quickly filter out non-payslip documents before more intensive processing.
///
/// Text extraction is often one of the most time-consuming parts of the pipeline, so this
/// step includes performance monitoring to help identify processing bottlenecks.
final class TextExtractionProcessingStep: PayslipProcessingStep {
    typealias Input = Data
    typealias Output = (Data, String)
    
    /// The text extraction service
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    /// The validation service for checking the extracted text
    private let validationService: PayslipValidationServiceProtocol
    
    /// Initialize with required services
    /// - Parameters:
    ///   - textExtractionService: Service for extracting text from PDFs
    ///   - validationService: Service for validating the extracted text
    init(
        textExtractionService: PDFTextExtractionServiceProtocol,
        validationService: PayslipValidationServiceProtocol
    ) {
        self.textExtractionService = textExtractionService
        self.validationService = validationService
    }
    
    /// Process the input by extracting text from the PDF data
    /// - Parameter input: The PDF data
    /// - Returns: Success with tuple of (original data, extracted text) or failure with error
    /// - Note: This method logs performance metrics and includes content validation to filter non-payslip documents
    func process(_ input: Data) async -> Result<(Data, String), PDFProcessingError> {
        let startTime = Date()
        defer {
            print("[TextExtractionStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }
        
        do {
            // Extract text from the PDF
            let extractedText = try textExtractionService.extractText(from: input)
            
            // Validate that the extracted text contains payslip content
            let validationResult = validationService.validatePayslipContent(extractedText)
            guard validationResult.isValid else {
                print("[TextExtractionStep] PDF does not appear to be a payslip")
                return .failure(.notAPayslip)
            }
            
            print("[TextExtractionStep] Extracted \(extractedText.count) characters of text")
            return .success((input, extractedText))
        } catch {
            print("[TextExtractionStep] Failed to extract text: \(error)")
            return .failure(.textExtractionFailed)
        }
    }
} 
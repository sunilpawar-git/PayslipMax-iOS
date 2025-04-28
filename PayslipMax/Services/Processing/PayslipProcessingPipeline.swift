import Foundation
import PDFKit
import UIKit

/// Protocol that defines a processing pipeline for payslips.
///
/// This protocol establishes the contract for payslip processing pipelines, outlining
/// the required stages and their expected input/output relationships. It provides a
/// standardized interface for different pipeline implementations, enabling various
/// processing strategies to be used interchangeably.
///
/// The protocol defines a complete processing workflow from raw PDF data to
/// structured payslip data, with distinct stages for:
/// - PDF validation
/// - Text extraction
/// - Format detection
/// - Data processing
///
/// Pipeline implementations must handle all stages and their transitions, including
/// proper error propagation between stages.
@MainActor protocol PayslipProcessingPipeline {
    /// Validates the PDF data to ensure it's properly formatted.
    ///
    /// This stage checks that the input represents a valid, accessible PDF document.
    /// It should verify the PDF structure and ensure the document is not password-protected.
    ///
    /// - Parameter data: The PDF data to validate
    /// - Returns: Success with the data or failure with an error
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError>
    
    /// Extracts text from the PDF data.
    ///
    /// This stage performs text extraction from the validated PDF document.
    /// It should handle different PDF structures and optimize for content extraction quality.
    ///
    /// - Parameter data: The validated PDF data
    /// - Returns: Success with the extracted text or failure with an error
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError>
    
    /// Detects the format of the payslip based on the extracted text.
    ///
    /// This stage analyzes the extracted text to determine the specific payslip format.
    /// It should use pattern matching and other detection techniques to identify the format.
    ///
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: Success with the detected format and original data or failure with an error
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError>
    
    /// Processes the payslip based on the detected format.
    ///
    /// This stage extracts structured data from the text based on the detected format.
    /// It should use format-specific processors to extract relevant fields.
    ///
    /// - Parameters:
    ///   - data: The PDF data
    ///   - text: The extracted text
    ///   - format: The detected payslip format
    /// - Returns: Success with the processed payslip or failure with an error
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError>
    
    /// Executes the full pipeline from validation to processing.
    ///
    /// This method coordinates the entire processing workflow, running each stage in sequence
    /// and handling transitions between stages. It should provide comprehensive error handling
    /// and may include performance monitoring.
    ///
    /// - Parameter data: The PDF data to process
    /// - Returns: Success with the processed payslip or failure with an error
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError>
} 
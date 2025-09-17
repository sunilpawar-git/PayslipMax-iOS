import Foundation
import PDFKit
import UIKit
import Vision
import CoreGraphics

/// Orchestrates the end-to-end processing of PDF documents to extract payslip data.
/// This service coordinates various specialized components for URL processing, password handling,
/// image processing, format validation, and data processing.
/// It leverages a configurable processing pipeline to manage the workflow.
@MainActor
class PDFProcessingService: PDFProcessingServiceProtocol {
    // MARK: - Properties

    /// Indicates whether the service and its dependencies have been successfully initialized.
    var isInitialized: Bool = false

    /// Handles URL-based PDF processing operations.
    private let urlProcessor: PDFURLProcessorProtocol

    /// Handles password-protected PDF operations.
    private let passwordHandler: PDFPasswordHandlerProtocol

    /// Handles scanned image processing operations.
    private let imageProcessor: PDFImageProcessorProtocol

    /// Handles PDF format detection and validation operations.
    private let formatValidator: PDFFormatValidatorProtocol

    /// Handles PDF data processing operations.
    private let dataProcessor: PDFDataProcessorProtocol

    /// The pipeline coordinating the sequential steps of payslip processing.
    private let processingPipeline: PayslipProcessingPipeline

    /// The core PDF service used for basic operations.
    private let pdfService: PDFServiceProtocol

    // MARK: - Initialization

    /// Initializes a new PDFProcessingService with its required dependencies.
    /// - Parameters:
    ///   - urlProcessor: Component for URL-based PDF processing.
    ///   - passwordHandler: Component for password protection operations.
    ///   - imageProcessor: Component for scanned image processing.
    ///   - formatValidator: Component for format detection and validation.
    ///   - dataProcessor: Component for PDF data processing.
    ///   - processingPipeline: The main processing pipeline.
    ///   - pdfService: The core PDF service for basic operations.
    init(
        urlProcessor: PDFURLProcessorProtocol,
        passwordHandler: PDFPasswordHandlerProtocol,
        imageProcessor: PDFImageProcessorProtocol,
        formatValidator: PDFFormatValidatorProtocol,
        dataProcessor: PDFDataProcessorProtocol,
        processingPipeline: PayslipProcessingPipeline,
        pdfService: PDFServiceProtocol
    ) {
        self.urlProcessor = urlProcessor
        self.passwordHandler = passwordHandler
        self.imageProcessor = imageProcessor
        self.formatValidator = formatValidator
        self.dataProcessor = dataProcessor
        self.processingPipeline = processingPipeline
        self.pdfService = pdfService
    }
    
    /// Initializes the service and its dependencies asynchronously.
    /// Ensures that dependent services like `pdfService` are ready.
    /// - Throws: An error if initialization of dependencies fails.
    func initialize() async throws {
        if !pdfService.isInitialized {
            try await pdfService.initialize()
        }
        isInitialized = true
    }

    // MARK: - PDFProcessingServiceProtocol Implementation

    /// Processes a PDF file specified by a URL.
    /// Delegates to the URL processor component.
    /// - Parameter url: The `URL` of the PDF file to process.
    /// - Returns: A `Result` containing the validated `Data` on success, or a `PDFProcessingError` on failure.
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        return await urlProcessor.processPDF(from: url)
    }

    /// Processes raw PDF data through the defined processing pipeline.
    /// Executes steps like validation, text extraction, format detection, and data extraction.
    /// - Parameter data: The raw `Data` of the PDF document.
    /// - Returns: A `Result` containing the extracted `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFProcessingService] Processing PDF of size: \(data.count) bytes")

        // Use the processing pipeline to process the PDF data
        return await processingPipeline.executePipeline(data)
    }
    
    /// Checks if the provided PDF data is password protected.
    /// Delegates to the password handler component.
    /// - Parameter data: The PDF data to check.
    /// - Returns: `true` if the PDF is password protected, `false` otherwise.
    func isPasswordProtected(_ data: Data) -> Bool {
        return passwordHandler.isPasswordProtected(data)
    }

    /// Unlocks a password-protected PDF using the provided password.
    /// Delegates to the password handler component.
    /// - Parameters:
    ///   - data: The `Data` of the password-protected PDF.
    ///   - password: The password to use for unlocking.
    /// - Returns: A `Result` containing the `Data` of the unlocked PDF on success, or `PDFProcessingError.incorrectPassword` on failure.
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        return await passwordHandler.unlockPDF(data, password: password)
    }
    
    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// Delegates to the image processor component.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: A `Result` containing the extracted `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        return await imageProcessor.processScannedImage(image)
    }

    /// Detects the format (e.g., Military, PCDA) of a defense personnel payslip PDF.
    /// Delegates to the format validator component.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: The detected `PayslipFormat`, or `.unknown` if detection fails.
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        return formatValidator.detectPayslipFormat(data)
    }

    /// Validates that the PDF data contains recognizable payslip content.
    /// Delegates to the format validator component.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: A `PayslipContentValidationResult` indicating validity and detected fields.
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        return formatValidator.validatePayslipContent(data)
    }

    /// Gets the detected format for a payslip based on previously extracted text.
    /// Delegates to the format validator component.
    /// - Parameter text: The extracted text content from a PDF.
    /// - Returns: The detected `PayslipFormat`, or `nil` if the format cannot be determined.
    func getPayslipFormat(from text: String) -> PayslipFormat? {
        return formatValidator.getPayslipFormat(from: text)
    }

    /// Gets a list of all payslip formats supported by the configured processors.
    /// Delegates to the format validator component.
    /// - Returns: An array of `PayslipFormat` values.
    func supportedFormats() -> [PayslipFormat] {
        return formatValidator.supportedFormats()
    }
    
    // MARK: - Processing Methods for Extracted Data

    /// Creates a `PayslipItem` from financial data already extracted by another process.
    /// Delegates to the data processor component.
    /// - Parameters:
    ///   - extractedData: A dictionary containing extracted financial key-value pairs.
    ///   - month: The month of the payslip.
    ///   - year: The year of the payslip.
    ///   - pdfData: The original PDF data.
    /// - Returns: A `Result` containing the created `PayslipItem` or a `PDFProcessingError`.
    func createPayslipFromExtractedData(extractedData: [String: Double], month: String, year: Int, pdfData: Data) async -> Result<PayslipItem, PDFProcessingError> {
        return await dataProcessor.createPayslipFromExtractedData(
            extractedData: extractedData,
            month: month,
            year: year,
            pdfData: pdfData
        )
    }

    /// Attempts special parsing logic on password-protected PDFs.
    /// Delegates to the password handler component.
    /// - Parameter data: The password-protected PDF data.
    /// - Returns: An optional `PayslipItem` if any data could be extracted, otherwise `nil`.
    func attemptSpecialParsingForPasswordProtectedPDF(data: Data) -> PayslipItem? {
        return passwordHandler.attemptSpecialParsingForPasswordProtectedPDF(data: data)
    }

    /// Processes extracted text assuming it's from a Military format payslip.
    /// Delegates to the data processor component.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processMilitaryPDF(from text: String) throws -> PayslipItem {
        return try dataProcessor.processMilitaryPDF(from: text)
    }

    /// Processes extracted text assuming it's from a PCDA format payslip.
    /// Delegates to the data processor component.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processPCDAPDF(from text: String) throws -> PayslipItem {
        return try dataProcessor.processPCDAPDF(from: text)
    }

    /// Processes extracted text assuming it's from a standard (non-specific) format payslip.
    /// Delegates to the data processor component.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processStandardPDF(from text: String) throws -> PayslipItem {
        return try dataProcessor.processStandardPDF(from: text)
    }
} 
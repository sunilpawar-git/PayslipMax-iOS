import Foundation
import PDFKit
import UIKit
import Vision
import CoreGraphics

/// Orchestrates the end-to-end processing of PDF documents to extract payslip data.
/// This service coordinates various underlying services like format detection, text extraction,
/// data parsing, validation, and error handling.
/// It leverages a configurable processing pipeline to manage the workflow.
@MainActor
class PDFProcessingService: PDFProcessingServiceProtocol {
    // MARK: - Properties

    /// Indicates whether the service and its dependencies (like PDFService) have been successfully initialized.
    var isInitialized: Bool = false

    /// The core PDF service used for basic operations like unlocking and initial processing.
    let pdfService: PDFServiceProtocol

    /// The service responsible for extracting structured data from PDF text content.
    internal let pdfExtractor: PDFExtractorProtocol

    /// Coordinates various parsing strategies and text extraction from PDF documents.
    internal let parsingCoordinator: any PDFParsingCoordinatorProtocol

    /// Service dedicated to detecting the specific format of a payslip (e.g., Military, PCDA).
    internal let formatDetectionService: PayslipFormatDetectionServiceProtocol

    /// Service used for validating PDF properties (e.g., password protection) and content.
    let validationService: PayslipValidationServiceProtocol

    /// The maximum duration allowed for a PDF processing operation before timing out.
    private let processingTimeout: TimeInterval = 30.0

    /// Optional user-provided hint to bias parsing without disabling auto-detect
    internal var userHint: PayslipUserHint = .auto

    /// Service specialized in extracting raw text content from PDF documents.
    private let textExtractionService: PDFTextExtractionServiceProtocol

    /// Factory responsible for creating the appropriate `PayslipProcessingStrategy` based on detected format.
    internal let processorFactory: PayslipProcessorFactory

    /// The pipeline coordinating the sequential steps of payslip processing (validation, extraction, etc.).
    internal let processingPipeline: PayslipProcessingPipeline

    /// Service focused on extracting specific financial figures and dates from text.
    private let dataExtractionService: DataExtractionService

    /// A pipeline step specifically for handling image-based inputs (e.g., scans) and converting them to PDF.
    internal let imageProcessingStep: ImageProcessingStep

    /// A pipeline step responsible for constructing the final `PayslipItem` from processed data.
    private let payslipCreationStep: PayslipCreationProcessingStep

    // Removed military fallback generator - simplified military processing

    // MARK: - Initialization

    /// Initializes a new PDFProcessingService with its required dependencies.
    /// - Parameters:
    ///   - pdfService: The core PDF service for basic operations.
    ///   - pdfExtractor: The service for extracting structured data from PDF text.
    ///   - parsingCoordinator: Coordinates parsing strategies and text extraction.
    ///   - formatDetectionService: Service for detecting the payslip format.
    ///   - validationService: Service for validating PDF properties and content.
    ///   - textExtractionService: Service for extracting raw text from PDFs.
    init(
        pdfService: PDFServiceProtocol,
        pdfExtractor: PDFExtractorProtocol,
        parsingCoordinator: any PDFParsingCoordinatorProtocol,
        formatDetectionService: PayslipFormatDetectionServiceProtocol,
        validationService: PayslipValidationServiceProtocol,
        textExtractionService: PDFTextExtractionServiceProtocol
    ) {
        self.pdfService = pdfService
        self.pdfExtractor = pdfExtractor
        self.parsingCoordinator = parsingCoordinator
        self.formatDetectionService = formatDetectionService
        self.validationService = validationService
        self.textExtractionService = textExtractionService

        // Create the processor factory
        self.processorFactory = PayslipProcessorFactory(formatDetectionService: formatDetectionService)

        // Create specialized services and helpers
        self.dataExtractionService = DataExtractionService(
            algorithms: DataExtractionAlgorithms(),
            validation: DataExtractionValidation()
        )
        self.imageProcessingStep = ImageProcessingStep()
        self.payslipCreationStep = PayslipCreationProcessingStep(dataExtractionService: dataExtractionService)
        // Removed military fallback generator initialization - simplified military processing

        // Create the processing pipeline - use the modular pipeline instead of DefaultPayslipProcessingPipeline
        self.processingPipeline = ModularPayslipProcessingPipeline(
            validationStep: AnyPayslipProcessingStep(ValidationProcessingStep(validationService: validationService)),
            textExtractionStep: AnyPayslipProcessingStep(TextExtractionProcessingStep(
                textExtractionService: textExtractionService,
                validationService: validationService)),
            formatDetectionStep: AnyPayslipProcessingStep(FormatDetectionProcessingStep(
                formatDetectionService: formatDetectionService)),
            processingStep: AnyPayslipProcessingStep(PayslipProcessingStepImpl(
                processorFactory: processorFactory))
        )
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

    // MARK: - Processing Methods for Extracted Data

    /// Creates a `PayslipItem` from financial data already extracted by another process.
    /// Delegates the creation logic to the `payslipCreationStep`.
    /// - Parameters:
    ///   - extractedData: A dictionary containing extracted financial key-value pairs.
    ///   - month: The month of the payslip.
    ///   - year: The year of the payslip.
    ///   - pdfData: The original PDF data.
    /// - Returns: A `Result` containing the created `PayslipItem` or a `PDFProcessingError`.
    private func createPayslipFromExtractedData(extractedData: [String: Double], month: String, year: Int, pdfData: Data) async -> Result<PayslipItem, PDFProcessingError> {
        return await payslipCreationStep.process((pdfData, extractedData, month, year))
    }

    /// Placeholder method for attempting special parsing logic on password-protected PDFs.
    /// In a future implementation, this could attempt to extract metadata or annotations
    /// that might be available even without unlocking the document.
    /// - Parameter data: The password-protected PDF data.
    /// - Returns: An optional `PayslipItem` if any data could be extracted, otherwise `nil`.
    private func attemptSpecialParsingForPasswordProtectedPDF(data: Data) -> PayslipItem? {
        // This is a placeholder for special handling of password-protected PDFs
        // In a real implementation, we would try to extract metadata or annotations

        return nil
    }



}


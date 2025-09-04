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
    private let pdfService: PDFServiceProtocol
    
    /// The service responsible for extracting structured data from PDF text content.
    private let pdfExtractor: PDFExtractorProtocol
    
    /// Coordinates various parsing strategies and text extraction from PDF documents.
    internal let parsingCoordinator: any PDFParsingCoordinatorProtocol
    
    /// Service dedicated to detecting the specific format of a payslip (e.g., Military, PCDA).
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol
    
    /// Service used for validating PDF properties (e.g., password protection) and content.
    private let validationService: PayslipValidationServiceProtocol
    
    /// The maximum duration allowed for a PDF processing operation before timing out.
    private let processingTimeout: TimeInterval = 30.0
    
    /// Service specialized in extracting raw text content from PDF documents.
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    /// Factory responsible for creating the appropriate `PayslipProcessingStrategy` based on detected format.
    private let processorFactory: PayslipProcessorFactory
    
    /// The pipeline coordinating the sequential steps of payslip processing (validation, extraction, etc.).
    private let processingPipeline: PayslipProcessingPipeline
    
    /// Service focused on extracting specific financial figures and dates from text.
    private let dataExtractionService: DataExtractionService
    
    /// A pipeline step specifically for handling image-based inputs (e.g., scans) and converting them to PDF.
    private let imageProcessingStep: ImageProcessingStep
    
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
        self.dataExtractionService = DataExtractionService()
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
    
    // MARK: - PDFProcessingServiceProtocol Implementation
    
    /// Processes a PDF file specified by a URL.
    /// Loads the PDF data, validates it, and returns the validated data if successful.
    /// - Parameter url: The `URL` of the PDF file to process.
    /// - Returns: A `Result` containing the validated `Data` on success, or a `PDFProcessingError` on failure.
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        print("[PDFProcessingService] Processing PDF file from URL: \(url)")
        
        do {
            // Use the process method from PDFServiceProtocol
            let data = try await pdfService.process(url)
            
            // Validate using the processing pipeline
            switch await processingPipeline.validatePDF(data) {
            case .success(let validData):
                return .success(validData)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            print("[PDFProcessingService] Error loading PDF file: \(error)")
            return .failure(.fileAccessError(error.localizedDescription))
        }
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
    /// This method delegates the check to the underlying `validationService`.
    /// - Parameter data: The PDF data to check.
    /// - Returns: `true` if the PDF is password protected, `false` otherwise.
    func isPasswordProtected(_ data: Data) -> Bool {
        return validationService.isPDFPasswordProtected(data)
    }
    
    /// Unlocks a password-protected PDF using the provided password.
    /// Delegates the unlocking operation to the underlying `pdfService`.
    /// - Parameters:
    ///   - data: The `Data` of the password-protected PDF.
    ///   - password: The password to use for unlocking.
    /// - Returns: A `Result` containing the `Data` of the unlocked PDF on success, or `PDFProcessingError.incorrectPassword` on failure.
    /// - Throws: Can rethrow errors from the underlying `pdfService` if unlocking fails for other reasons.
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        do {
            let unlockedData = try await pdfService.unlockPDF(data: data, password: password)
            return .success(unlockedData)
        } catch {
            print("[PDFProcessingService] Error unlocking PDF: \(error)")
            return .failure(.incorrectPassword)
        }
    }
    
    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: A `Result` containing the extracted `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFProcessingService] Processing scanned image")
        
        // Use the image processing step to convert image to PDF
        let pdfDataResult = await imageProcessingStep.process(image)
        
        switch pdfDataResult {
        case .success(let pdfData):
        // Process the PDF data using the pipeline
        return await processingPipeline.executePipeline(pdfData)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Detects the format (e.g., Military, PCDA) of a defense personnel payslip PDF.
    /// Extracts text from the PDF and uses the `formatDetectionService`.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: The detected `PayslipFormat`, or `.unknown` if detection fails or text extraction is not possible.
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        // Extract text from data
        guard let document = PDFDocument(data: data),
              let text = parsingCoordinator.extractFullText(from: document) else {
            return .unknown
        }
        
        // Use the format detection service to get the format
        let format = formatDetectionService.detectFormat(fromText: text)
        return format
    }
    
    /// Validates that the PDF data contains recognizable payslip content.
    /// Extracts text and delegates the validation logic to the `validationService`.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: A `PayslipContentValidationResult` indicating validity, confidence, and detected/missing fields.
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        // Extract text from data
        guard let document = PDFDocument(data: data),
              let text = parsingCoordinator.extractFullText(from: document) else {
            return PayslipContentValidationResult(isValid: false, confidence: 0, detectedFields: [], missingRequiredFields: ["Valid PDF"])
        }
        
        return validationService.validatePayslipContent(text)
    }
    
    /// Gets the detected format for a payslip based on previously extracted text.
    /// - Parameter text: The extracted text content from a PDF.
    /// - Returns: The detected `PayslipFormat`, or `nil` if the format cannot be determined from the text.
    func getPayslipFormat(from text: String) -> PayslipFormat? {
        return formatDetectionService.detectFormat(fromText: text)
    }
    
    /// Gets a list of all payslip formats supported by the configured processors.
    /// - Returns: An array of `PayslipFormat` values.
    func supportedFormats() -> [PayslipFormat] {
        let processors = processorFactory.getAllProcessors()
        return processors.map { $0.handlesFormat }
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
    
    /// Processes extracted text assuming it's from a Military format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    private func processMilitaryPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing military PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract military payslip data")
    }
    
    /// Processes extracted text assuming it's from a PCDA format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    private func processPCDAPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing PCDA PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract PCDA payslip data")
    }
    
    /// Processes extracted text assuming it's from a standard (non-specific) format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    private func processStandardPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing standard PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract standard payslip data")
    }
} 
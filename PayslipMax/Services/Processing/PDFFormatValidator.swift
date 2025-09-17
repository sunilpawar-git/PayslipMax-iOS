import Foundation
import PDFKit

/// Protocol for PDF format detection and validation operations
protocol PDFFormatValidatorProtocol {
    /// Detects the format (e.g., Military, PCDA) of a defense personnel payslip PDF.
    /// Extracts text from the PDF and uses format detection service.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: The detected `PayslipFormat`, or `.unknown` if detection fails.
    func detectPayslipFormat(_ data: Data) -> PayslipFormat

    /// Validates that the PDF data contains recognizable payslip content.
    /// Extracts text and delegates the validation logic to the validation service.
    /// - Parameter data: The `Data` of the PDF document.
    /// - Returns: A `PayslipContentValidationResult` indicating validity and detected fields.
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult

    /// Gets the detected format for a payslip based on previously extracted text.
    /// - Parameter text: The extracted text content from a PDF.
    /// - Returns: The detected `PayslipFormat`, or `nil` if the format cannot be determined.
    func getPayslipFormat(from text: String) -> PayslipFormat?

    /// Gets a list of all payslip formats supported by the configured processors.
    /// - Returns: An array of `PayslipFormat` values.
    func supportedFormats() -> [PayslipFormat]
}

/// Handles PDF format detection and validation operations
/// Responsible for identifying payslip formats and validating content
@MainActor
class PDFFormatValidator: PDFFormatValidatorProtocol {
    // MARK: - Properties

    /// Coordinates various parsing strategies and text extraction from PDF documents.
    private let parsingCoordinator: any PDFParsingCoordinatorProtocol

    /// Service dedicated to detecting the specific format of a payslip (e.g., Military, PCDA).
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol

    /// Service used for validating PDF properties and content.
    private let validationService: PayslipValidationServiceProtocol

    /// Factory responsible for creating payslip processing strategies.
    private let processorFactory: PayslipProcessorFactory

    // MARK: - Initialization

    /// Initializes a new PDFFormatValidator with its required dependencies.
    /// - Parameters:
    ///   - parsingCoordinator: Coordinates parsing strategies and text extraction.
    ///   - formatDetectionService: Service for detecting payslip formats.
    ///   - validationService: Service for validating PDF content.
    ///   - processorFactory: Factory for creating payslip processors.
    init(
        parsingCoordinator: any PDFParsingCoordinatorProtocol,
        formatDetectionService: PayslipFormatDetectionServiceProtocol,
        validationService: PayslipValidationServiceProtocol,
        processorFactory: PayslipProcessorFactory
    ) {
        self.parsingCoordinator = parsingCoordinator
        self.formatDetectionService = formatDetectionService
        self.validationService = validationService
        self.processorFactory = processorFactory
    }

    // MARK: - PDFFormatValidatorProtocol Implementation

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
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0,
                detectedFields: [],
                missingRequiredFields: ["Valid PDF"]
            )
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
}

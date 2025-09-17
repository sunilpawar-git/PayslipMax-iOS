import Foundation

/// Protocol for PDF data processing operations
protocol PDFDataProcessorProtocol {
    /// Creates a `PayslipItem` from financial data already extracted by another process.
    /// - Parameters:
    ///   - extractedData: A dictionary containing extracted financial key-value pairs.
    ///   - month: The month of the payslip.
    ///   - year: The year of the payslip.
    ///   - pdfData: The original PDF data.
    /// - Returns: A `Result` containing the created `PayslipItem` or a `PDFProcessingError`.
    func createPayslipFromExtractedData(
        extractedData: [String: Double],
        month: String,
        year: Int,
        pdfData: Data
    ) async -> Result<PayslipItem, PDFProcessingError>

    /// Processes extracted text assuming it's from a Military format payslip.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processMilitaryPDF(from text: String) throws -> PayslipItem

    /// Processes extracted text assuming it's from a PCDA format payslip.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processPCDAPDF(from text: String) throws -> PayslipItem

    /// Processes extracted text assuming it's from a standard (non-specific) format payslip.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processStandardPDF(from text: String) throws -> PayslipItem
}

/// Handles PDF data processing operations
/// Responsible for processing different payslip formats and creating PayslipItem objects
@MainActor
class PDFDataProcessor: PDFDataProcessorProtocol {
    // MARK: - Properties

    /// Service specialized in extracting specific financial figures and dates from text.
    private let dataExtractionService: DataExtractionService

    /// A pipeline step responsible for constructing the final `PayslipItem` from processed data.
    private let payslipCreationStep: PayslipCreationProcessingStep

    /// The service responsible for extracting structured data from PDF text content.
    private let pdfExtractor: PDFExtractorProtocol

    // MARK: - Initialization

    /// Initializes a new PDFDataProcessor with its required dependencies.
    /// - Parameters:
    ///   - dataExtractionService: Service for extracting financial data from text.
    ///   - payslipCreationStep: Pipeline step for creating PayslipItem objects.
    ///   - pdfExtractor: Service for extracting structured data from PDF text.
    init(
        dataExtractionService: DataExtractionService,
        payslipCreationStep: PayslipCreationProcessingStep,
        pdfExtractor: PDFExtractorProtocol
    ) {
        self.dataExtractionService = dataExtractionService
        self.payslipCreationStep = payslipCreationStep
        self.pdfExtractor = pdfExtractor
    }

    // MARK: - PDFDataProcessorProtocol Implementation

    /// Creates a `PayslipItem` from financial data already extracted by another process.
    /// Delegates the creation logic to the `payslipCreationStep`.
    /// - Parameters:
    ///   - extractedData: A dictionary containing extracted financial key-value pairs.
    ///   - month: The month of the payslip.
    ///   - year: The year of the payslip.
    ///   - pdfData: The original PDF data.
    /// - Returns: A `Result` containing the created `PayslipItem` or a `PDFProcessingError`.
    func createPayslipFromExtractedData(
        extractedData: [String: Double],
        month: String,
        year: Int,
        pdfData: Data
    ) async -> Result<PayslipItem, PDFProcessingError> {
        return await payslipCreationStep.process((pdfData, extractedData, month, year))
    }

    /// Processes extracted text assuming it's from a Military format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processMilitaryPDF(from text: String) throws -> PayslipItem {
        print("[PDFDataProcessor] Processing military PDF")
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
    func processPCDAPDF(from text: String) throws -> PayslipItem {
        print("[PDFDataProcessor] Processing PCDA PDF")
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
    func processStandardPDF(from text: String) throws -> PayslipItem {
        print("[PDFDataProcessor] Processing standard PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract standard payslip data")
    }
}

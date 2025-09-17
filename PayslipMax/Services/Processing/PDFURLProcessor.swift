import Foundation
import PDFKit

/// Protocol for URL-based PDF processing operations
protocol PDFURLProcessorProtocol {
    /// Processes a PDF file specified by a URL.
    /// Loads the PDF data, validates it, and returns the validated data if successful.
    /// - Parameter url: The `URL` of the PDF file to process.
    /// - Returns: A `Result` containing the validated `Data` on success, or a `PDFProcessingError` on failure.
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError>
}

/// Handles URL-based PDF processing operations
/// Responsible for loading PDF data from URLs and validating it
@MainActor
class PDFURLProcessor: PDFURLProcessorProtocol {
    // MARK: - Properties

    /// The core PDF service used for basic operations like unlocking and initial processing.
    private let pdfService: PDFServiceProtocol

    /// Service used for validating PDF properties (e.g., password protection) and content.
    private let validationService: PayslipValidationServiceProtocol

    // MARK: - Initialization

    /// Initializes a new PDFURLProcessor with its required dependencies.
    /// - Parameters:
    ///   - pdfService: The core PDF service for basic operations.
    ///   - validationService: Service for validating PDF properties and content.
    init(pdfService: PDFServiceProtocol, validationService: PayslipValidationServiceProtocol) {
        self.pdfService = pdfService
        self.validationService = validationService
    }

    // MARK: - PDFURLProcessorProtocol Implementation

    /// Processes a PDF file specified by a URL.
    /// Loads the PDF data, validates it, and returns the validated data if successful.
    /// - Parameter url: The `URL` of the PDF file to process.
    /// - Returns: A `Result` containing the validated `Data` on success, or a `PDFProcessingError` on failure.
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        print("[PDFURLProcessor] Processing PDF file from URL: \(url)")

        do {
            // Use the process method from PDFServiceProtocol
            let data = try await pdfService.process(url)

            // Validate the PDF data
            if validationService.isPDFPasswordProtected(data) {
                return .failure(.passwordProtected)
            }

            // Additional validation could be added here if needed
            return .success(data)
        } catch {
            print("[PDFURLProcessor] Error loading PDF file: \(error)")
            return .failure(.fileAccessError(error.localizedDescription))
        }
    }
}

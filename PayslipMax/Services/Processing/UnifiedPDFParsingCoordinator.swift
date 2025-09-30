import Foundation
import PDFKit

/// Unified PDF parsing coordinator that directly implements PDFParsingCoordinatorProtocol
/// using the ModularPayslipProcessingPipeline. This replaces the PayslipProcessingPipelineAdapter
/// to eliminate the adapter layer and provide direct pipeline integration.
@MainActor
final class UnifiedPDFParsingCoordinator: PDFParsingCoordinatorProtocol {

    // MARK: - Properties

    private let pipeline: PayslipProcessingPipeline

    // MARK: - Initialization

    init(pipeline: PayslipProcessingPipeline) {
        self.pipeline = pipeline
    }

    // MARK: - PDFParsingCoordinatorProtocol Implementation

    /// Parses a PDF document using the unified processing pipeline
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: The parsed PayslipItem, or nil if parsing failed
    /// - Throws: PDFProcessingError if parsing encounters an error
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipDTO? {
        // Convert PDFDocument to Data for pipeline processing
        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw PDFProcessingError.invalidFormat
        }

        // Execute the unified processing pipeline
        let result = await pipeline.executePipeline(pdfData)

        switch result {
        case .success(let payslipItem):
            return PayslipDTO(from: payslipItem)
        case .failure(let error):
            throw error
        }
    }

    /// Parses a PDF document using a specific parser name
    /// In the unified architecture, parser names are ignored as we use a single processor
    /// - Parameters:
    ///   - pdfDocument: The PDF document to parse
    ///   - parserName: The name of the parser (ignored in unified architecture)
    /// - Returns: The parsed PayslipItem, or nil if parsing failed
    /// - Throws: PDFProcessingError if parsing encounters an error
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipDTO? {
        // In the unified architecture, we use a single processor regardless of parser name
        print("[UnifiedPDFParsingCoordinator] Parser name '\(parserName)' ignored - using unified pipeline")
        return try await parsePayslip(pdfDocument: pdfDocument)
    }

    /// Selects the best parser for given text
    /// In the unified architecture, parser selection is handled internally by the pipeline
    /// - Parameter text: The text to analyze
    /// - Returns: Always returns nil as parser selection is internal to the pipeline
    nonisolated func selectBestParser(for text: String) -> PayslipParser? {
        // Unified architecture doesn't expose individual parsers
        // Parser selection is handled internally by the pipeline
        return nil
    }

    /// Extracts full text from a PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    nonisolated func extractFullText(from document: PDFDocument) -> String? {
        var fullText = ""

        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                if let pageText = page.string {
                    fullText += pageText + "\n"
                }
            }
        }

        return fullText.isEmpty ? nil : fullText
    }

    /// Gets all available parsers
    /// In the unified architecture, individual parsers are not exposed
    /// - Returns: Empty array as parsers are internal to the pipeline
    nonisolated func getAvailableParsers() -> [PayslipParser] {
        // Unified architecture uses internal processors, not exposed parsers
        return []
    }
}

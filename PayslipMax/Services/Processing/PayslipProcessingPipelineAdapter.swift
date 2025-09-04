import Foundation
import PDFKit

/// Adapter that makes PayslipProcessingPipeline compatible with PDFParsingCoordinatorProtocol
/// This is a temporary compatibility layer to ease the transition to the unified architecture
@MainActor
final class PayslipProcessingPipelineAdapter: PDFParsingCoordinatorProtocol {
    
    // MARK: - Properties
    
    private let pipeline: PayslipProcessingPipeline
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    // MARK: - Initialization
    
    init(pipeline: PayslipProcessingPipeline, textExtractionService: PDFTextExtractionServiceProtocol) {
        self.pipeline = pipeline
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - PDFParsingCoordinatorProtocol Implementation
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        // Convert PDFDocument to Data
        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw PDFProcessingError.invalidFormat
        }
        
        // Use the pipeline to process the PDF
        let result = await pipeline.executePipeline(pdfData)
        
        switch result {
        case .success(let payslipItem):
            return payslipItem
        case .failure(let error):
            throw error
        }
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        // Since we have a unified processor, ignore the parser name and use the default processing
        print("[PayslipProcessingPipelineAdapter] Parser name '\(parserName)' ignored - using unified military processor")
        return try await parsePayslip(pdfDocument: pdfDocument)
    }
    
    nonisolated func selectBestParser(for text: String) -> PayslipParser? {
        // No parsers in the unified architecture
        print("[PayslipProcessingPipelineAdapter] selectBestParser called - unified architecture uses processor instead")
        return nil
    }
    
    nonisolated func extractFullText(from document: PDFDocument) -> String? {
        // Extract text page by page since we're in unified architecture
        var allText = ""
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                allText += page.string ?? ""
            }
        }
        return allText.isEmpty ? nil : allText
    }
    
    nonisolated func getAvailableParsers() -> [PayslipParser] {
        // No parsers in the unified architecture
        return []
    }
}

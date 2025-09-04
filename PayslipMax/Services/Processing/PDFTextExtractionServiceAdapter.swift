import Foundation
import PDFKit

/// Adapter that makes PDFTextExtractionService compatible with TextExtractionServiceProtocol
/// This enables backward compatibility during the transition to the unified architecture
final class PDFTextExtractionServiceAdapter: TextExtractionServiceProtocol {
    
    // MARK: - Properties
    
    private let pdfTextExtractionService: PDFTextExtractionServiceProtocol
    
    // MARK: - Initialization
    
    init(_ pdfTextExtractionService: PDFTextExtractionServiceProtocol) {
        self.pdfTextExtractionService = pdfTextExtractionService
    }
    
    // MARK: - TextExtractionServiceProtocol Implementation
    
    func extractText(from pdfDocument: PDFDocument) async -> String {
        // Extract text page by page since PDFTextExtractionService expects Data
        var allText = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                allText += page.string ?? ""
            }
        }
        return allText
    }
    
    func extractText(from page: PDFPage) -> String {
        return page.string ?? ""
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) async -> String {
        // Delegate to the main extraction method
        return await extractText(from: pdfDocument)
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // Simple diagnostic logging
        print("[PDFTextExtractionServiceAdapter] Diagnosing PDF with \(pdfDocument.pageCount) pages")
        print("[PDFTextExtractionServiceAdapter] PDF data size: \(pdfDocument.dataRepresentation()?.count ?? 0) bytes")
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        // Check if any page has text content
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageString = page.string,
               !pageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }
}

/// Simple error enumeration for text extraction
enum TextExtractionError: Error {
    case invalidPDFData
    case extractionFailed
}

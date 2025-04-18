import Foundation
import PDFKit

// Extension to make StandardTextExtractionService work with the profiler
extension StandardTextExtractionService {
    
    /// Extract text with completion handler for profiling purposes
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - completion: Completion handler with extracted text
    func extractTextWithCompletion(from document: PDFDocument, completion: @escaping (String) -> Void) {
        let text = extractText(from: document)
        completion(text)
    }
    
    /// Extract text from a specific page range with completion handler for profiling purposes
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - range: The range of pages to extract
    ///   - completion: Completion handler with extracted text
    func extractTextWithCompletion(from document: PDFDocument, in range: Range<Int>, completion: @escaping (String) -> Void) {
        let text = extractText(from: document, in: range)
        completion(text)
    }
} 
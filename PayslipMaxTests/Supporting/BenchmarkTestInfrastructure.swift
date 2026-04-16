import Foundation
import PDFKit
@testable import PayslipMax

/// Comprehensive test infrastructure for benchmarking text extraction methods.
///
/// This infrastructure provides stub implementations of various text extraction
/// services and utilities needed for benchmark testing. It includes simulated
/// processing times and memory usage to provide realistic benchmark scenarios.
class BenchmarkTestInfrastructure {
    
    // MARK: - Static Access
    
    static let shared = BenchmarkTestInfrastructure()
    
    private init() {}
    
    // MARK: - Factory Methods
    
    /// Creates a standard text extractor adapter for benchmarking
    /// - Returns: A PDFTextExtractionServiceProtocol implementation
    func createStandardTextExtractorAdapter() -> PDFTextExtractionServiceProtocol {
        return StandardTextExtractorAdapter()
    }
    
    /// Creates a Vision-based text extractor adapter for benchmarking
    /// - Returns: A PDFTextExtractionServiceProtocol implementation
    func createVisionTextExtractorAdapter() -> PDFTextExtractionServiceProtocol {
        return VisionTextExtractorAdapter()
    }
    
    /// Creates a benchmark streaming PDF processor
    /// - Returns: A BenchmarkStreamingPDFProcessor instance
    func createStreamingPDFProcessor() -> BenchmarkStreamingPDFProcessor {
        return BenchmarkStreamingPDFProcessor()
    }
    
    /// Creates a benchmark text extraction service
    /// - Returns: A TextExtractionServiceProtocol implementation
    func createTextExtractionService() -> TextExtractionServiceProtocol {
        return BenchmarkTextExtractionService()
    }
    
    /// Creates a benchmark PDF processing cache
    /// - Returns: A BenchmarkPDFProcessingCache instance
    func createPDFProcessingCache() -> BenchmarkPDFProcessingCache {
        return BenchmarkPDFProcessingCache.shared
    }
}

// MARK: - StreamingPDFProcessor Stub

/// Stub implementation of StreamingPDFProcessor
class BenchmarkStreamingPDFProcessor {
    /// Process a document in a streaming manner
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressHandler: Handler to receive progress updates
    /// - Returns: The extracted text
    func processDocumentStreaming(_ document: PDFDocument, progressHandler: @escaping (Double, String) -> Void) async -> String {
        var result = ""
        
        // Simple implementation that extracts text from each page
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                // Extract text from page
                let pageText = page.string ?? ""
                result += pageText + "\n\n"
                
                // Report progress
                let progress = Double(i + 1) / Double(document.pageCount)
                progressHandler(progress, pageText)
            }
        }
        
        return result
    }
}

// MARK: - TextExtractionService Stub

/// Stub implementation of TextExtractionService
class BenchmarkTextExtractionService: TextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var result = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                result += page.string ?? ""
                if i < document.pageCount - 1 {
                    result += "\n\n"
                }
            }
        }
        
        return result
    }
    
    // Add stubs for conformance to TextExtractionServiceProtocol
    func extractText(from page: PDFPage) -> String {
        return page.string ?? ""
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        return extractText(from: pdfDocument)
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // No-op in stub implementation
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        return true
    }
}

// MARK: - PDFProcessingCache Stub

/// Stub implementation of PDFProcessingCache
class BenchmarkPDFProcessingCache {
    static let shared = BenchmarkPDFProcessingCache()
    
    private var cache: [String: Any] = [:]
    
    func store<T>(_ value: T, forKey key: String) throws {
        cache[key] = value
    }
    
    func retrieve<T>(forKey key: String) throws -> T {
        guard let value = cache[key] as? T else {
            throw NSError(domain: "PDFProcessingCache", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found in cache"])
        }
        return value
    }
}



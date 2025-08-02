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

// MARK: - PDFTextExtractionService Stub

/// Stub implementation of PDFTextExtractionService
class BenchmarkPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
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
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount else { return nil }
        return document.page(at: pageIndex)?.string
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        var result = ""
        for i in range {
            if let page = document.page(at: i) {
                result += page.string ?? ""
            }
        }
        return result
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 0
    }
    
    func extractText(from data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw NSError(domain: "BenchmarkPDFTextExtractionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document from data"])
        }
        return extractText(from: document) ?? ""
    }
}

// MARK: - Required Protocols

/// Protocol for text extraction service
protocol BenchmarkTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

/// Protocol for PDF text extraction service
protocol BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

// Test implementations for benchmark protocol
private struct StandardExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
            }
        }
        return text
    }
}

private struct VisionExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        // Simulated Vision implementation
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
                // Vision would typically provide better text recognition
                text += " [Enhanced with Vision]"
            }
        }
        return text
    }
}

// MARK: - Adapters for Main Protocol

/// Standard text extractor adapter
struct StandardTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 0.5) // Simulating processing time
        let end = CFAbsoluteTimeGetCurrent()
        
        print("StandardExtractor time: \(end - start) seconds")
        return text
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractTextFromPage(at: pageIndex, in: document)
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractText(from: document, in: range)
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 0
    }
    
    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        return try service.extractText(from: data)
    }
}

/// Vision-based text extractor adapter
struct VisionTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 1.5) // Simulating longer processing time for Vision
        let end = CFAbsoluteTimeGetCurrent()
        
        print("VisionExtractor time: \(end - start) seconds")
        return text
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.2) // Simulating Vision processing
        return service.extractTextFromPage(at: pageIndex, in: document)
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.5) // Simulating Vision processing
        return service.extractText(from: document, in: range)
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 10_000_000 // 10MB simulated memory usage
    }
    
    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.3) // Simulating Vision processing
        return try service.extractText(from: data)
    }
}


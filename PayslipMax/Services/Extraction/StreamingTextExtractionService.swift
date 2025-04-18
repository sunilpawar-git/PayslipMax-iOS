import Foundation
import PDFKit

/// Protocol defining the interface for streaming text extraction
protocol StreamingTextExtractionServiceProtocol {
    /// Extract text from a PDF document using streaming processing
    /// - Parameter document: The PDF document to process
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) -> String
    
    /// Extract text from a PDF document with progress updates
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressHandler: Closure that receives progress updates (0.0 to 1.0)
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument, progressHandler: @escaping (Double, String) -> Void) -> String
}

/// Service that provides streaming-based text extraction from PDF documents
class StreamingTextExtractionService: StreamingTextExtractionServiceProtocol {
    
    // MARK: - Properties
    
    private let processor: StreamingPDFProcessor
    private let options: StreamingProcessingOptions
    
    // MARK: - Initialization
    
    /// Initialize a new streaming text extraction service
    /// - Parameters:
    ///   - processor: The streaming PDF processor to use
    ///   - options: Options to configure streaming processing
    init(
        processor: StreamingPDFProcessor? = nil,
        options: StreamingProcessingOptions? = nil
    ) {
        self.processor = processor ?? StreamingPDFProcessor()
        self.options = options ?? StreamingProcessingOptions()
    }
    
    // MARK: - Public API
    
    /// Extract text from a PDF document using streaming processing
    /// - Parameter document: The PDF document to process
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) -> String {
        return extractText(from: document) { _, _ in }
    }
    
    /// Extract text from a PDF document with progress updates
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressHandler: Closure that receives progress updates (0.0 to 1.0)
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument, progressHandler: @escaping (Double, String) -> Void) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        
        Task {
            result = await processor.processDocumentStreaming(document) { progress, page in
                progressHandler(progress, "Processing page \(page)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}

/// Options for streaming PDF processing
struct StreamingProcessingOptions {
    /// Maximum memory threshold in bytes
    let memoryThreshold: Int64
    
    /// Batch size for processing
    let batchSize: Int
    
    /// Whether to preprocess text during extraction
    let preprocessText: Bool
    
    /// Initialize processing options
    /// - Parameters:
    ///   - memoryThreshold: Maximum memory threshold in bytes
    ///   - batchSize: Batch size for processing
    ///   - preprocessText: Whether to preprocess text during extraction
    init(
        memoryThreshold: Int64 = 100 * 1024 * 1024, // 100 MB
        batchSize: Int = 5,
        preprocessText: Bool = true
    ) {
        self.memoryThreshold = memoryThreshold
        self.batchSize = batchSize
        self.preprocessText = preprocessText
    }
} 
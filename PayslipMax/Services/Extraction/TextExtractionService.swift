import Foundation
import PDFKit

/// Service for extracting text from PDF documents
// Declare conformance to TextExtractor protocol
class TextExtractionService: TextExtractionServiceProtocol, TextExtractor {
    // MARK: - Properties
    
    /// Cache for storing extracted text
    private let textCache: PDFProcessingCache
    
    /// Memory usage threshold for switching to progressive extraction (in MB)
    private let memoryThreshold: Int
    
    /// Streaming processor for handling large documents
    private let streamingProcessor: StreamingPDFProcessor
    
    // MARK: - Initialization
    
    /// Initializes a TextExtractionService with custom parameters
    /// - Parameters:
    ///   - useCache: Whether to use caching for text extraction
    ///   - memoryThreshold: Memory threshold in MB for switching to progressive extraction
    init(useCache: Bool = true, memoryThreshold: Int = 200) {
        self.textCache = PDFProcessingCache(memoryCacheSize: 20, diskCacheSize: 50)
        self.memoryThreshold = memoryThreshold * 1024 * 1024
        self.streamingProcessor = StreamingPDFProcessor()
    }
    
    // MARK: - Public Methods
    
    /// Extracts text from a PDF document. Handles large documents asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) async -> String {
        // Check if we have a cached result
        let cacheKey = pdfDocument.cacheKey()
        if let cachedText: String = textCache.retrieve(forKey: cacheKey) {
            print("[TextExtractionService] Using cached text for document")
            return cachedText
        }
        
        // Check if this is a large document that requires progressive extraction
        if pdfDocument.pageCount > 30 || estimateDocumentSize(pdfDocument) > memoryThreshold {
            print("[TextExtractionService] Using progressive extraction for large document (\(pdfDocument.pageCount) pages)")
            // Await the async progressive extraction
            return await extractTextProgressively(from: pdfDocument)
        }
        
        // Standard extraction for normal sized documents
        let text = pdfDocument.string ?? ""
        
        // Cache the result if not empty
        if !text.isEmpty {
            _ = textCache.store(text, forKey: cacheKey)
        }
        
        return text
    }
    
    /// Extracts text from a specific page of a PDF document
    /// - Parameters:
    ///   - page: The PDF page to extract text from
    /// - Returns: The extracted text
    func extractText(from page: PDFPage) -> String {
        return page.string ?? ""
    }
    
    /// Extracts text from all pages of a PDF document with detailed logging.
    /// Handles large documents asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractDetailedText(from pdfDocument: PDFDocument) async -> String {
        var extractedText = ""
        
        print("[TextExtractionService] PDF has \(pdfDocument.pageCount) pages")
        
        // Check if we should use progressive extraction
        if pdfDocument.pageCount > 30 || estimateDocumentSize(pdfDocument) > memoryThreshold {
            print("[TextExtractionService] Using progressive extraction for large document")
            // Await the async progressive extraction with logging
            return await extractTextProgressively(from: pdfDocument, withLogging: true)
        }
        
        // Extract text from each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                let pageSize = pageRect.size
                print("[TextExtractionService] Page \(i+1) size: \(pageSize.width) x \(pageSize.height)")
                print("[TextExtractionService] Page \(i+1) rotation: \(page.rotation)")
                
                // Extract text from page
                if let text = page.string, !text.isEmpty {
                    print("[TextExtractionService] Page \(i+1) has \(text.count) characters of text")
                    extractedText += text + "\n\n"
                } else {
                    print("[TextExtractionService] Page \(i+1) has no text content, may be image-only")
                }
            }
        }
        
        return extractedText
    }
    
    /// Logging text extraction diagnostic information
    /// - Parameter pdfDocument: The PDF document to diagnose
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // Log basic document info
        let pdfData = pdfDocument.dataRepresentation()
        print("[TextExtractionService] PDF data size: \(pdfData?.count ?? 0) bytes")
        print("[TextExtractionService] PDF has \(pdfDocument.pageCount) pages")
        
        // Log info for each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                let pageSize = pageRect.size
                print("[TextExtractionService] Page \(i+1) size: \(pageSize.width) x \(pageSize.height)")
                print("[TextExtractionService] Page \(i+1) rotation: \(page.rotation)")
                
                // Check if page has text
                if let text = page.string, !text.isEmpty {
                    print("[TextExtractionService] Page \(i+1) has \(text.count) characters of text")
                } else {
                    print("[TextExtractionService] Page \(i+1) has no text content, may be image-only")
                }
            }
        }
    }
    
    /// Checks if a PDF document is valid and contains text
    /// - Parameter pdfDocument: The PDF document to validate
    /// - Returns: True if the document is valid and has text content
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), 
               let text = page.string, 
               !text.isEmpty {
                return true
            }
        }
        return false
    }
    
    // MARK: - Private Methods
    
    /// Extracts text progressively but synchronously
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract text from
    ///   - withLogging: Whether to include detailed logging
    /// - Returns: The extracted text
    private func extractTextProgressivelySync(from pdfDocument: PDFDocument, withLogging: Bool = false) -> String {
        // Check cache first
        let cacheKey = pdfDocument.cacheKey()
        if let cachedText: String = textCache.retrieve(forKey: cacheKey) {
            print("[TextExtractionService] Using cached text for large document")
            return cachedText
        }
        
        print("[TextExtractionService] Starting progressive text extraction on \(pdfDocument.pageCount) pages")
        
        // Variables to store state during processing
        var result = ""
        var isComplete = false
        
        // Start the processing task on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            // Process each page
            var allText = ""
            var currentBatch = ""
            var batchSize = 0
            let maxBatchSize = 5
            
            for i in 0..<pdfDocument.pageCount {
                autoreleasepool {
                    guard let page = pdfDocument.page(at: i), let text = page.string else { return }
                    
                    // Add to current batch
                    currentBatch += text + "\n\n"
                    batchSize += 1
                    
                    // Calculate progress
                    let progress = Double(i + 1) / Double(pdfDocument.pageCount)
                    
                    if withLogging {
                        print("[TextExtractionService] Extraction progress: \(Int(progress * 100))% - \(text.count) chars extracted")
                    }
                    
                    // Process batch when it reaches max size or this is the last page
                    if batchSize >= maxBatchSize || i == pdfDocument.pageCount - 1 {
                        allText += currentBatch
                        currentBatch = ""
                        batchSize = 0
                    }
                }
            }
            
            // Store final result
            result = allText
            
            // Cache the result
            if !result.isEmpty {
                _ = self.textCache.store(result, forKey: cacheKey)
            }
            
            print("[TextExtractionService] Progressive extraction completed with \(result.count) chars")
            isComplete = true
        }
        
        // Wait for processing to complete with timeout
        let timeout = Date().addingTimeInterval(30) // 30 second timeout
        while !isComplete && Date() < timeout {
            // Let the RunLoop process other events while we wait
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }
        
        if !isComplete {
            print("[TextExtractionService] Progressive extraction timed out")
        }
        
        return result
    }
    
    /// Extracts text progressively using structured concurrency.
    /// This method is suitable for large documents where extracting all text at once might cause memory issues.
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract text from.
    ///   - withLogging: Whether to include detailed logging during extraction.
    /// - Returns: The extracted text.
    private func extractTextProgressively(from pdfDocument: PDFDocument, withLogging: Bool = false) async -> String {
        // Check cache first
        let cacheKey = pdfDocument.cacheKey()
        if let cachedText: String = textCache.retrieve(forKey: cacheKey) {
            if withLogging { print("[TextExtractionService] Using cached text for large document") }
            return cachedText
        }
        
        if withLogging { print("[TextExtractionService] Starting progressive text extraction on \(pdfDocument.pageCount) pages") }
        
        var allText = ""
        var currentBatch = ""
        var batchSize = 0
        let maxBatchSize = 5 // Process in batches to potentially yield if needed, though direct iteration is often fine.
        
        for i in 0..<pdfDocument.pageCount {
            // Check for cancellation if this task becomes part of a larger cooperative cancellation system.
            // try Task.checkCancellation() // Example: Add if needed later
            
            // Use autoreleasepool to manage memory for potentially large page objects/text.
            autoreleasepool {
                guard let page = pdfDocument.page(at: i), let text = page.string else { return }
                
                // Add to current batch
                currentBatch += text + "\n\n"
                batchSize += 1
                
                // Log progress if enabled
                if withLogging {
                    let progress = Double(i + 1) / Double(pdfDocument.pageCount)
                    print("[TextExtractionService] Extraction progress: \(Int(progress * 100))% - \(text.count) chars extracted from page \(i+1)")
                }
                
                // Append batch when it reaches max size or this is the last page
                if batchSize >= maxBatchSize || i == pdfDocument.pageCount - 1 {
                    allText += currentBatch
                    currentBatch = ""
                    batchSize = 0
                }
            }
            
            // Yield the task briefly to allow other tasks to run, especially important for long loops.
            // Remove this if profiling shows it's unnecessary overhead.
            await Task.yield()
        }
        
        // Cache the final result
        if !allText.isEmpty {
            _ = self.textCache.store(allText, forKey: cacheKey)
        }
        
        if withLogging { print("[TextExtractionService] Progressive extraction completed with \(allText.count) chars") }
        
        return allText
    }
    
    /// Estimates the size of a PDF document in memory
    /// - Parameter pdfDocument: The PDF document to estimate
    /// - Returns: Estimated size in bytes
    private func estimateDocumentSize(_ pdfDocument: PDFDocument) -> Int {
        // Base size for the document structure
        var estimatedSize = 1024 * 1024 // Start with 1MB base size
        
        // Add size of PDF data if available
        if let pdfData = pdfDocument.dataRepresentation() {
            estimatedSize += pdfData.count
        }
        
        // Estimate size based on pages and content
        for i in 0..<min(3, pdfDocument.pageCount) {
            if let page = pdfDocument.page(at: i), let text = page.string {
                // Estimate text size (UTF-16 is 2 bytes per character)
                let textSize = text.count * 2
                
                // Extrapolate for all pages
                estimatedSize += (textSize * pdfDocument.pageCount) / 3
                break
            }
        }
        
        return estimatedSize
    }

    // Add implementations for TextExtractor protocol methods if missing
    // (extractData and extractTabularData - assuming they exist below)

    func extractData(from text: String) -> [String : String] {
        // Placeholder - Requires actual implementation or delegation
        print("[TextExtractionService] extractData(from: String) called - needs implementation")
        return [:] 
    }

    func extractTabularData(from text: String) -> ([String : Double], [String : Double]) {
        // Placeholder - Requires actual implementation or delegation
        print("[TextExtractionService] extractTabularData(from: String) called - needs implementation")
        return ([:], [:])
    }
} 
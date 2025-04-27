import Foundation
import PDFKit

/// Protocol for optimized text extraction service
protocol OptimizedTextExtractionServiceProtocol {
    /// Extracts text with optimal strategy based on PDF characteristics. Runs asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractOptimizedText(from document: PDFDocument) async -> String
    
    /// Analyzes a PDF document to determine optimal extraction strategy
    /// - Parameter document: The PDF document to analyze
    /// - Returns: The determined extraction strategy
    func analyzeDocument(_ document: PDFDocument) -> PDFExtractionStrategy
    
    /// Extracts text using a specific strategy
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - strategy: The extraction strategy to use
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument, using strategy: PDFExtractionStrategy) async -> String
}

/// Enum representing different PDF extraction strategies
enum PDFExtractionStrategy: String {
    /// Standard extraction using PDFKit's built-in extraction
    case standard
    
    /// Vision framework-based extraction for image-based PDFs
    case vision
    
    /// Layout-aware extraction for documents with complex structures
    case layoutAware
    
    /// Fast extraction for simple text-based PDFs
    case fastText
}

/// Service providing optimized text extraction from PDF documents
class OptimizedTextExtractionService: OptimizedTextExtractionServiceProtocol {
    // MARK: - Properties
    
    /// Text extraction service for standard extraction
    private let textExtractionService: TextExtractionServiceProtocol
    
    /// Cache for storing extracted text
    private let textCache: PDFProcessingCache
    
    /// Streaming processor for handling large documents
    private let streamingProcessor: StreamingPDFProcessor
    
    // MARK: - Initialization
    
    /// Initializes an OptimizedTextExtractionService with custom parameters
    /// - Parameters:
    ///   - textExtractionService: The standard text extraction service
    ///   - textCache: Cache for storing extracted text
    ///   - streamingProcessor: Streaming processor for handling large documents
    init(
        textExtractionService: TextExtractionServiceProtocol? = nil,
        textCache: PDFProcessingCache? = nil,
        streamingProcessor: StreamingPDFProcessor? = nil
    ) {
        self.textExtractionService = textExtractionService ?? TextExtractionService()
        self.textCache = textCache ?? PDFProcessingCache(memoryCacheSize: 20, diskCacheSize: 50)
        self.streamingProcessor = streamingProcessor ?? StreamingPDFProcessor()
    }
    
    // MARK: - OptimizedTextExtractionServiceProtocol Implementation
    
    /// Extracts text with optimal strategy based on PDF characteristics. Runs asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractOptimizedText(from document: PDFDocument) async -> String {
        // Check cache first
        let cacheKey = "optimized_\(document.cacheKey())"
        if let cachedText: String = textCache.retrieve(forKey: cacheKey) {
            print("[OptimizedTextExtractionService] Using cached text for document")
            return cachedText
        }
        
        // Analyze document to determine optimal strategy
        let strategy = analyzeDocument(document)
        print("[OptimizedTextExtractionService] Using \(strategy.rawValue) strategy for document")
        
        // Extract text using the selected strategy (now requires await)
        let extractedText = await extractText(from: document, using: strategy)
        
        // Cache the result if not empty
        if !extractedText.isEmpty {
            _ = textCache.store(extractedText, forKey: cacheKey)
        }
        
        return extractedText
    }
    
    /// Analyzes a PDF document to determine optimal extraction strategy
    /// - Parameter document: The PDF document to analyze
    /// - Returns: The determined extraction strategy
    func analyzeDocument(_ document: PDFDocument) -> PDFExtractionStrategy {
        // Get document attributes
        let hasText = documentHasText(document)
        let hasImages = documentHasImages(document)
        let isComplex = isComplexLayout(document)
        let pageCount = document.pageCount
        
        // Decision logic based on document characteristics
        if !hasText && hasImages {
            // Image-based PDF with no text
            return .vision
        } else if isComplex {
            // Complex layout needs special handling
            return .layoutAware
        } else if pageCount > 50 {
            // Large document benefits from faster extraction
            return .fastText
        } else {
            // Simple text document can use standard extraction
            return .standard
        }
    }
    
    /// Extracts text using a specific strategy
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - strategy: The extraction strategy to use
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument, using strategy: PDFExtractionStrategy) async -> String {
        switch strategy {
        case .standard:
            // Await the async standard strategy
            return await extractUsingStandardStrategy(from: document)
        case .vision:
            // Assuming vision strategy might become async in the future
            // For now, it returns synchronously but the wrapper function is async
            return extractUsingVisionStrategy(from: document)
        case .layoutAware:
            // Assuming layout aware strategy might become async
            return extractUsingLayoutAwareStrategy(from: document)
        case .fastText:
            // Assuming fast text strategy might become async
            return extractUsingFastTextStrategy(from: document)
        }
    }
    
    // MARK: - Strategy Implementations
    
    /// Extracts text using the standard PDFKit strategy (now async).
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    private func extractUsingStandardStrategy(from document: PDFDocument) async -> String {
        // Await the underlying async text extraction service call
        return await textExtractionService.extractText(from: document)
    }
    
    /// Extracts text using the Vision framework for image-based PDFs
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    private func extractUsingVisionStrategy(from document: PDFDocument) -> String {
        // In a real implementation, this would use Vision framework for OCR
        // This is simplified for demonstration purposes
        var extractedText = ""
        
        // Simulate Vision framework extraction with standard extraction
        for i in 0..<document.pageCount {
            autoreleasepool {
                if let page = document.page(at: i), let pageText = page.string {
                    extractedText += pageText + "\n\n"
                } else {
                    // If no text found, this would trigger OCR in a real implementation
                    extractedText += "[Image-based content on page \(i+1) would be processed with OCR]\n\n"
                }
            }
        }
        
        return extractedText
    }
    
    /// Extracts text using a layout-aware strategy for complex documents
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    private func extractUsingLayoutAwareStrategy(from document: PDFDocument) -> String {
        var extractedText = ""
        
        // Process each page with layout awareness
        for i in 0..<document.pageCount {
            autoreleasepool {
                guard let page = document.page(at: i) else { return }
                
                // Get page bounds for layout analysis
                let pageBounds = page.bounds(for: .mediaBox)
                
                // Analyze document into columns and regions
                let regions = analyzePageLayout(page, bounds: pageBounds)
                
                // Extract text from each region in reading order
                var pageText = ""
                for _ in regions {
                    // In a real implementation, we would extract text from each region
                    if let regionText = page.attributedString?.string {
                        pageText += regionText + " "
                    }
                }
                
                extractedText += pageText + "\n\n"
            }
        }
        
        return extractedText
    }
    
    /// Helper method to analyze page layout into regions
    private func analyzePageLayout(_ page: PDFPage, bounds: CGRect) -> [CGRect] {
        // In a real implementation, this would analyze the page layout
        // For now, return the whole page as a single region
        return [bounds]
    }
    
    /// Extracts text using a fast strategy optimized for simple text documents
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    private func extractUsingFastTextStrategy(from document: PDFDocument) -> String {
        // Use streamingProcessor for fast processing 
        var extractedText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageText = page.string {
                extractedText += pageText + "\n\n"
            }
        }
        
        return extractedText
    }
    
    // MARK: - Document Analysis Helpers
    
    /// Checks if a document contains textual content
    /// - Parameter document: The PDF document to check
    /// - Returns: True if the document contains text, false otherwise
    private func documentHasText(_ document: PDFDocument) -> Bool {
        // Check the first few pages for text
        for i in 0..<min(3, document.pageCount) {
            if let page = document.page(at: i), let text = page.string, !text.isEmpty {
                return true
            }
        }
        return false
    }
    
    /// Checks if a document contains images
    /// - Parameter document: The PDF document to check
    /// - Returns: True if the document contains images, false otherwise
    private func documentHasImages(_ document: PDFDocument) -> Bool {
        // In a real implementation, this would analyze PDF structures for images
        // For now, use a simplified check based on document properties
        if let data = document.dataRepresentation(), data.count > 100_000 {
            // Large files often contain images
            if documentHasText(document) {
                // If the document has text but is large, it likely has images too
                let textSize = document.string?.count ?? 0
                let dataRatio = Double(data.count) / Double(textSize + 1)
                return dataRatio > 100 // Arbitrary threshold
            }
            return true
        }
        return false
    }
    
    /// Checks if a document has a complex layout
    /// - Parameter document: The PDF document to check
    /// - Returns: True if the document has a complex layout, false otherwise
    private func isComplexLayout(_ document: PDFDocument) -> Bool {
        // In a real implementation, this would analyze page structure
        // For now, use a simplified heuristic
        for i in 0..<min(3, document.pageCount) {
            if let page = document.page(at: i) {
                if page.string?.contains("\t") ?? false || page.string?.contains("\r") ?? false {
                    // Tabs and carriage returns often indicate complex layouts
                    return true
                }
            }
        }
        return false
    }
}

extension PDFDocument {
    func cacheKey() -> String {
        if let documentAttributes = self.documentAttributes {
            if let title = documentAttributes[PDFDocumentAttribute.titleAttribute] as? String {
                return title
            }
        }
        return UUID().uuidString
    }
} 
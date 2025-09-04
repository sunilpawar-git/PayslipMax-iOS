import Foundation
import PDFKit
import Combine
// Ensure CommonCrypto is available; consider adding it to Package.swift if not implicitly linked
import CommonCrypto

/// Orchestrates the optimized processing of PDF documents by integrating various specialized services.
///
/// This pipeline coordinates text extraction, caching, document analysis, and strategy selection
/// to provide efficient and memory-conscious PDF processing. It automatically chooses
/// between streaming processing for large documents and optimized extraction strategies
/// based on document characteristics.
class OptimizedPDFProcessingPipeline {
    // MARK: - Dependencies
    
    /// Processor responsible for handling large PDFs page-by-page to minimize memory usage.
    private let streamingProcessor: StreamingPDFProcessor
    
    /// Service specialized in extracting text content using various performance-optimized strategies.
    private let textExtractionService: TextExtractionServiceProtocol
    
    /// Caching layer to store and retrieve results of previously processed PDFs, avoiding redundant work.
    private let cache: PDFProcessingCache
    
    /// Service that analyzes PDF documents to determine characteristics like size, layout complexity, and content type.
    private let analysisService: DocumentAnalysisCoordinator
    
    // MARK: - State
    
    /// A Combine subject used to publish progress updates (percentage, status message) during processing.
    private var progressPublisher: PassthroughSubject<(Double, String), Never>
    
    /// Stores active Combine subscriptions to manage their lifecycle.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the optimized processing pipeline with required service dependencies.
    ///
    /// Allows injection of custom implementations for each service, defaulting to standard providers.
    /// - Parameters:
    ///   - streamingProcessor: The processor for handling large PDFs via streaming. Defaults to `StreamingPDFProcessor()`.
    ///   - textExtractionService: The service for optimized text extraction. Defaults to `OptimizedTextExtractionService()`.
    ///   - cache: The cache for storing processed results. Defaults to `PDFProcessingCache.shared`.
    ///   - analysisService: The service for analyzing document characteristics. Defaults to `DocumentAnalysisCoordinator()`.
    init(
        streamingProcessor: StreamingPDFProcessor = StreamingPDFProcessor(),
        textExtractionService: TextExtractionServiceProtocol = TextExtractionService(),
        cache: PDFProcessingCache = PDFProcessingCache.shared,
        analysisService: DocumentAnalysisCoordinator = DocumentAnalysisCoordinator()
    ) {
        self.streamingProcessor = streamingProcessor
        self.textExtractionService = textExtractionService
        self.cache = cache
        self.analysisService = analysisService
        self.progressPublisher = PassthroughSubject<(Double, String), Never>()
    }
    
    // MARK: - Public Methods
    
    /// Processes the given PDF document to extract its text content, utilizing optimized strategies and caching.
    ///
    /// This method first checks the cache. If the document hasn't been processed, it analyzes the document,
    /// selects an appropriate strategy (streaming for large files, specific extraction otherwise),
    /// performs the extraction, caches the result, and returns the text.
    /// Progress updates are published via the `progressPublisher` and can be consumed using the `progressHandler`.
    ///
    /// - Parameters:
    ///   - document: The `PDFDocument` instance to process.
    ///   - progressHandler: An optional closure that receives progress updates (percentage 0.0-1.0, status message).
    ///                      Updates are delivered on the main thread.
    /// - Returns: A string containing the extracted text from the document.
    /// - Throws: An error if the document analysis fails (e.g., cannot read document properties).
    func processDocument(_ document: PDFDocument, progressHandler: ((Double, String) -> Void)? = nil) async throws -> String {
        // Create a unique identifier for the document based on content hash and metadata
        let documentId = generateDocumentId(document)
        
        // Attempt to retrieve the result from cache first
        if let cachedText = cache.retrieveProcessedText(for: documentId) {
            progressHandler?(1.0, "Retrieved from cache") // Report completion if cached
            return cachedText
        }
        
        // Reset cancellables and set up new progress subscription if handler is provided
        cancellables.removeAll()
        if let progressHandler = progressHandler {
            progressPublisher
                .receive(on: DispatchQueue.main) // Ensure handler is called on main thread
                .sink { progress, status in
                    progressHandler(progress, status)
                }
                .store(in: &cancellables)
        }
        
        // Perform document analysis to understand its characteristics
        self.progressPublisher.send((0.1, "Analyzing document structure"))
        let analysisResult = await analysisService.analyzeDocument(document)
        
        // Convert to DocumentAnalysis format for compatibility
        let documentAnalysis = DocumentAnalysis(
            pageCount: analysisResult.pageCount,
            containsScannedContent: analysisResult.hasScannedContent,
            hasComplexLayout: analysisResult.isComplexLayout,
            textDensity: analysisResult.textDensity,
            estimatedMemoryRequirement: analysisResult.estimatedMemoryRequirement,
            containsTables: analysisResult.hasTabularData,
            hasText: analysisResult.textDensity > 0.1,
            imageCount: analysisResult.hasScannedContent ? 1 : 0,
            containsFormElements: analysisResult.hasFormElements
        )
        let optimalStrategy = selectOptimalStrategy(based: documentAnalysis)
        
        // Process the document using the selected strategy
        let extractedText: String
        if documentAnalysis.isLargeDocument {
            // Use memory-optimized streaming for large documents
            self.progressPublisher.send((0.2, "Using streaming processor for large document"))
            // Await the result from the streaming processor
            extractedText = await streamingProcessor.processDocumentStreaming(document) { progress, pageNumber in
                // Scale streaming progress relative to the overall pipeline progress
                let overallProgress = 0.2 + (progress * 0.7) // Streaming takes up 70% of progress after analysis
                self.progressPublisher.send((overallProgress, "Processing page \(pageNumber)"))
            }
        } else {
            // Use the appropriate extraction service for non-large documents
            self.progressPublisher.send((0.3, "Using \(optimalStrategy.rawValue) extraction strategy"))
            // Await the result from the text extraction service
            extractedText = await textExtractionService.extractText(from: document)
            self.progressPublisher.send((0.9, "Text extraction complete"))
        }
        
        // Store the extracted text in the cache for future requests
        self.progressPublisher.send((0.95, "Caching results"))
        _ = cache.storeProcessedText(extractedText, for: documentId)
        
        // Signal completion
        self.progressPublisher.send((1.0, "Processing complete"))
        return extractedText
    }
    
    /// Asynchronously runs performance benchmarks on the provided PDF document using various extraction strategies.
    ///
    /// Simple benchmark placeholder - benchmarking tools were removed during debt reduction
    ///
    /// - Parameter document: The `PDFDocument` to benchmark.
    /// - Returns: Empty array (benchmarking disabled in production)
    func runPerformanceBenchmark(on document: PDFDocument) async -> [String] {
        // Benchmarking tools removed during technical debt reduction
        return []
    }
    
    /// Clears the entire PDF processing cache, removing all stored results.
    func clearCache() {
        _ = cache.clearCache()
    }
    
    // MARK: - Private Helper Methods
    
    /// Generates a reasonably unique identifier for a `PDFDocument` based on its content hash and basic metadata.
    ///
    /// Uses SHA-256 hash of the document's data representation combined with title (if available)
    /// and page count to create the identifier. Falls back to a UUID if data representation fails.
    ///
    /// - Parameter document: The `PDFDocument` instance.
    /// - Returns: A string identifier suitable for use as a cache key.
    private func generateDocumentId(_ document: PDFDocument) -> String {
        // Attempt to get the raw data representation for hashing
        guard let pdfData = document.dataRepresentation() else {
            // Fallback to UUID if data cannot be obtained
            return UUID().uuidString
        }
        
        // Calculate the SHA-256 hash of the PDF content
        let hash = pdfData.sha256Hash()
        
        // Incorporate basic metadata for better uniqueness
        var metadataComponents = [String]()
        if let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
            // Use sanitized title to avoid issues with special characters in keys
            let sanitizedTitle = title.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
            if !sanitizedTitle.isEmpty { metadataComponents.append(sanitizedTitle) }
        }
        
        let pageCount = document.pageCount
        metadataComponents.append("pages\(pageCount)")
        
        // Combine hash and metadata components
        let metadataSuffix = metadataComponents.joined(separator: "_")
        return "\(hash)_\(metadataSuffix)"
    }
    
    /// Selects the most appropriate `PDFExtractionStrategy` based on the results of the document analysis.
    ///
    /// Prioritizes Vision for scanned content, Layout Aware for complex layouts, Fast Text for text-heavy documents,
    /// and Standard as the default fallback.
    ///
    /// - Parameter analysis: The `DocumentAnalysis` result containing document characteristics.
    /// - Returns: The recommended `PDFExtractionStrategy`.
    private func selectOptimalStrategy(based analysis: DocumentAnalysis) -> ExtractionStrategy {
        if analysis.containsScannedContent {
            return .ocrExtraction // Use OCR for scanned images
        } else if analysis.hasComplexLayout {
            return .tableExtraction // Handle complex structures like tables
        } else if analysis.isTextHeavy {
            return .nativeTextExtraction // Optimize for documents primarily containing text
        } else {
            return .hybridExtraction // Default strategy for general cases
        }
    }
}

// MARK: - Data Extension for Hashing

extension Data {
    /// Computes the SHA-256 hash of the data.
    /// - Returns: A hexadecimal string representation of the SHA-256 hash.
    func sha256Hash() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            // Ensure the base address and count are valid before calling CommonCrypto
            guard let baseAddress = buffer.baseAddress, buffer.count > 0 else { return }
            _ = CC_SHA256(baseAddress, CC_LONG(buffer.count), &hash)
        }
        // Convert the hash bytes to a hexadecimal string
        return hash.map { String(format: "%02x", $0) }.joined()
    }
} 
import Foundation
import PDFKit
import Combine

/// A comprehensive pipeline that integrates all optimized PDF processing components
class OptimizedPDFProcessingPipeline {
    // MARK: - Properties
    
    /// The PDF processor for streaming extraction
    private let streamingProcessor: StreamingPDFProcessor
    
    /// The text extraction service
    private let textExtractionService: OptimizedTextExtractionService
    
    /// The caching layer for processed PDFs
    private let cache: PDFProcessingCache
    
    /// Document analysis service
    private let analysisService: DocumentAnalysisService
    
    /// Publisher for processing progress updates
    private var progressPublisher: PassthroughSubject<(Double, String), Never>
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize the pipeline with optional custom components
    /// - Parameters:
    ///   - streamingProcessor: Custom streaming processor or default
    ///   - textExtractionService: Custom text extraction service or default
    ///   - cache: Custom cache or default
    ///   - analysisService: Custom analysis service or default
    init(
        streamingProcessor: StreamingPDFProcessor = StreamingPDFProcessor(),
        textExtractionService: OptimizedTextExtractionService = OptimizedTextExtractionService(),
        cache: PDFProcessingCache = PDFProcessingCache.shared,
        analysisService: DocumentAnalysisService = DocumentAnalysisService()
    ) {
        self.streamingProcessor = streamingProcessor
        self.textExtractionService = textExtractionService
        self.cache = cache
        self.analysisService = analysisService
        self.progressPublisher = PassthroughSubject<(Double, String), Never>()
    }
    
    // MARK: - Public Methods
    
    /// Process a PDF document with optimized performance and memory usage
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressHandler: Optional handler for processing progress
    /// - Returns: The extracted text from the PDF
    func processDocument(_ document: PDFDocument, progressHandler: ((Double, String) -> Void)? = nil) async throws -> String {
        // Create a unique identifier for the document
        let documentId = generateDocumentId(document)
        
        // Check if the document is already cached
        if let cachedText = cache.retrieveProcessedText(for: documentId) {
            progressHandler?(1.0, "Retrieved from cache")
            return cachedText
        }
        
        // Set up progress subscription if handler provided
        if let progressHandler = progressHandler {
            progressPublisher
                .receive(on: DispatchQueue.main)
                .sink { progress, status in
                    progressHandler(progress, status)
                }
                .store(in: &cancellables)
        }
        
        // Analyze document to determine its characteristics
        self.progressPublisher.send((0.1, "Analyzing document structure"))
        let documentAnalysis = try analysisService.analyzeDocument(document)
        let optimalStrategy = selectOptimalStrategy(based: documentAnalysis)
        
        // Process document based on size and complexity
        let extractedText: String
        
        if documentAnalysis.isLargeDocument {
            // Use streaming processing for large documents to optimize memory
            self.progressPublisher.send((0.2, "Using streaming processor for large document"))
            extractedText = await streamingProcessor.processDocumentStreaming(document) { progress, pageNumber in
                let overallProgress = 0.2 + (progress * 0.7)
                self.progressPublisher.send((overallProgress, "Processing page \(pageNumber)"))
            }
        } else {
            // Use optimized extraction service with the determined strategy
            self.progressPublisher.send((0.3, "Using \(optimalStrategy.rawValue) extraction strategy"))
            extractedText = textExtractionService.extractText(from: document, using: optimalStrategy)
            self.progressPublisher.send((0.9, "Text extraction complete"))
        }
        
        // Cache the processed result
        self.progressPublisher.send((0.95, "Caching results"))
        _ = cache.storeProcessedText(extractedText, for: documentId)
        
        self.progressPublisher.send((1.0, "Processing complete"))
        return extractedText
    }
    
    /// Run performance benchmark on the document with all extraction strategies
    /// - Parameters:
    ///   - document: The PDF document to benchmark
    ///   - completion: Callback with benchmark results
    func runPerformanceBenchmark(on document: PDFDocument, completion: @escaping ([PDFBenchmarkingTools.BenchmarkResult]) -> Void) {
        PDFBenchmarkingTools.shared.runComprehensiveBenchmark(on: document, completion: completion)
    }
    
    /// Clear processing cache
    func clearCache() {
        _ = cache.clearCache()
    }
    
    // MARK: - Private Helper Methods
    
    /// Generate a unique identifier for a PDF document
    /// - Parameter document: The PDF document
    /// - Returns: A unique string identifier
    private func generateDocumentId(_ document: PDFDocument) -> String {
        guard let pdfData = document.dataRepresentation() else {
            return UUID().uuidString
        }
        
        let hash = pdfData.sha256Hash()
        
        // Also consider metadata for identification
        var metadataComponents = [String]()
        if let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
            metadataComponents.append(title)
        }
        
        let pageCount = document.pageCount
        metadataComponents.append("pages:\(pageCount)")
        
        return metadataComponents.isEmpty ? hash : "\(hash)_\(metadataComponents.joined(separator: "_"))"
    }
    
    /// Select the optimal extraction strategy based on document analysis
    /// - Parameter analysis: The document analysis result
    /// - Returns: The most suitable extraction strategy
    private func selectOptimalStrategy(based analysis: DocumentAnalysis) -> PDFExtractionStrategy {
        if analysis.containsScannedContent {
            return .vision
        } else if analysis.hasComplexLayout {
            return .layoutAware
        } else if analysis.isTextHeavy {
            return .fastText
        } else {
            return .standard
        }
    }
}

// MARK: - Extensions

extension Data {
    /// Generate SHA-256 hash of the data
    /// - Returns: SHA-256 hash string
    func sha256Hash() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Swift doesn't have CommonCrypto module directly available, so we need to import it
import CommonCrypto 
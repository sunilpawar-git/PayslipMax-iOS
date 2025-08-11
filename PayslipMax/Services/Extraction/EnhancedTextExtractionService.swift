import Foundation
import PDFKit
import Combine

// Import extracted data models
// Note: TextExtractionModels provides ExtractionOptions and ExtractionMetrics

/// Protocol for the enhanced text extraction service
protocol EnhancedTextExtractionServiceProtocol {
    /// Extracts text from a PDF document with optimized performance
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - options: Options to configure the extraction process
    /// - Returns: The extracted text and performance metrics
    func extractTextEnhanced(from document: PDFDocument, options: ExtractionOptions) async -> (text: String, metrics: ExtractionMetrics)
    
    /// Extracts text from a PDF document using the most appropriate strategy based on document characteristics
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text and performance metrics
    func extractTextWithOptimalStrategy(from document: PDFDocument) async -> (text: String, metrics: ExtractionMetrics)
    
    /// Gets performance metrics for the last extraction operation
    /// - Returns: Performance metrics for the extraction process
    func getPerformanceMetrics() -> ExtractionMetrics
}

/// Enhanced text extraction service coordinator that orchestrates specialized extraction engines
/// based on document characteristics and performance requirements.
///
/// This service acts as the primary coordinator, delegating extraction tasks to:
/// - ParallelTextExtractor: For concurrent multi-page processing
/// - SequentialTextExtractor: For memory-efficient sequential processing
/// - ExtractionDocumentAnalyzer: For automatic strategy selection
/// - ExtractionMemoryManager: For memory optimization decisions
///
/// Supports caching, streaming for large documents, and comprehensive performance metrics.
class EnhancedTextExtractionService: EnhancedTextExtractionServiceProtocol {
    // MARK: - Dependencies
    
    /// Text extraction service for standard extraction
    private let textExtractionService: TextExtractionServiceProtocol
    
    /// PDF text extraction service for detailed extraction
    private let pdfTextExtractionService: PDFTextExtractionServiceProtocol
    
    /// Streaming processor for handling large documents
    private let streamingProcessor: StreamingPDFProcessor
    
    /// Caching layer for processed results
    private let textCache: PDFProcessingCache
    
    /// Operation queue for parallel processing
    private let extractionQueue: OperationQueue
    
    // MARK: - Extracted Engines
    
    /// Parallel text extraction engine
    private let parallelExtractor: ParallelTextExtractor
    
    /// Sequential text extraction engine
    private let sequentialExtractor: SequentialTextExtractor
    
    /// Document analyzer for extraction optimization
    private let documentAnalyzer: ExtractionDocumentAnalyzer
    
    /// Memory management service
    private let memoryManager: ExtractionMemoryManager
    
    // MARK: - State
    
    /// Performance metrics for the last extraction operation
    private var lastMetrics: ExtractionMetrics = ExtractionMetrics()
    
    /// Subject for tracking extraction progress
    private let progressSubject = PassthroughSubject<(pageIndex: Int, progress: Double), Never>()
    
    /// Cancellables bag for storing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the enhanced text extraction service coordinator
    /// - Parameters:
    ///   - textExtractionService: The standard text extraction service
    ///   - pdfTextExtractionService: The PDF text extraction service for detailed extraction
    ///   - streamingProcessor: The streaming processor for large documents
    ///   - textCache: The cache for storing extracted text
    init(
        textExtractionService: TextExtractionServiceProtocol? = nil,
        pdfTextExtractionService: PDFTextExtractionServiceProtocol? = nil,
        streamingProcessor: StreamingPDFProcessor? = nil,
        textCache: PDFProcessingCache? = nil
    ) {
        self.textExtractionService = textExtractionService ?? TextExtractionService()
        self.pdfTextExtractionService = pdfTextExtractionService ?? PDFTextExtractionService()
        self.streamingProcessor = streamingProcessor ?? StreamingPDFProcessor()
        self.textCache = textCache ?? PDFProcessingCache.shared
        
        // Configure extraction queue for parallel processing
        self.extractionQueue = OperationQueue()
        self.extractionQueue.name = "com.payslipmax.textextraction"
        self.extractionQueue.maxConcurrentOperationCount = DeviceClass.current.parallelismCap
        self.extractionQueue.qualityOfService = .userInitiated
        
        // Initialize extracted engines
        self.memoryManager = ExtractionMemoryManager()
        self.documentAnalyzer = ExtractionDocumentAnalyzer()
        self.parallelExtractor = ParallelTextExtractor(
            extractionQueue: self.extractionQueue,
            textPreprocessor: TextPreprocessor(),
            progressSubject: self.progressSubject
        )
        self.sequentialExtractor = SequentialTextExtractor(
            textPreprocessor: TextPreprocessor(),
            progressSubject: self.progressSubject,
            memoryManager: self.memoryManager
        )
        
        // Set up progress tracking
        setupProgressTracking()

        // Respond to system memory pressure by adjusting concurrency
        NotificationCenter.default.addObserver(forName: NSNotification.Name("MemoryPressureHigh"), object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.extractionQueue.maxConcurrentOperationCount = max(1, DeviceClass.current.parallelismCap / 2)
            print("[EnhancedTextExtractionService] Memory pressure detected; reducing parallelism to \(self.extractionQueue.maxConcurrentOperationCount)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Extracts text from a PDF document with optimized performance
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - options: Options to configure the extraction process
    /// - Returns: The extracted text and performance metrics
    func extractTextEnhanced(from document: PDFDocument, options: ExtractionOptions = ExtractionOptions()) async -> (text: String, metrics: ExtractionMetrics) {
        // Start timing execution
        let startTime = Date()
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Initialize metrics
        var metrics = ExtractionMetrics()
        metrics.pagesProcessed = document.pageCount
        metrics.usedParallelProcessing = options.useParallelProcessing
        metrics.usedTextPreprocessing = options.preprocessText
        
        // Check cache first if enabled
        if options.useCache {
            let cacheKey = document.uniqueCacheKey()
            if let cachedText = textCache.retrieve(forKey: cacheKey) as String? {
                print("[EnhancedTextExtractionService] Using cached text for document")
                
                // Update metrics
                metrics.executionTime = Date().timeIntervalSince(startTime)
                metrics.cacheHitRatio = 1.0
                metrics.charactersExtracted = cachedText.count
                
                lastMetrics = metrics
                return (cachedText, metrics)
            }
        }
        
        // Check if memory optimization should be used
        let shouldUseMemoryOptimization = memoryManager.shouldUseMemoryOptimization(for: document, thresholdMB: options.memoryThresholdMB)
        
        if shouldUseMemoryOptimization {
            let estimatedMemoryRequirement = memoryManager.estimateMemoryRequirement(for: document)
            print("[EnhancedTextExtractionService] Using memory optimization for large document (\(memoryManager.formatMemory(estimatedMemoryRequirement)))")
            metrics.memoryOptimizationTriggered = true
            
            // Use streaming processor for memory-efficient processing
            let extractedText = await streamingProcessor.processDocumentStreaming(document) { progress, pageText in
                // Report progress
                self.progressSubject.send((pageIndex: Int(progress * Double(document.pageCount)), progress: progress))
            }
            
            // Update metrics
            let endTime = Date()
            let endMemory = memoryManager.getCurrentMemoryUsage()
            
            metrics.executionTime = endTime.timeIntervalSince(startTime)
            metrics.peakMemoryUsage = max(initialMemory, endMemory) - min(initialMemory, endMemory)
            metrics.charactersExtracted = extractedText.count
            
            // Cache the result if enabled
            if options.useCache {
                let _ = textCache.store(extractedText, forKey: document.uniqueCacheKey())
            }
            
            lastMetrics = metrics
            return (extractedText, metrics)
        } else {
            // Delegate to appropriate extraction engine
            let result = options.useParallelProcessing ?
                await parallelExtractor.extractTextParallel(from: document, options: options, metrics: &metrics) :
                await sequentialExtractor.extractTextSequential(from: document, options: options, metrics: &metrics)
            
            // Update final metrics
            let endTime = Date()
            metrics.executionTime = endTime.timeIntervalSince(startTime)
            metrics.charactersExtracted = result.count
            
            // Cache the result if enabled
            if options.useCache {
                let _ = textCache.store(result, forKey: document.uniqueCacheKey())
            }
            
            lastMetrics = metrics
            return (result, metrics)
        }
    }
    
    /// Extracts text from a PDF document using the most appropriate strategy based on document characteristics
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text and performance metrics
    func extractTextWithOptimalStrategy(from document: PDFDocument) async -> (text: String, metrics: ExtractionMetrics) {
        // Delegate to document analyzer for optimal strategy selection
        let options = documentAnalyzer.recommendOptimalExtractionOptions(for: document)
        return await extractTextEnhanced(from: document, options: options)
    }
    
    /// Gets the performance metrics from the last extraction operation
    /// - Returns: Performance metrics
    func getPerformanceMetrics() -> ExtractionMetrics {
        return lastMetrics
    }
    
    // MARK: - Private Methods
    
    /// Sets up progress tracking subscription
    private func setupProgressTracking() {
        progressSubject
            .sink { pageInfo in
                print("[EnhancedTextExtractionService] Processing page \(pageInfo.pageIndex), progress: \(Int(pageInfo.progress * 100))%")
            }
            .store(in: &cancellables)
    }
} 
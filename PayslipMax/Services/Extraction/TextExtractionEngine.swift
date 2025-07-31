import Foundation
import PDFKit
import Combine

/// Protocol for the core text extraction engine
protocol TextExtractionEngineProtocol {
    /// Executes text extraction using the specified strategy and options
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - strategy: The extraction strategy to use
    ///   - options: Configuration options for extraction
    /// - Returns: The extracted text and performance metrics
    func executeExtraction(
        from document: PDFDocument,
        using strategy: TextExtractionStrategy,
        options: ExtractionOptions
    ) async -> TextExtractionResult
    
    /// Gets the current extraction progress
    /// - Returns: Progress publisher for real-time updates
    func getProgressPublisher() -> AnyPublisher<ExtractionProgress, Never>
}

/// Core text extraction engine that orchestrates the extraction process
///
/// This engine serves as the central coordinator for text extraction operations,
/// managing the execution flow between different extraction strategies and handling
/// cross-cutting concerns like caching, memory management, and progress tracking.
///
/// ## Responsibilities:
/// - Orchestrating extraction execution based on selected strategy
/// - Managing extraction lifecycle (start, progress, completion)
/// - Coordinating with caching and memory management systems
/// - Providing real-time progress updates
/// - Handling extraction errors and recovery
///
/// ## Architecture:
/// The engine follows a strategy pattern, delegating actual extraction work to
/// specialized extractors while managing the overall process flow.
class TextExtractionEngine: TextExtractionEngineProtocol {
    
    // MARK: - Dependencies
    
    /// Parallel text extraction engine
    private let parallelExtractor: ParallelTextExtractor
    
    /// Sequential text extraction engine
    private let sequentialExtractor: SequentialTextExtractor
    
    /// Streaming processor for memory-efficient processing
    private let streamingProcessor: StreamingPDFProcessor
    
    /// Caching layer for processed results
    private let textCache: PDFProcessingCache
    
    /// Memory management service
    private let memoryManager: TextExtractionMemoryManager
    
    // MARK: - State Management
    
    /// Subject for tracking extraction progress
    private let progressSubject = PassthroughSubject<ExtractionProgress, Never>()
    
    /// Current extraction session metrics
    private var currentMetrics: ExtractionMetrics = ExtractionMetrics()
    
    /// Cancellables bag for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the text extraction engine with required dependencies
    /// - Parameters:
    ///   - parallelExtractor: Engine for parallel text extraction
    ///   - sequentialExtractor: Engine for sequential text extraction
    ///   - streamingProcessor: Processor for memory-efficient streaming
    ///   - textCache: Cache for storing extraction results
    ///   - memoryManager: Manager for memory optimization decisions
    init(
        parallelExtractor: ParallelTextExtractor,
        sequentialExtractor: SequentialTextExtractor,
        streamingProcessor: StreamingPDFProcessor,
        textCache: PDFProcessingCache,
        memoryManager: TextExtractionMemoryManager
    ) {
        self.parallelExtractor = parallelExtractor
        self.sequentialExtractor = sequentialExtractor
        self.streamingProcessor = streamingProcessor
        self.textCache = textCache
        self.memoryManager = memoryManager
        
        setupProgressTracking()
    }
    
    // MARK: - Core Extraction
    
    /// Executes text extraction using the specified strategy and options
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - strategy: The extraction strategy to use
    ///   - options: Configuration options for extraction
    /// - Returns: The extracted text and performance metrics
    func executeExtraction(
        from document: PDFDocument,
        using strategy: TextExtractionStrategy,
        options: ExtractionOptions
    ) async -> TextExtractionResult {
        // Initialize extraction session
        let startTime = Date()
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Reset and configure metrics
        currentMetrics = ExtractionMetrics()
        currentMetrics.pagesProcessed = document.pageCount
        currentMetrics.usedParallelProcessing = strategy.requiresParallelProcessing
        currentMetrics.usedTextPreprocessing = options.preprocessText
        
        // Emit initial progress
        emitProgress(ExtractionProgress(
            pageIndex: 0,
            totalPages: document.pageCount,
            progress: 0.0,
            phase: .initialization
        ))
        
        do {
            // Check cache first if enabled
            if let cachedResult = await checkCache(for: document, options: options) {
                currentMetrics.cacheHitRatio = 1.0
                currentMetrics.executionTime = Date().timeIntervalSince(startTime)
                
                return TextExtractionResult(
                    text: cachedResult,
                    metrics: currentMetrics,
                    success: true,
                    error: nil
                )
            }
            
            // Execute extraction based on strategy
            let extractedText = try await performExtraction(
                from: document,
                using: strategy,
                options: options
            )
            
            // Finalize metrics
            let endTime = Date()
            let endMemory = memoryManager.getCurrentMemoryUsage()
            
            currentMetrics.executionTime = endTime.timeIntervalSince(startTime)
            currentMetrics.peakMemoryUsage = max(initialMemory, endMemory) - min(initialMemory, endMemory)
            currentMetrics.charactersExtracted = extractedText.count
            
            // Cache result if enabled
            if options.useCache {
                await cacheResult(extractedText, for: document)
            }
            
            // Emit completion progress
            emitProgress(ExtractionProgress(
                pageIndex: document.pageCount,
                totalPages: document.pageCount,
                progress: 1.0,
                phase: .completed
            ))
            
            return TextExtractionResult(
                text: extractedText,
                metrics: currentMetrics,
                success: true,
                error: nil
            )
            
        } catch {
            // Handle extraction errors
            let errorResult = handleExtractionError(error, startTime: startTime)
            
            emitProgress(ExtractionProgress(
                pageIndex: 0,
                totalPages: document.pageCount,
                progress: 0.0,
                phase: .error
            ))
            
            return errorResult
        }
    }
    
    /// Gets the current extraction progress publisher
    /// - Returns: Progress publisher for real-time updates
    func getProgressPublisher() -> AnyPublisher<ExtractionProgress, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Performs the actual extraction based on the selected strategy
    /// - Parameters:
    ///   - document: The PDF document to extract from
    ///   - strategy: The extraction strategy to use
    ///   - options: Configuration options
    /// - Returns: The extracted text
    /// - Throws: ExtractionError if extraction fails
    private func performExtraction(
        from document: PDFDocument,
        using strategy: TextExtractionStrategy,
        options: ExtractionOptions
    ) async throws -> String {
        
        // Emit processing start
        emitProgress(ExtractionProgress(
            pageIndex: 0,
            totalPages: document.pageCount,
            progress: 0.1,
            phase: .processing
        ))
        
        switch strategy {
        case .parallel:
            return try await executeParallelExtraction(from: document, options: options)
            
        case .sequential:
            return try await executeSequentialExtraction(from: document, options: options)
            
        case .streaming:
            return try await executeStreamingExtraction(from: document, options: options)
            
        case .adaptive:
            // Determine optimal approach based on document characteristics
            let shouldUseMemoryOptimization = memoryManager.shouldUseMemoryOptimization(
                for: document,
                thresholdMB: options.memoryThresholdMB
            )
            
            if shouldUseMemoryOptimization {
                currentMetrics.memoryOptimizationTriggered = true
                return try await executeStreamingExtraction(from: document, options: options)
            } else {
                return options.useParallelProcessing ?
                    try await executeParallelExtraction(from: document, options: options) :
                    try await executeSequentialExtraction(from: document, options: options)
            }
        }
    }
    
    /// Executes parallel text extraction
    /// - Parameters:
    ///   - document: The PDF document to extract from
    ///   - options: Configuration options
    /// - Returns: The extracted text
    /// - Throws: ExtractionError if extraction fails
    private func executeParallelExtraction(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async throws -> String {
        var metrics = currentMetrics
        let result = await parallelExtractor.extractTextParallel(
            from: document,
            options: options,
            metrics: &metrics
        )
        currentMetrics = metrics
        return result
    }
    
    /// Executes sequential text extraction
    /// - Parameters:
    ///   - document: The PDF document to extract from
    ///   - options: Configuration options
    /// - Returns: The extracted text
    /// - Throws: ExtractionError if extraction fails
    private func executeSequentialExtraction(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async throws -> String {
        var metrics = currentMetrics
        let result = await sequentialExtractor.extractTextSequential(
            from: document,
            options: options,
            metrics: &metrics
        )
        currentMetrics = metrics
        return result
    }
    
    /// Executes streaming text extraction for memory efficiency
    /// - Parameters:
    ///   - document: The PDF document to extract from
    ///   - options: Configuration options
    /// - Returns: The extracted text
    /// - Throws: ExtractionError if extraction fails
    private func executeStreamingExtraction(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async throws -> String {
        return await streamingProcessor.processDocumentStreaming(document) { progress, pageText in
            self.emitProgress(ExtractionProgress(
                pageIndex: Int(progress * Double(document.pageCount)),
                totalPages: document.pageCount,
                progress: progress,
                phase: .processing
            ))
        }
    }
    
    /// Checks cache for existing extraction results
    /// - Parameters:
    ///   - document: The PDF document to check
    ///   - options: Configuration options
    /// - Returns: Cached text if available, nil otherwise
    private func checkCache(for document: PDFDocument, options: ExtractionOptions) async -> String? {
        guard options.useCache else { return nil }
        
        let cacheKey = document.uniqueCacheKey()
        return textCache.retrieve(forKey: cacheKey) as String?
    }
    
    /// Caches the extraction result
    /// - Parameters:
    ///   - text: The extracted text to cache
    ///   - document: The source PDF document
    private func cacheResult(_ text: String, for document: PDFDocument) async {
        let cacheKey = document.uniqueCacheKey()
        let _ = textCache.store(text, forKey: cacheKey)
    }
    
    /// Handles extraction errors and creates error result
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - startTime: When extraction started
    /// - Returns: Error result with metrics
    private func handleExtractionError(_ error: Error, startTime: Date) -> TextExtractionResult {
        currentMetrics.executionTime = Date().timeIntervalSince(startTime)
        
        return TextExtractionResult(
            text: "",
            metrics: currentMetrics,
            success: false,
            error: error
        )
    }
    
    /// Sets up progress tracking subscription
    private func setupProgressTracking() {
        progressSubject
            .sink { progress in
                print("[TextExtractionEngine] Page \(progress.pageIndex)/\(progress.totalPages), \(Int(progress.progress * 100))% - \(progress.phase)")
            }
            .store(in: &cancellables)
    }
    
    /// Emits progress update
    /// - Parameter progress: The progress information to emit
    private func emitProgress(_ progress: ExtractionProgress) {
        progressSubject.send(progress)
    }
}

// MARK: - Supporting Models

/// Text extraction engine strategy options
enum TextExtractionStrategy {
    /// Use parallel processing for optimal performance
    case parallel
    /// Use sequential processing for memory efficiency
    case sequential
    /// Use streaming processing for very large documents
    case streaming
    /// Adaptive strategy based on document characteristics
    case adaptive
    
    /// Whether this strategy requires parallel processing
    var requiresParallelProcessing: Bool {
        switch self {
        case .parallel, .adaptive:
            return true
        case .sequential, .streaming:
            return false
        }
    }
}

/// Progress information during extraction
struct ExtractionProgress {
    /// Current page being processed
    let pageIndex: Int
    /// Total number of pages
    let totalPages: Int
    /// Progress as a value between 0.0 and 1.0
    let progress: Double
    /// Current extraction phase
    let phase: ExtractionPhase
}

/// Phases of the extraction process
enum ExtractionPhase {
    /// Initializing extraction
    case initialization
    /// Processing pages
    case processing
    /// Extraction completed successfully
    case completed
    /// Error occurred during extraction
    case error
}

/// Result of text extraction engine operation
struct TextExtractionResult {
    /// The extracted text
    let text: String
    /// Performance metrics
    let metrics: ExtractionMetrics
    /// Whether extraction was successful
    let success: Bool
    /// Error information if extraction failed
    let error: Error?
}

/// Text extraction memory manager placeholder (to be implemented separately)
class TextExtractionMemoryManager {
    func getCurrentMemoryUsage() -> UInt64 {
        // Implementation would go here
        return 0
    }
    
    func shouldUseMemoryOptimization(for document: PDFDocument, thresholdMB: Int) -> Bool {
        // Implementation would go here
        return false
    }
    
    func getAvailableMemory() -> UInt64 {
        // Implementation would go here
        return 1024 * 1024 * 1024 // 1GB placeholder
    }
    
    func estimateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        // Implementation would go here
        return UInt64(document.pageCount * 10 * 1024 * 1024) // 10MB per page placeholder
    }
}
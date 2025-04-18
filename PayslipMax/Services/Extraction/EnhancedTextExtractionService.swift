import Foundation
import PDFKit
import Combine

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

/// Options for configuring the text extraction process
struct ExtractionOptions {
    /// Whether to use parallel processing for non-sequential pages
    var useParallelProcessing: Bool = true
    
    /// Maximum number of concurrent operations for parallel processing
    var maxConcurrentOperations: Int = 4
    
    /// Whether to preprocess text for better quality
    var preprocessText: Bool = true
    
    /// Whether to use adaptive batching based on page characteristics
    var useAdaptiveBatching: Bool = true
    
    /// Maximum batch size in bytes
    var maxBatchSize: Int = 5 * 1024 * 1024 // 5MB
    
    /// Whether to collect detailed performance metrics
    var collectDetailedMetrics: Bool = true
    
    /// Whether to use the cache
    var useCache: Bool = true
    
    /// Memory threshold in MB for triggering memory optimization
    var memoryThresholdMB: Int = 200
    
    /// Default extraction options
    static var `default`: ExtractionOptions {
        return ExtractionOptions()
    }
    
    /// Options optimized for speed
    static var speed: ExtractionOptions {
        var options = ExtractionOptions()
        options.preprocessText = false
        options.maxConcurrentOperations = 8
        return options
    }
    
    /// Options optimized for quality
    static var quality: ExtractionOptions {
        var options = ExtractionOptions()
        options.preprocessText = true
        options.useParallelProcessing = false
        return options
    }
    
    /// Options optimized for memory efficiency
    static var memoryEfficient: ExtractionOptions {
        var options = ExtractionOptions()
        options.useParallelProcessing = false
        options.useAdaptiveBatching = true
        options.memoryThresholdMB = 100
        return options
    }
}

/// Performance metrics for the extraction process
struct ExtractionMetrics {
    /// Total execution time in seconds
    var executionTime: TimeInterval = 0
    
    /// Peak memory usage in bytes
    var peakMemoryUsage: UInt64 = 0
    
    /// Number of pages processed
    var pagesProcessed: Int = 0
    
    /// Number of characters extracted
    var charactersExtracted: Int = 0
    
    /// Processing time per page in seconds
    var processingTimePerPage: [Int: TimeInterval] = [:]
    
    /// Memory usage per page in bytes
    var memoryUsagePerPage: [Int: UInt64] = [:]
    
    /// Cache hit ratio (0.0-1.0)
    var cacheHitRatio: Double = 0.0
    
    /// Whether parallel processing was used
    var usedParallelProcessing: Bool = false
    
    /// Whether text preprocessing was used
    var usedTextPreprocessing: Bool = false
    
    /// Number of extraction retries due to errors
    var extractionRetries: Int = 0
    
    /// Whether memory optimization was triggered
    var memoryOptimizationTriggered: Bool = false
}

/// Service for enhanced text extraction with optimized performance
class EnhancedTextExtractionService: EnhancedTextExtractionServiceProtocol {
    // MARK: - Properties
    
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
    
    /// Performance metrics for the last extraction operation
    private var lastMetrics: ExtractionMetrics = ExtractionMetrics()
    
    /// Subject for tracking extraction progress
    private let progressSubject = PassthroughSubject<(pageIndex: Int, progress: Double), Never>()
    
    /// Cancellables bag for storing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes an EnhancedTextExtractionService with custom parameters
    /// - Parameters:
    ///   - textExtractionService: The standard text extraction service
    ///   - pdfTextExtractionService: The PDF text extraction service
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
        self.extractionQueue.maxConcurrentOperationCount = 4
        self.extractionQueue.qualityOfService = .userInitiated
        
        // Set up progress tracking
        setupProgressTracking()
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
        let initialMemory = getCurrentMemoryUsage()
        
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
        let estimatedMemoryRequirement = estimateMemoryRequirement(for: document)
        let shouldUseMemoryOptimization = estimatedMemoryRequirement > UInt64(options.memoryThresholdMB * 1024 * 1024)
        
        if shouldUseMemoryOptimization {
            print("[EnhancedTextExtractionService] Using memory optimization for large document (\(formatMemory(estimatedMemoryRequirement)))")
            metrics.memoryOptimizationTriggered = true
            
            // Use streaming processor for memory-efficient processing
            let extractedText = await streamingProcessor.processDocumentStreaming(document) { progress, pageText in
                // Report progress
                self.progressSubject.send((pageIndex: Int(progress * Double(document.pageCount)), progress: progress))
            }
            
            // Update metrics
            let endTime = Date()
            let endMemory = getCurrentMemoryUsage()
            
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
            // Use parallel or sequential processing based on options
            let result = options.useParallelProcessing ?
                await extractTextParallel(from: document, options: options, metrics: &metrics) :
                await extractTextSequential(from: document, options: options, metrics: &metrics)
            
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
        // Analyze the document to determine characteristics
        let analysis = analyzeDocument(document)
        
        // Choose the optimal extraction options based on document analysis
        var options = ExtractionOptions()
        
        if analysis.hasScannedContent {
            // For scanned content, use OCR-appropriate settings
            options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: 2,
                preprocessText: true,
                useAdaptiveBatching: true,
                maxBatchSize: 2 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 300
            )
        } else if analysis.isLargeDocument {
            // For large documents, use memory-efficient settings
            options = ExtractionOptions(
                useParallelProcessing: false,
                maxConcurrentOperations: 1,
                preprocessText: false,
                useAdaptiveBatching: true,
                maxBatchSize: 1 * 1024 * 1024,
                collectDetailedMetrics: false,
                useCache: true,
                memoryThresholdMB: 100
            )
        } else if analysis.hasComplexLayout {
            // For complex layouts, use layout-aware settings
            options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: 4,
                preprocessText: true,
                useAdaptiveBatching: true,
                maxBatchSize: 3 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 200
            )
        } else if analysis.isTextHeavy {
            // For text-heavy documents, use standard settings
            options = ExtractionOptions()
        }
        
        return await extractTextEnhanced(from: document, options: options)
    }
    
    /// Gets the performance metrics from the last extraction operation
    /// - Returns: Performance metrics
    func getPerformanceMetrics() -> ExtractionMetrics {
        return lastMetrics
    }
    
    // MARK: - Private Methods - Extraction
    
    /// Extract text from a document using parallel processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - options: Extraction options
    ///   - metrics: Metrics to update
    /// - Returns: The extracted text
    private func extractTextParallel(from document: PDFDocument, options: ExtractionOptions, metrics: inout ExtractionMetrics) async -> String {
        print("[EnhancedTextExtractionService] Using parallel processing with \(options.maxConcurrentOperations) concurrent operations")
        
        // Configure extraction queue
        extractionQueue.maxConcurrentOperationCount = options.maxConcurrentOperations
        
        // Create a task group for parallel processing
        var pageTexts = [Int: String]()
        let pageCount = document.pageCount
        
        await withTaskGroup(of: (Int, String).self) { group in
            // Add a task for each page
            for pageIndex in 0..<pageCount {
                group.addTask {
                    // Extract text from page
                    let page = document.page(at: pageIndex)!
                    let pageText = page.string ?? ""
                    
                    // Apply preprocessing if enabled
                    let finalText = options.preprocessText ? self.preprocessText(pageText) : pageText
                    
                    // Report progress
                    let progress = Double(pageIndex + 1) / Double(pageCount)
                    self.progressSubject.send((pageIndex: pageIndex, progress: progress))
                    
                    return (pageIndex, finalText)
                }
            }
            
            // Collect results
            for await (pageIndex, pageText) in group {
                pageTexts[pageIndex] = pageText
            }
        }
        
        // Combine page texts in correct order
        var combinedText = ""
        for pageIndex in 0..<pageCount {
            if let pageText = pageTexts[pageIndex] {
                combinedText += pageText
                if pageIndex < pageCount - 1 {
                    combinedText += "\n\n"
                }
            }
        }
        
        return combinedText
    }
    
    /// Extract text from a document using sequential processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - options: Extraction options
    ///   - metrics: Metrics to update
    /// - Returns: The extracted text
    private func extractTextSequential(from document: PDFDocument, options: ExtractionOptions, metrics: inout ExtractionMetrics) async -> String {
        print("[EnhancedTextExtractionService] Using sequential processing")
        
        var combinedText = ""
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            let startTime = Date()
            let startMemory = getCurrentMemoryUsage()
            
            // Use autorelease pool to manage memory
            autoreleasepool {
                // Extract text from page
                let page = document.page(at: pageIndex)!
                let pageText = page.string ?? ""
                
                // Apply preprocessing if enabled
                let finalText = options.preprocessText ? preprocessText(pageText) : pageText
                
                // Add to combined text
                combinedText += finalText
                if pageIndex < pageCount - 1 {
                    combinedText += "\n\n"
                }
                
                // Calculate metrics
                let endTime = Date()
                let endMemory = getCurrentMemoryUsage()
                let processingTime = endTime.timeIntervalSince(startTime)
                let memoryUsage = endMemory - startMemory
                
                metrics.processingTimePerPage[pageIndex] = processingTime
                metrics.memoryUsagePerPage[pageIndex] = memoryUsage
                
                // Report progress
                let progress = Double(pageIndex + 1) / Double(pageCount)
                progressSubject.send((pageIndex: pageIndex, progress: progress))
            }
        }
        
        return combinedText
    }
    
    // MARK: - Helper Methods
    
    /// Set up progress tracking for extraction operations
    private func setupProgressTracking() {
        progressSubject
            .sink { pageInfo in
                print("[EnhancedTextExtractionService] Processing page \(pageInfo.pageIndex), progress: \(Int(pageInfo.progress * 100))%")
            }
            .store(in: &cancellables)
    }
    
    /// Preprocess text to improve quality
    /// - Parameter text: The raw text to process
    /// - Returns: Processed text
    private func preprocessText(_ text: String) -> String {
        // Basic text cleanup
        var processedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // Remove duplicate line breaks
        while processedText.contains("\n\n\n") {
            processedText = processedText.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // Trim whitespace
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
    
    /// Get current memory usage
    /// - Returns: Memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            withUnsafeMutablePointer(to: &count) { countPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    task_info_t(OpaquePointer(infoPtr)),
                    countPtr
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    /// Format memory size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string
    private func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
    
    /// Estimate memory requirement for processing a document
    /// - Parameter document: The PDF document
    /// - Returns: Estimated memory requirement in bytes
    private func estimateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        // Basic heuristic: estimate based on page count and size
        let pageCount = document.pageCount
        let averagePageSize: UInt64 = 1_000_000 // 1MB per page as base estimate
        
        // Sample a few pages to refine the estimate
        var totalSize: UInt64 = 0
        let sampleSize = min(pageCount, 5)
        
        for i in 0..<sampleSize {
            if let page = document.page(at: i), let pageText = page.string {
                totalSize += UInt64(pageText.count * 2) // Unicode chars are 2 bytes
            } else {
                totalSize += averagePageSize
            }
        }
        
        let avgSampleSize = sampleSize > 0 ? totalSize / UInt64(sampleSize) : averagePageSize
        let estimatedSize = avgSampleSize * UInt64(pageCount)
        
        // Add overhead for processing
        let overhead: UInt64 = 50_000_000 // 50MB overhead
        return estimatedSize + overhead
    }
    
    /// Analyze a document to determine its characteristics
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document analysis results
    private func analyzeDocument(_ document: PDFDocument) -> PayslipMax.DocumentAnalysis {
        let analysisService = PayslipMax.DocumentAnalysisService()
        
        do {
            return try analysisService.analyzeDocument(document)
        } catch {
            print("[EnhancedTextExtractionService] Error analyzing document: \(error)")
            // Return default analysis if analysis fails
            return PayslipMax.DocumentAnalysis(
                pageCount: document.pageCount,
                containsScannedContent: false,
                hasComplexLayout: false,
                textDensity: 0.5,
                estimatedMemoryRequirement: 0,
                containsTables: false,
                containsFormElements: false
            )
        }
    }
    
    /// Check if a document contains scanned content
    /// - Parameter document: The PDF document to check
    /// - Returns: True if the document contains scanned content
    private func detectScannedContent(in document: PDFDocument) -> Bool {
        // Basic heuristic: check text density
        var totalChars = 0
        let pageCount = document.pageCount
        
        for pageIndex in 0..<min(pageCount, 5) {
            if let page = document.page(at: pageIndex), let pageText = page.string {
                totalChars += pageText.count
            }
        }
        
        let avgCharsPerPage = pageCount > 0 ? Double(totalChars) / Double(min(pageCount, 5)) : 0
        let containsScannedContent = avgCharsPerPage < 500 // Threshold for scanned content
        
        return containsScannedContent
    }
}

// No need for ExtractionOptions extension at the end - static members are already defined in the struct 
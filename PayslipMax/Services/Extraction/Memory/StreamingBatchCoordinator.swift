import Foundation
import PDFKit
import Combine

/// Streaming batch coordinator for memory-efficient PDF processing
///
/// Following Phase 4B modular pattern: Focused responsibility for batch coordination
/// Orchestrates memory-aware streaming processing with adaptive batch sizing
class StreamingBatchCoordinator {
    
    // MARK: - Configuration
    
    /// Batch processing configuration
    private struct BatchConfiguration {
        let maxBatchSize: Int
        let minBatchSize: Int = 1
        let maxConcurrentBatches: Int
        let memoryThreshold: UInt64
        
        init(maxBatchSize: Int = 10, maxConcurrentBatches: Int = 2, memoryThreshold: UInt64 = 200 * 1024 * 1024) {
            self.maxBatchSize = maxBatchSize
            self.maxConcurrentBatches = maxConcurrentBatches
            self.memoryThreshold = memoryThreshold
        }
    }
    
    /// Processing result for a batch
    struct BatchResult {
        let batchIndex: Int
        let pageRange: Range<Int>
        let extractedText: String
        let processingTime: TimeInterval
        let memoryUsed: UInt64
    }
    
    /// Progress information
    struct ProcessingProgress {
        let completedPages: Int
        let totalPages: Int
        let currentBatch: Int
        let totalBatches: Int
        let estimatedTimeRemaining: TimeInterval
        
        var percentage: Double {
            guard totalPages > 0 else { return 0.0 }
            return Double(completedPages) / Double(totalPages)
        }
    }
    
    // MARK: - Dependencies
    
    /// Resource pressure monitor for adaptive processing
    private let pressureMonitor: ResourcePressureMonitor
    
    /// Memory optimized extractor for text processing
    private let memoryExtractor: MemoryOptimizedExtractor
    
    /// Adaptive cache manager for result caching
    private let cacheManager: AdaptiveCacheManager
    
    // MARK: - State
    
    /// Current batch configuration
    private var configuration: BatchConfiguration
    
    /// Progress tracking
    private let progressSubject = PassthroughSubject<ProcessingProgress, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize streaming batch coordinator with default components
    init() {
        self.pressureMonitor = ResourcePressureMonitor()
        self.memoryExtractor = MemoryOptimizedExtractor()
        self.cacheManager = AdaptiveCacheManager()
        self.configuration = BatchConfiguration()
    }
    
    /// Initialize streaming batch coordinator
    /// - Parameters:
    ///   - pressureMonitor: Resource pressure monitor instance
    ///   - memoryExtractor: Memory optimized extractor instance
    ///   - cacheManager: Adaptive cache manager instance
    ///   - configuration: Initial batch configuration
    private init(
        pressureMonitor: ResourcePressureMonitor = ResourcePressureMonitor(),
        memoryExtractor: MemoryOptimizedExtractor = MemoryOptimizedExtractor(),
        cacheManager: AdaptiveCacheManager = AdaptiveCacheManager(),
        configuration: BatchConfiguration = BatchConfiguration()
    ) {
        self.pressureMonitor = pressureMonitor
        self.memoryExtractor = memoryExtractor
        self.cacheManager = cacheManager
        self.configuration = configuration
    }
    
    // MARK: - Streaming Processing
    
    /// Process document using streaming batches with memory optimization
    /// - Parameters:
    ///   - document: PDF document to process
    ///   - options: Extraction options
    ///   - progressHandler: Optional progress callback
    /// - Returns: Complete extracted text
    func processDocumentStreaming(
        _ document: PDFDocument,
        options: ExtractionOptions,
        progressHandler: ((ProcessingProgress) -> Void)? = nil
    ) async -> String {
        
        let pageCount = document.pageCount
        guard pageCount > 0 else { return "" }
        
        // Check cache first
        let cacheKey = "streaming_\(document.pageCount)_\(document.documentURL?.lastPathComponent ?? "unknown")_\(document.hash)"
        if let cachedText = cacheManager.retrieve(forKey: cacheKey) {
            return cachedText
        }
        
        // Calculate adaptive batch configuration
        let adaptiveConfig = calculateAdaptiveBatchConfiguration(
            for: document,
            options: options
        )
        
        // Create batches
        let batches = createBatches(pageCount: pageCount, configuration: adaptiveConfig)
        let totalBatches = batches.count
        
        var results: [BatchResult] = []
        var completedPages = 0
        
        // Process batches with memory awareness
        for (batchIndex, batch) in batches.enumerated() {
            let startTime = Date()
            
            // Check memory pressure before processing
            if pressureMonitor.requiresImmediateAction() {
                // Wait for memory pressure to reduce
                await waitForMemoryPressureReduction()
            }
            
            // Process current batch
            let batchResult = await processBatch(
                document: document,
                batch: batch,
                batchIndex: batchIndex,
                options: options
            )
            
            results.append(batchResult)
            completedPages += batch.count
            
            // Report progress
            let progress = ProcessingProgress(
                completedPages: completedPages,
                totalPages: pageCount,
                currentBatch: batchIndex + 1,
                totalBatches: totalBatches,
                estimatedTimeRemaining: estimateRemainingTime(
                    batchIndex: batchIndex,
                    totalBatches: totalBatches,
                    averageTimePerBatch: Date().timeIntervalSince(startTime)
                )
            )
            
            progressHandler?(progress)
            progressSubject.send(progress)
            
            // Allow memory cleanup between batches
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Combine results in correct order
        results.sort { $0.batchIndex < $1.batchIndex }
        let finalText = results.map { $0.extractedText }.joined(separator: "\n")
        
        // Cache the final result
        _ = cacheManager.store(finalText, forKey: cacheKey)
        
        return finalText
    }
    
    // MARK: - Batch Processing
    
    /// Process a single batch of pages
    /// - Parameters:
    ///   - document: PDF document
    ///   - batch: Page range to process
    ///   - batchIndex: Index of current batch
    ///   - options: Extraction options
    /// - Returns: Batch processing result
    private func processBatch(
        document: PDFDocument,
        batch: Range<Int>,
        batchIndex: Int,
        options: ExtractionOptions
    ) async -> BatchResult {
        
        let startTime = Date()
        let startMemory = MemoryUtils.getCurrentMemoryUsage()
        
        var batchText = ""
        
        // Process pages in batch with autorelease pool
        autoreleasepool {
            for pageIndex in batch {
                if let page = document.page(at: pageIndex),
                   let pageText = page.string {
                    
                    // Apply memory-efficient preprocessing if enabled
                    let processedText = options.preprocessText ?
                        MemoryUtils.preprocessTextMemoryEfficient(pageText) : pageText
                    
                    batchText += processedText + "\n"
                }
            }
        }
        
        // Yield control periodically during batch processing
        if batch.count > 3 {
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        let endTime = Date()
        let endMemory = MemoryUtils.getCurrentMemoryUsage()
        let memoryUsed = endMemory > startMemory ? endMemory - startMemory : 0
        
        return BatchResult(
            batchIndex: batchIndex,
            pageRange: batch,
            extractedText: batchText,
            processingTime: endTime.timeIntervalSince(startTime),
            memoryUsed: memoryUsed
        )
    }
    
    // MARK: - Batch Configuration
    
    /// Calculate adaptive batch configuration based on document and system state
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - options: Extraction options
    /// - Returns: Optimized batch configuration
    private func calculateAdaptiveBatchConfiguration(
        for document: PDFDocument,
        options: ExtractionOptions
    ) -> BatchConfiguration {
        
        // Get memory pressure recommendations
        let recommendedBatchSize = pressureMonitor.getRecommendedBatchSize(
            default: configuration.maxBatchSize
        )
        let recommendedConcurrency = pressureMonitor.getRecommendedConcurrency(
            default: configuration.maxConcurrentBatches
        )
        
        // Adjust based on document characteristics
        let adjustedBatchSize = calculateOptimalBatchSize(
            pageCount: document.pageCount,
            recommendedSize: recommendedBatchSize
        )
        
        return BatchConfiguration(
            maxBatchSize: adjustedBatchSize,
            maxConcurrentBatches: recommendedConcurrency,
            memoryThreshold: configuration.memoryThreshold
        )
    }
    
    /// Calculate optimal batch size based on page count
    /// - Parameters:
    ///   - pageCount: Number of pages in document
    ///   - recommendedSize: Recommended batch size from pressure monitor
    /// - Returns: Optimal batch size
    private func calculateOptimalBatchSize(pageCount: Int, recommendedSize: Int) -> Int {
        if pageCount > 100 {
            return min(recommendedSize, 5)  // Large documents: smaller batches
        } else if pageCount > 20 {
            return min(recommendedSize, 8)  // Medium documents: moderate batches
        } else {
            return recommendedSize          // Small documents: can use larger batches
        }
    }
    
    /// Create batches for processing
    /// - Parameters:
    ///   - pageCount: Total number of pages
    ///   - configuration: Batch configuration to use
    /// - Returns: Array of page ranges for batching
    private func createBatches(pageCount: Int, configuration: BatchConfiguration) -> [Range<Int>] {
        var batches: [Range<Int>] = []
        
        for start in stride(from: 0, to: pageCount, by: configuration.maxBatchSize) {
            let end = min(start + configuration.maxBatchSize, pageCount)
            batches.append(start..<end)
        }
        
        return batches
    }
    
    // MARK: - Helper Methods
    
    /// Wait for memory pressure to reduce to acceptable levels
    private func waitForMemoryPressureReduction() async {
        while pressureMonitor.requiresImmediateAction() {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
    }
    
    /// Estimate remaining processing time
    /// - Parameters:
    ///   - batchIndex: Current batch index
    ///   - totalBatches: Total number of batches
    ///   - averageTimePerBatch: Average time per batch
    /// - Returns: Estimated remaining time in seconds
    private func estimateRemainingTime(
        batchIndex: Int,
        totalBatches: Int,
        averageTimePerBatch: TimeInterval
    ) -> TimeInterval {
        let remainingBatches = totalBatches - (batchIndex + 1)
        return Double(remainingBatches) * averageTimePerBatch
    }
    

    
    // MARK: - Progress Tracking
    
    /// Publisher for processing progress updates
    var progressPublisher: AnyPublisher<ProcessingProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }
} 
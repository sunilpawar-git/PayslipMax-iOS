import Foundation
import PDFKit
import Combine

/// Streaming batch coordinator for memory-efficient PDF processing
///
/// Following Phase 4B modular pattern: Focused responsibility for batch coordination
/// Orchestrates memory-aware streaming processing with adaptive batch sizing
final class StreamingBatchCoordinator {
    
    // MARK: - Dependencies
    
    /// Resource pressure monitor for adaptive processing
    private let pressureMonitor: ResourcePressureMonitor
    
    /// Batch processor for executing page batches
    private let batchProcessor: StreamingBatchProcessor
    
    /// Configuration calculator for adaptive settings
    private let configurationCalculator: BatchConfigurationCalculator
    
    /// Progress tracker for monitoring and reporting
    private let progressTracker: BatchProgressTracker
    
    // MARK: - State
    
    /// Current batch configuration
    private var configuration: BatchConfiguration
    
    // MARK: - Initialization
    
    /// Initialize streaming batch coordinator with default components
    init() {
        self.pressureMonitor = ResourcePressureMonitor()
        self.batchProcessor = StreamingBatchProcessor()
        self.configurationCalculator = BatchConfigurationCalculator()
        self.progressTracker = BatchProgressTracker()
        self.configuration = BatchConfiguration()
    }
    
    /// Initialize streaming batch coordinator with custom components
    /// - Parameters:
    ///   - pressureMonitor: Resource pressure monitor instance
    ///   - batchProcessor: Batch processor instance
    ///   - configurationCalculator: Configuration calculator instance
    ///   - progressTracker: Progress tracker instance
    ///   - configuration: Initial batch configuration
    init(
        pressureMonitor: ResourcePressureMonitor,
        batchProcessor: StreamingBatchProcessor,
        configurationCalculator: BatchConfigurationCalculator,
        progressTracker: BatchProgressTracker,
        configuration: BatchConfiguration = BatchConfiguration()
    ) {
        self.pressureMonitor = pressureMonitor
        self.batchProcessor = batchProcessor
        self.configurationCalculator = configurationCalculator
        self.progressTracker = progressTracker
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
        options: ExtractionOptions = ExtractionOptions(),
        progressHandler: ((ProcessingProgress) -> Void)? = nil
    ) async -> String {
        
        let pageCount = document.pageCount
        guard pageCount > 0 else { return "" }
        
        // Check cache first
        if let cachedText = batchProcessor.checkCache(for: document, options: options) {
            return cachedText
        }
        
        // Calculate adaptive batch configuration
        let adaptiveConfig = configurationCalculator.calculateAdaptiveBatchConfiguration(
            for: document,
            options: options,
            baseConfiguration: configuration
        )
        
        // Create batches and start tracking
        let batches = batchProcessor.createBatches(pageCount: pageCount, configuration: adaptiveConfig)
        progressTracker.startTracking(totalBatches: batches.count)
        
        // Process batches with memory awareness
        let results = await processBatchesSequentially(
            document: document,
            batches: batches,
            options: options,
            progressHandler: progressHandler
        )
        
        // Complete tracking and combine results
        progressTracker.completeTracking()
        let finalText = batchProcessor.combineBatchResults(results)
        
        // Cache the final result
        batchProcessor.storeInCache(finalText, for: document, options: options)
        
        return finalText
    }
    
    // MARK: - Batch Processing Coordination
    
    /// Process batches sequentially with memory monitoring
    /// - Parameters:
    ///   - document: PDF document
    ///   - batches: Array of page ranges to process
    ///   - options: Extraction options
    ///   - progressHandler: Optional progress callback
    /// - Returns: Array of batch results
    private func processBatchesSequentially(
        document: PDFDocument,
        batches: [Range<Int>],
        options: ExtractionOptions,
        progressHandler: ((ProcessingProgress) -> Void)?
    ) async -> [BatchResult] {
        
        var results: [BatchResult] = []
        var completedPages = 0
        
        for (batchIndex, batch) in batches.enumerated() {
            let startTime = Date()
            
            // Check memory pressure before processing
            if pressureMonitor.requiresImmediateAction() {
                await waitForMemoryPressureReduction()
            }
            
            // Process current batch
            let batchResult = await batchProcessor.processBatch(
                document: document,
                batch: batch,
                batchIndex: batchIndex,
                options: options
            )
            
            results.append(batchResult)
            completedPages += batch.count
            
            // Report progress
            let batchProcessingTime = Date().timeIntervalSince(startTime)
            progressTracker.reportProgress(
                batchIndex: batchIndex,
                totalBatches: batches.count,
                completedPages: completedPages,
                totalPages: document.pageCount,
                batchProcessingTime: batchProcessingTime,
                progressHandler: progressHandler
            )
            
            // Allow memory cleanup between batches
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        return results
    }
    
    // MARK: - Memory Management
    
    /// Wait for memory pressure to reduce to acceptable levels
    private func waitForMemoryPressureReduction() async {
        while pressureMonitor.requiresImmediateAction() {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
    }
    
    // MARK: - Configuration Management
    
    /// Update batch configuration
    /// - Parameter newConfiguration: New configuration to use
    func updateConfiguration(_ newConfiguration: BatchConfiguration) {
        self.configuration = configurationCalculator.validateConfiguration(newConfiguration)
    }
    
    /// Get current configuration
    /// - Returns: Current batch configuration
    func getCurrentConfiguration() -> BatchConfiguration {
        return configuration
    }
    
    /// Get recommended configuration for document
    /// - Parameter pageCount: Number of pages in document
    /// - Returns: Recommended configuration
    func getRecommendedConfiguration(for pageCount: Int) -> BatchConfiguration {
        return configurationCalculator.getRecommendedConfiguration(for: pageCount)
    }
    
    // MARK: - Progress Tracking
    
    /// Publisher for processing progress updates
    var progressPublisher: AnyPublisher<ProcessingProgress, Never> {
        progressTracker.progressPublisher
    }
    
    /// Get current progress statistics
    /// - Returns: Dictionary of progress statistics
    func getProgressStatistics() -> [String: Any] {
        return progressTracker.getProgressStatistics()
    }
    
    /// Get average processing time per batch
    /// - Returns: Average time per batch
    func getAverageProcessingTime() -> TimeInterval {
        return progressTracker.getAverageProcessingTime()
    }
}
import Foundation
import PDFKit

/// Core batch processing algorithms for streaming PDF processing
///
/// Following Phase 4B modular pattern: Focused responsibility for batch execution
/// Handles the actual processing of PDF page batches with memory optimization
final class StreamingBatchProcessor {
    
    // MARK: - Dependencies
    
    /// Memory optimized extractor for text processing
    private let memoryExtractor: MemoryOptimizedExtractor
    
    /// Adaptive cache manager for result caching
    private let cacheManager: AdaptiveCacheManager
    
    // MARK: - Initialization
    
    /// Initialize batch processor
    /// - Parameters:
    ///   - memoryExtractor: Memory optimized extractor instance
    ///   - cacheManager: Adaptive cache manager instance
    init(
        memoryExtractor: MemoryOptimizedExtractor = MemoryOptimizedExtractor(),
        cacheManager: AdaptiveCacheManager = AdaptiveCacheManager()
    ) {
        self.memoryExtractor = memoryExtractor
        self.cacheManager = cacheManager
    }
    
    // MARK: - Batch Processing
    
    /// Process a single batch of pages
    /// - Parameters:
    ///   - document: PDF document
    ///   - batch: Page range to process
    ///   - batchIndex: Index of current batch
    ///   - options: Extraction options
    /// - Returns: Batch processing result
    func processBatch(
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
    
    /// Create batches for processing
    /// - Parameters:
    ///   - pageCount: Total number of pages
    ///   - configuration: Batch configuration to use
    /// - Returns: Array of page ranges for batching
    func createBatches(pageCount: Int, configuration: BatchConfiguration) -> [Range<Int>] {
        var batches: [Range<Int>] = []
        
        for start in stride(from: 0, to: pageCount, by: configuration.maxBatchSize) {
            let end = min(start + configuration.maxBatchSize, pageCount)
            batches.append(start..<end)
        }
        
        return batches
    }
    
    /// Combine batch results into final text
    /// - Parameter results: Array of batch results
    /// - Returns: Combined text from all batches
    func combineBatchResults(_ results: [BatchResult]) -> String {
        let sortedResults = results.sorted { $0.batchIndex < $1.batchIndex }
        return sortedResults.map { $0.extractedText }.joined(separator: "\n")
    }
    
    /// Check cache for existing result
    /// - Parameters:
    ///   - document: PDF document
    ///   - options: Extraction options
    /// - Returns: Cached text if available
    func checkCache(for document: PDFDocument, options: ExtractionOptions) -> String? {
        let cacheKey = "streaming_\(document.pageCount)_\(document.documentURL?.lastPathComponent ?? "unknown")_\(document.hash)"
        return cacheManager.retrieve(forKey: cacheKey)
    }
    
    /// Store result in cache
    /// - Parameters:
    ///   - text: Text to cache
    ///   - document: PDF document
    ///   - options: Extraction options
    func storeInCache(_ text: String, for document: PDFDocument, options: ExtractionOptions) {
        let cacheKey = "streaming_\(document.pageCount)_\(document.documentURL?.lastPathComponent ?? "unknown")_\(document.hash)"
        _ = cacheManager.store(text, forKey: cacheKey)
    }
}

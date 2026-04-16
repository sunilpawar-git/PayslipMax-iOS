import Foundation
import PDFKit

/// Memory-optimized text extractor for efficient PDF processing
///
/// Following Phase 4B modular pattern: Focused responsibility for memory-efficient text extraction
/// Eliminates repeated memory calculations and implements intelligent sampling
class MemoryOptimizedExtractor {
    
    // MARK: - Memory-Optimized Configuration
    
    /// Maximum memory threshold for processing (default: 200MB)
    let maxMemoryThreshold: UInt64
    
    /// Cache for memory requirement estimations to avoid recalculation
    var memoryEstimationCache: [String: UInt64] = [:]
    
    /// Base memory overhead for processing operations
    let processingOverhead: UInt64 = 50_000_000 // 50MB
    
    /// Sample size for memory estimation (pages)
    let estimationSampleSize: Int = 5
    
    // MARK: - Initialization
    
    /// Initialize with memory threshold configuration
    /// - Parameter maxMemoryThreshold: Maximum memory in bytes (default: 200MB)
    init(maxMemoryThreshold: UInt64 = 200 * 1024 * 1024) {
        self.maxMemoryThreshold = maxMemoryThreshold
    }
    
    // MARK: - Memory-Optimized Text Extraction
    
    /// Extract text with memory optimization awareness
    /// - Parameters:
    ///   - document: PDF document to process
    ///   - options: Extraction options
    /// - Returns: Tuple of extracted text and memory usage info
    func extractTextWithMemoryOptimization(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async -> (text: String, memoryUsed: UInt64, useStreamingRecommended: Bool) {
        
        let startMemory = MemoryUtils.getCurrentMemoryUsage()
        
        // Check cached memory requirement or calculate if needed
        let estimatedMemory = getCachedOrCalculateMemoryRequirement(for: document)
        let shouldUseStreaming = estimatedMemory > maxMemoryThreshold
        
        var extractedText: String
        
        if shouldUseStreaming {
            // Use memory-efficient streaming extraction
            extractedText = await extractTextStreaming(from: document, options: options)
        } else {
            // Use standard extraction with memory monitoring
            extractedText = await extractTextStandard(from: document, options: options)
        }
        
        let endMemory = MemoryUtils.getCurrentMemoryUsage()
        let memoryUsed = endMemory > startMemory ? endMemory - startMemory : 0
        
        return (extractedText, memoryUsed, shouldUseStreaming)
    }
    
    /// Extract text using memory-efficient streaming approach
    /// - Parameters:
    ///   - document: PDF document to process
    ///   - options: Extraction options
    /// - Returns: Extracted text string
    private func extractTextStreaming(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async -> String {
        var extractedText = ""
        let pageCount = document.pageCount
        let batchSize = calculateOptimalBatchSize(for: document, options: options)
        
        // Process in memory-efficient batches
        for batchStart in stride(from: 0, to: pageCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, pageCount)
            var batchText = ""
            
            // Extract text in autoreleasepool without async operations
            autoreleasepool {
                for pageIndex in batchStart..<batchEnd {
                    if let page = document.page(at: pageIndex),
                       let pageText = page.string {
                        batchText += pageText + "\n"
                    }
                }
            }
            
            // Yield control outside autoreleasepool
            if batchStart % 50 == 0 {
                await Task.yield()
            }
            
            // Apply preprocessing if enabled
            if options.preprocessText {
                batchText = MemoryUtils.preprocessTextMemoryEfficient(batchText)
            }
            
            extractedText += batchText
            
            // Allow memory cleanup between batches
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        return extractedText
    }
    
    /// Extract text using standard approach with memory monitoring
    /// - Parameters:
    ///   - document: PDF document to process
    ///   - options: Extraction options
    /// - Returns: Extracted text string
    private func extractTextStandard(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async -> String {
        var extractedText = ""
        let pageCount = document.pageCount
        
        if options.useParallelProcessing && pageCount > 1 {
            // Parallel processing with memory monitoring
            extractedText = await extractTextParallelMemoryAware(from: document, options: options)
        } else {
            // Sequential processing with autorelease pools
            for pageIndex in 0..<pageCount {
                autoreleasepool {
                    if let page = document.page(at: pageIndex),
                       let pageText = page.string {
                        let processedText = options.preprocessText ?
                            MemoryUtils.preprocessTextMemoryEfficient(pageText) : pageText
                        extractedText += processedText + "\n"
                    }
                }
                
                // Yield control periodically
                if pageIndex % 5 == 0 {
                    try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
                }
            }
        }
        
        return extractedText
    }
    
    /// Extract text using parallel processing with memory awareness
    /// - Parameters:
    ///   - document: PDF document to process
    ///   - options: Extraction options
    /// - Returns: Extracted text string
    private func extractTextParallelMemoryAware(
        from document: PDFDocument,
        options: ExtractionOptions
    ) async -> String {
        let pageCount = document.pageCount
        let maxConcurrency = min(options.maxConcurrentOperations, 4) // Limit for memory
        
        return await withTaskGroup(of: (Int, String).self) { group in
            var results: [(Int, String)] = []
            
            // Add tasks with memory-conscious concurrency limits
            for pageIndex in 0..<pageCount {
                group.addTask {
                    autoreleasepool {
                        if let page = document.page(at: pageIndex),
                           let pageText = page.string {
                            let processedText = options.preprocessText ?
                                MemoryUtils.preprocessTextMemoryEfficient(pageText) : pageText
                            return (pageIndex, processedText)
                        }
                        return (pageIndex, "")
                    }
                }
                
                // Limit concurrent tasks to prevent memory pressure
                if group.isEmpty == false && (pageIndex + 1) % maxConcurrency == 0 {
                    if let result = await group.next() {
                        results.append(result)
                    }
                }
            }
            
            // Collect remaining results
            for await result in group {
                results.append(result)
            }
            
            // Sort by page index and combine
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }.joined(separator: "\n")
        }
    }
    
}
import Foundation
import PDFKit

/// Memory-optimized text extractor for efficient PDF processing
///
/// Following Phase 4B modular pattern: Focused responsibility for memory-efficient text extraction
/// Eliminates repeated memory calculations and implements intelligent sampling
class MemoryOptimizedExtractor {
    
    // MARK: - Memory-Optimized Configuration
    
    /// Maximum memory threshold for processing (default: 200MB)
    private let maxMemoryThreshold: UInt64
    
    /// Cache for memory requirement estimations to avoid recalculation
    private var memoryEstimationCache: [String: UInt64] = [:]
    
    /// Base memory overhead for processing operations
    private let processingOverhead: UInt64 = 50_000_000 // 50MB
    
    /// Sample size for memory estimation (pages)
    private let estimationSampleSize: Int = 5
    
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
    
    // MARK: - Memory Calculation and Caching
    
    /// Get cached memory requirement or calculate if not cached
    /// - Parameter document: PDF document to analyze
    /// - Returns: Estimated memory requirement in bytes
    private func getCachedOrCalculateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        let cacheKey = generateCacheKey(for: document)
        
        if let cachedEstimate = memoryEstimationCache[cacheKey] {
            return cachedEstimate
        }
        
        let estimate = calculateMemoryRequirement(for: document)
        memoryEstimationCache[cacheKey] = estimate
        
        // Clean cache if it gets too large
        if memoryEstimationCache.count > 100 {
            let keysToRemove = Array(memoryEstimationCache.keys.prefix(50))
            keysToRemove.forEach { memoryEstimationCache.removeValue(forKey: $0) }
        }
        
        return estimate
    }
    
    /// Calculate optimal batch size based on document characteristics
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - options: Extraction options
    /// - Returns: Optimal batch size in pages
    private func calculateOptimalBatchSize(for document: PDFDocument, options: ExtractionOptions) -> Int {
        let pageCount = document.pageCount
        let estimatedMemoryPerPage = getCachedOrCalculateMemoryRequirement(for: document) / UInt64(max(pageCount, 1))
        
        // Calculate batch size based on memory threshold
        let maxBatchMemory = UInt64(options.maxBatchSize)
        let optimalBatchSize = Int(maxBatchMemory / max(estimatedMemoryPerPage, 1_000_000))
        
        return max(1, min(optimalBatchSize, 20)) // Between 1 and 20 pages
    }
    
    /// Calculate memory requirement for document using intelligent sampling
    /// - Parameter document: PDF document to analyze
    /// - Returns: Estimated memory requirement in bytes
    private func calculateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        let pageCount = document.pageCount
        let sampleSize = min(pageCount, estimationSampleSize)
        
        var totalSampleSize: UInt64 = 0
        
        for i in 0..<sampleSize {
            if let page = document.page(at: i),
               let pageText = page.string {
                // Unicode characters are typically 2 bytes each
                totalSampleSize += UInt64(pageText.count * 2)
            } else {
                // Default estimate for pages without text
                totalSampleSize += 1_000_000 // 1MB
            }
        }
        
        // Calculate average and extrapolate
        let avgSampleSize = sampleSize > 0 ? totalSampleSize / UInt64(sampleSize) : 1_000_000
        let estimatedSize = avgSampleSize * UInt64(pageCount)
        
        return estimatedSize + processingOverhead
    }
    
    // MARK: - Helper Methods
    
    /// Generate cache key for document
    /// - Parameter document: PDF document
    /// - Returns: Cache key string
    private func generateCacheKey(for document: PDFDocument) -> String {
        return "\(document.pageCount)_\(document.documentURL?.lastPathComponent ?? "unknown")_\(document.hash)"
    }
    
    /// Memory-efficient text preprocessing
    /// - Parameter text: Text to preprocess
    /// - Returns: Preprocessed text
    private func preprocessTextMemoryEfficient(_ text: String) -> String {
        // Efficient text normalization without multiple passes
        return text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: #"(\n\s*){3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 
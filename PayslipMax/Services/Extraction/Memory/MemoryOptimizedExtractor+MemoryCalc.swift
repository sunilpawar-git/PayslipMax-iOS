import Foundation
import PDFKit

// MARK: - Memory Calculation and Caching

extension MemoryOptimizedExtractor {

    /// Get cached memory requirement or calculate if not cached
    func getCachedOrCalculateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        let cacheKey = generateCacheKey(for: document)
        
        if let cachedEstimate = memoryEstimationCache[cacheKey] {
            return cachedEstimate
        }
        
        let estimate = calculateMemoryRequirement(for: document)
        memoryEstimationCache[cacheKey] = estimate
        
        if memoryEstimationCache.count > 100 {
            let keysToRemove = Array(memoryEstimationCache.keys.prefix(50))
            keysToRemove.forEach { memoryEstimationCache.removeValue(forKey: $0) }
        }
        
        return estimate
    }

    /// Calculate optimal batch size based on document characteristics
    func calculateOptimalBatchSize(for document: PDFDocument, options: ExtractionOptions) -> Int {
        let pageCount = document.pageCount
        let estimatedMemoryPerPage = getCachedOrCalculateMemoryRequirement(for: document) / UInt64(max(pageCount, 1))
        
        let maxBatchMemory = UInt64(options.maxBatchSize)
        let optimalBatchSize = Int(maxBatchMemory / max(estimatedMemoryPerPage, 1_000_000))
        
        return max(1, min(optimalBatchSize, 20))
    }

    /// Calculate memory requirement for document using intelligent sampling
    func calculateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        let pageCount = document.pageCount
        let sampleSize = min(pageCount, estimationSampleSize)
        
        var totalSampleSize: UInt64 = 0
        
        for i in 0..<sampleSize {
            if let page = document.page(at: i),
               let pageText = page.string {
                totalSampleSize += UInt64(pageText.count * 2)
            } else {
                totalSampleSize += 1_000_000
            }
        }
        
        let avgSampleSize = sampleSize > 0 ? totalSampleSize / UInt64(sampleSize) : 1_000_000
        let estimatedSize = avgSampleSize * UInt64(pageCount)
        
        return estimatedSize + processingOverhead
    }

    // MARK: - Helper Methods

    /// Generate cache key for document
    func generateCacheKey(for document: PDFDocument) -> String {
        return "\(document.pageCount)_\(document.documentURL?.lastPathComponent ?? "unknown")_\(document.hash)"
    }

    /// Memory-efficient text preprocessing
    func preprocessTextMemoryEfficient(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: #"(\n\s*){3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

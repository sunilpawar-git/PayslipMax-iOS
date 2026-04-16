import Foundation

// MARK: - Update Methods

extension IntegratedPerformanceMetrics {

    /// Record successful document processing
    mutating func recordDocumentProcessing(duration: TimeInterval) {
        documentsProcessed += 1
        totalProcessingTime += duration

        if duration > peakProcessingTime {
            peakProcessingTime = duration
        }

        lastUpdated = Date()
    }

    /// Record cache hit
    mutating func recordCacheHit() {
        cacheHits += 1
        lastUpdated = Date()
    }

    /// Record cache miss
    mutating func recordCacheMiss() {
        cacheMisses += 1
        lastUpdated = Date()
    }

    /// Record stage cache hit
    mutating func recordStageCacheHit() {
        stageCacheHits += 1
        lastUpdated = Date()
    }

    /// Record stage cache miss
    mutating func recordStageCacheMiss() {
        stageCacheMisses += 1
        lastUpdated = Date()
    }

    /// Record deduplication hit
    mutating func recordDeduplicationHit(timeSaved: TimeInterval = 0.0, memorySaved: Int64 = 0) {
        deduplicationHits += 1
        timeSavedThroughDeduplication += timeSaved
        memorySavedThroughDeduplication += memorySaved
        lastUpdated = Date()
    }

    /// Record unique operation
    mutating func recordUniqueOperation() {
        uniqueOperations += 1
        lastUpdated = Date()
    }

    /// Record operation coalescing
    mutating func recordOperationCoalescing(subscribers: Int, timeSaved: TimeInterval = 0.0) {
        coalescedOperations += 1
        sharedResultOperations += subscribers
        totalSubscribers += subscribers
        timeSavedThroughCoalescing += timeSaved
        lastUpdated = Date()
    }

    /// Record processing error
    mutating func recordProcessingError() {
        processingErrors += 1
        lastUpdated = Date()
    }

    /// Record cache error
    mutating func recordCacheError() {
        cacheErrors += 1
        lastUpdated = Date()
    }

    /// Record deduplication error
    mutating func recordDeduplicationError() {
        deduplicationErrors += 1
        lastUpdated = Date()
    }

    /// Record memory usage
    mutating func recordMemoryUsage(_ usage: Int64) {
        if usage > peakMemoryUsage {
            peakMemoryUsage = usage
        }
        lastUpdated = Date()
    }

    /// Reset all metrics for new session
    mutating func reset() {
        self = IntegratedPerformanceMetrics()
    }
}

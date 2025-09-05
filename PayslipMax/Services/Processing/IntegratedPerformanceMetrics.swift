import Foundation

/// Performance metrics for the enhanced processing pipeline integration
/// Tracks efficiency improvements from deduplication and operation coalescing
struct IntegratedPerformanceMetrics: Codable {
    
    // MARK: - Processing Performance
    
    /// Total processing time across all operations (seconds)
    var totalProcessingTime: TimeInterval = 0.0
    
    /// Number of documents processed
    var documentsProcessed: Int = 0
    
    /// Average processing time per document (seconds)
    var averageProcessingTime: TimeInterval {
        return documentsProcessed > 0 ? totalProcessingTime / Double(documentsProcessed) : 0.0
    }
    
    /// Peak processing time for a single document (seconds)
    var peakProcessingTime: TimeInterval = 0.0
    
    // MARK: - Cache Performance
    
    /// Total cache hits across all cache levels
    var cacheHits: Int = 0
    
    /// Total cache misses across all cache levels
    var cacheMisses: Int = 0
    
    /// Cache hit rate percentage
    var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? (Double(cacheHits) / Double(total)) * 100.0 : 0.0
    }
    
    /// Stage-specific cache hits
    var stageCacheHits: Int = 0
    
    /// Stage-specific cache misses
    var stageCacheMisses: Int = 0
    
    /// Stage cache hit rate percentage
    var stageCacheHitRate: Double {
        let total = stageCacheHits + stageCacheMisses
        return total > 0 ? (Double(stageCacheHits) / Double(total)) * 100.0 : 0.0
    }
    
    // MARK: - Deduplication Performance
    
    /// Number of operations avoided through deduplication
    var deduplicationHits: Int = 0
    
    /// Number of unique operations processed
    var uniqueOperations: Int = 0
    
    /// Deduplication effectiveness percentage
    var deduplicationEffectiveness: Double {
        let total = deduplicationHits + uniqueOperations
        return total > 0 ? (Double(deduplicationHits) / Double(total)) * 100.0 : 0.0
    }
    
    /// Time saved through deduplication (seconds)
    var timeSavedThroughDeduplication: TimeInterval = 0.0
    
    // MARK: - Operation Coalescing Performance
    
    /// Number of operations coalesced
    var coalescedOperations: Int = 0
    
    /// Number of operations that shared results
    var sharedResultOperations: Int = 0
    
    /// Total subscribers across all coalesced operations
    var totalSubscribers: Int = 0
    
    /// Coalescing efficiency percentage
    var coalescingEfficiency: Double {
        return coalescedOperations > 0 ? (Double(sharedResultOperations) / Double(coalescedOperations)) * 100.0 : 0.0
    }
    
    /// Time saved through operation coalescing (seconds)
    var timeSavedThroughCoalescing: TimeInterval = 0.0
    
    // MARK: - Error Tracking
    
    /// Number of processing errors encountered
    var processingErrors: Int = 0
    
    /// Number of cache errors encountered
    var cacheErrors: Int = 0
    
    /// Number of deduplication errors encountered
    var deduplicationErrors: Int = 0
    
    /// Error rate percentage
    var errorRate: Double {
        let totalOperations = documentsProcessed + processingErrors
        return totalOperations > 0 ? (Double(processingErrors) / Double(totalOperations)) * 100.0 : 0.0
    }
    
    // MARK: - Memory Performance
    
    /// Peak memory usage during processing (bytes)
    var peakMemoryUsage: Int64 = 0
    
    /// Memory saved through deduplication (bytes)
    var memorySavedThroughDeduplication: Int64 = 0
    
    /// Memory efficiency improvement percentage
    var memoryEfficiencyImprovement: Double {
        guard peakMemoryUsage > 0 else { return 0.0 }
        return (Double(memorySavedThroughDeduplication) / Double(peakMemoryUsage)) * 100.0
    }
    
    // MARK: - Session Information
    
    /// Session start time
    var sessionStartTime: Date = Date()
    
    /// Last metrics update time
    var lastUpdated: Date = Date()
    
    /// Session duration in seconds
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(sessionStartTime)
    }
    
    // MARK: - Computed Performance Indicators
    
    /// Overall performance improvement percentage
    /// Combines deduplication, caching, and coalescing benefits
    var overallPerformanceImprovement: Double {
        let deduplicationContribution = deduplicationEffectiveness * 0.4 // 40% weight
        let cacheContribution = cacheHitRate * 0.4 // 40% weight
        let coalescingContribution = coalescingEfficiency * 0.2 // 20% weight
        
        return (deduplicationContribution + cacheContribution + coalescingContribution) / 100.0 * 100.0
    }
    
    /// Processing throughput (documents per second)
    var processingThroughput: Double {
        return sessionDuration > 0 ? Double(documentsProcessed) / sessionDuration : 0.0
    }
    
    /// Resource efficiency score (0-100)
    var resourceEfficiencyScore: Double {
        let memoryScore = min(100.0, memoryEfficiencyImprovement)
        let timeScore = min(100.0, (timeSavedThroughDeduplication + timeSavedThroughCoalescing) / totalProcessingTime * 100.0)
        let errorScore = max(0.0, 100.0 - errorRate)
        
        return (memoryScore + timeScore + errorScore) / 3.0
    }
    
    // MARK: - Update Methods
    
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
    
    /// Generate performance summary
    func generateSummary() -> PerformanceSummary {
        return PerformanceSummary(
            documentsProcessed: documentsProcessed,
            averageProcessingTime: averageProcessingTime,
            cacheHitRate: cacheHitRate,
            deduplicationEffectiveness: deduplicationEffectiveness,
            coalescingEfficiency: coalescingEfficiency,
            overallImprovement: overallPerformanceImprovement,
            resourceEfficiency: resourceEfficiencyScore,
            errorRate: errorRate,
            sessionDuration: sessionDuration,
            generatedAt: Date()
        )
    }
}

// MARK: - Performance Summary

/// Summary of performance metrics for reporting
struct PerformanceSummary: Codable {
    let documentsProcessed: Int
    let averageProcessingTime: TimeInterval
    let cacheHitRate: Double
    let deduplicationEffectiveness: Double
    let coalescingEfficiency: Double
    let overallImprovement: Double
    let resourceEfficiency: Double
    let errorRate: Double
    let sessionDuration: TimeInterval
    let generatedAt: Date
    
    /// Performance grade based on overall improvement
    var performanceGrade: String {
        switch overallImprovement {
        case 90...: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B+"
        case 60..<70: return "B"
        case 50..<60: return "C+"
        case 40..<50: return "C"
        case 30..<40: return "D"
        default: return "F"
        }
    }
    
}

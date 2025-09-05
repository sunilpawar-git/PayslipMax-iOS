import Foundation

// MARK: - Deduplication Metrics Data Structures

/// Core metrics for deduplication effectiveness tracking
struct DeduplicationMetrics: Codable, Equatable {
    
    // MARK: - Cache Performance
    
    /// Cache hit rate percentage (0.0-100.0)
    var cacheHitRate: Double = 0.0
    
    /// Total cache hits in current session
    var totalCacheHits: Int = 0
    
    /// Total cache misses in current session
    var totalCacheMisses: Int = 0
    
    /// Cache key effectiveness (unique keys / total requests)
    var cacheKeyEffectiveness: Double = 0.0
    
    // MARK: - Deduplication Performance
    
    /// Percentage of operations avoided through deduplication (0.0-100.0)
    var redundancyReduction: Double = 0.0
    
    /// Number of operations coalesced
    var coalescedOperations: Int = 0
    
    /// Number of identical requests sharing results
    var sharedResults: Int = 0
    
    /// Semantic fingerprint matches
    var semanticMatches: Int = 0
    
    // MARK: - Processing Performance
    
    /// Average processing time per document (seconds)
    var averageProcessingTime: Double = 0.0
    
    /// Peak processing time in current session (seconds)
    var peakProcessingTime: Double = 0.0
    
    /// Total documents processed
    var totalDocumentsProcessed: Int = 0
    
    /// Processing time saved through deduplication (seconds)
    var timeSavedThroughDeduplication: Double = 0.0
    
    // MARK: - Memory Efficiency
    
    /// Memory saved through deduplication (bytes)
    var memorySaved: Int64 = 0
    
    /// Peak memory usage (bytes)
    var peakMemoryUsage: Int64 = 0
    
    /// Current memory usage (bytes)
    var currentMemoryUsage: Int64 = 0
    
    // MARK: - System Health
    
    /// Timestamp of last metrics update
    var lastUpdated: Date = Date()
    
    /// Session start time
    var sessionStartTime: Date = Date()
    
    /// Error count in current session
    var errorCount: Int = 0
    
    // MARK: - Computed Properties
    
    /// Total cache requests
    var totalCacheRequests: Int {
        return totalCacheHits + totalCacheMisses
    }
    
    /// Session duration in seconds
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(sessionStartTime)
    }
    
    /// Processing efficiency (0.0-1.0)
    var processingEfficiency: Double {
        guard totalDocumentsProcessed > 0 else { return 0.0 }
        let baselineTime = Double(totalDocumentsProcessed) * 3.0 // Assume 3s baseline
        let actualTime = averageProcessingTime * Double(totalDocumentsProcessed)
        return max(0.0, (baselineTime - actualTime) / baselineTime)
    }
}

/// Historical trends analysis
struct MetricsTrends: Codable, Equatable {
    
    /// Cache hit rate trend (positive = improving)
    var cacheHitRateTrend: Double = 0.0
    
    /// Redundancy reduction trend (positive = improving)
    var redundancyReductionTrend: Double = 0.0
    
    /// Processing time trend (negative = improving)
    var processingTimeTrend: Double = 0.0
    
    /// Memory usage trend (negative = improving)
    var memoryUsageTrend: Double = 0.0
    
    /// Trend calculation window (days)
    var trendWindow: Int = 7
    
    /// Last trend calculation date
    var lastCalculated: Date = Date()
    
    /// Is trend data reliable (enough data points)
    var isReliable: Bool = false
}

/// Performance baseline from Phase 0
struct PerformanceBaseline: Codable, Equatable {
    
    /// Baseline average processing time (seconds)
    var baselineProcessingTime: Double = 0.0
    
    /// Baseline memory usage (bytes)
    var baselineMemoryUsage: Int64 = 0
    
    /// Baseline cache hit rate (percentage)
    var baselineCacheHitRate: Double = 0.0
    
    /// Baseline establishment date
    var establishedDate: Date = Date()
    
    /// Is baseline valid and reliable
    var isValid: Bool = false
    
    /// Baseline measurement count
    var measurementCount: Int = 0
}

/// Alert thresholds configuration
struct AlertThresholds: Codable, Equatable {
    
    /// Alert if redundancy reduction falls below this percentage
    let redundancyReductionBelow: Double
    
    /// Alert if cache hit rate falls below this percentage
    let cacheHitRateBelow: Double
    
    /// Alert if processing time exceeds this threshold (seconds)
    let processingTimeAbove: Double
    
    /// Alert if memory usage exceeds baseline by this multiplier
    let memoryUsageMultiplier: Double
    
    init(redundancyReductionBelow: Double = 30.0,
         cacheHitRateBelow: Double = 70.0,
         processingTimeAbove: Double = 5.0,
         memoryUsageMultiplier: Double = 2.0) {
        self.redundancyReductionBelow = redundancyReductionBelow
        self.cacheHitRateBelow = cacheHitRateBelow
        self.processingTimeAbove = processingTimeAbove
        self.memoryUsageMultiplier = memoryUsageMultiplier
    }
}

/// Performance improvement summary
struct PerformanceImprovementSummary: Codable, Equatable {
    
    /// Overall performance improvement percentage
    let overallImprovement: Double
    
    /// Processing time improvement percentage
    let processingTimeImprovement: Double
    
    /// Memory usage improvement percentage
    let memoryUsageImprovement: Double
    
    /// Cache effectiveness improvement percentage
    let cacheEffectivenessImprovement: Double
    
    /// Redundancy reduction achievement
    let redundancyReductionAchievement: Double
    
    /// Summary generation date
    let generatedAt: Date
    
    /// Is improvement significant (>10%)
    var isSignificant: Bool {
        return overallImprovement > 10.0
    }
    
    /// Performance grade (A+ to F)
    var performanceGrade: String {
        switch overallImprovement {
        case 50...: return "A+"
        case 40..<50: return "A"
        case 30..<40: return "B+"
        case 20..<30: return "B"
        case 10..<20: return "C"
        case 0..<10: return "D"
        default: return "F"
        }
    }
}

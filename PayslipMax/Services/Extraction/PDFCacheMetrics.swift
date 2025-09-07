import Foundation

/// Statistics for measuring cache performance
struct CacheStats {
    var hits: Int = 0
    var misses: Int = 0
    var writes: Int = 0
    var evictions: Int = 0
    
    var hitRatio: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0.0
    }
}

/// Handles cache metrics and monitoring for PDF processing cache
final class PDFCacheMetrics {
    // MARK: - Properties
    
    /// Statistics for cache performance monitoring
    private var stats = CacheStats()
    
    /// Queue for synchronizing metric operations
    private let metricsQueue = DispatchQueue(label: "com.payslipmax.pdfcache.metrics", attributes: .concurrent)
    
    // MARK: - Statistics Tracking
    
    /// Record a cache hit
    func recordHit() {
        metricsQueue.async(flags: .barrier) { [weak self] in
            self?.stats.hits += 1
        }
    }
    
    /// Record a cache miss
    func recordMiss() {
        metricsQueue.async(flags: .barrier) { [weak self] in
            self?.stats.misses += 1
        }
    }
    
    /// Record a cache write
    func recordWrite() {
        metricsQueue.async(flags: .barrier) { [weak self] in
            self?.stats.writes += 1
        }
    }
    
    /// Record cache evictions
    /// - Parameter count: Number of items evicted
    func recordEvictions(count: Int) {
        metricsQueue.async(flags: .barrier) { [weak self] in
            self?.stats.evictions += count
        }
    }
    
    // MARK: - Metrics Retrieval
    
    /// Get cache hit ratio
    /// - Returns: Cache hit ratio (0.0-1.0)
    func getHitRatio() -> Double {
        var hitRatio: Double = 0.0
        
        metricsQueue.sync {
            hitRatio = stats.hitRatio
        }
        
        return hitRatio
    }
    
    /// Get cache statistics
    /// - Parameters:
    ///   - memoryCache: Memory cache instance for additional metrics
    ///   - diskCacheSize: Current disk cache size
    /// - Returns: Dictionary with cache statistics
    func getCacheMetrics(memoryCache: NSCache<NSString, NSData>, diskCacheSize: Int64) -> [String: Any] {
        var metrics: [String: Any] = [:]
        
        metricsQueue.sync {
            metrics = [
                "hits": stats.hits,
                "misses": stats.misses,
                "writes": stats.writes,
                "evictions": stats.evictions,
                "hitRatio": stats.hitRatio,
                "memoryItems": memoryCache.totalCostLimit,
                "diskCacheSize": diskCacheSize
            ]
        }
        
        return metrics
    }
    
    /// Get current statistics snapshot
    /// - Returns: Current cache statistics
    func getCurrentStats() -> CacheStats {
        var currentStats = CacheStats()
        
        metricsQueue.sync {
            currentStats = stats
        }
        
        return currentStats
    }
    
    /// Reset all statistics
    func resetMetrics() {
        metricsQueue.async(flags: .barrier) { [weak self] in
            self?.stats = CacheStats()
        }
    }
    
    // MARK: - Performance Analysis
    
    /// Check if cache performance is optimal
    /// - Returns: True if hit ratio is above threshold
    func isPerformanceOptimal(minimumHitRatio: Double = 0.7) -> Bool {
        return getHitRatio() >= minimumHitRatio
    }
    
    /// Get performance recommendations
    /// - Returns: Array of performance improvement suggestions
    func getPerformanceRecommendations() -> [String] {
        let currentStats = getCurrentStats()
        var recommendations: [String] = []
        
        let hitRatio = currentStats.hitRatio
        
        if hitRatio < 0.5 {
            recommendations.append("Low hit ratio (\(String(format: "%.1f", hitRatio * 100))%). Consider increasing cache size or reviewing cache keys.")
        }
        
        if currentStats.evictions > Int(Double(currentStats.writes) * 0.1) {
            recommendations.append("High eviction rate. Consider increasing cache size to reduce turnover.")
        }
        
        if currentStats.misses > currentStats.hits * 2 {
            recommendations.append("Cache miss rate is high. Review caching strategy and key generation.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Cache performance is optimal.")
        }
        
        return recommendations
    }
}

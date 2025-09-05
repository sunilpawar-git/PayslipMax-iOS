import Foundation

/// Collects and aggregates deduplication metrics from various sources
@MainActor
final class DeduplicationMetricsCollector {
    
    // MARK: - Configuration
    
    private struct CollectorConfig {
        static let collectionInterval: TimeInterval = 60.0 // 1 minute
        static let memoryCheckInterval: TimeInterval = 10.0 // 10 seconds
        static let maxHistorySize = 1000 // Maximum metrics history entries
    }
    
    // MARK: - Properties
    
    /// Current metrics being tracked
    private var currentMetrics = DeduplicationMetrics()
    
    /// Collection timer
    private var collectionTimer: Timer?
    
    /// Memory monitoring timer
    private var memoryTimer: Timer?
    
    /// Metrics collection delegates
    private var delegates: [WeakMetricsDelegate] = []
    
    // MARK: - Initialization
    
    init() {
        setupPeriodicCollection()
        setupMemoryMonitoring()
    }
    
    deinit {
        collectionTimer?.invalidate()
        memoryTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Get current metrics snapshot
    func getCurrentMetrics() -> DeduplicationMetrics {
        return currentMetrics
    }
    
    /// Record cache hit
    func recordCacheHit() {
        currentMetrics.totalCacheHits += 1
        updateCacheHitRate()
    }
    
    /// Record cache miss
    func recordCacheMiss() {
        currentMetrics.totalCacheMisses += 1
        updateCacheHitRate()
    }
    
    /// Record operation coalescing
    func recordOperationCoalescing(savedOperations: Int = 1) {
        currentMetrics.coalescedOperations += savedOperations
        updateRedundancyReduction()
    }
    
    /// Record result sharing
    func recordResultSharing(sharedCount: Int = 1) {
        currentMetrics.sharedResults += sharedCount
        updateRedundancyReduction()
    }
    
    /// Record semantic fingerprint match
    func recordSemanticMatch() {
        currentMetrics.semanticMatches += 1
        updateRedundancyReduction()
    }
    
    /// Record document processing
    func recordDocumentProcessing(processingTime: TimeInterval) {
        currentMetrics.totalDocumentsProcessed += 1
        updateProcessingTimeMetrics(processingTime)
    }
    
    /// Record processing time saved through deduplication
    func recordTimeSaved(_ timeSaved: TimeInterval) {
        currentMetrics.timeSavedThroughDeduplication += timeSaved
    }
    
    /// Record memory saved through deduplication
    func recordMemorySaved(_ bytesSaved: Int64) {
        currentMetrics.memorySaved += bytesSaved
    }
    
    /// Record processing error
    func recordError() {
        currentMetrics.errorCount += 1
    }
    
    /// Add metrics collection delegate
    func addDelegate(_ delegate: DeduplicationMetricsDelegate) {
        let weakDelegate = WeakMetricsDelegate(delegate)
        delegates.append(weakDelegate)
        cleanupDelegates()
    }
    
    /// Reset metrics for new session
    func resetMetrics() {
        currentMetrics = DeduplicationMetrics()
        currentMetrics.sessionStartTime = Date()
    }
    
    // MARK: - Private Methods
    
    private func setupPeriodicCollection() {
        collectionTimer = Timer.scheduledTimer(withTimeInterval: CollectorConfig.collectionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performPeriodicCollection()
            }
        }
    }
    
    private func setupMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: CollectorConfig.memoryCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryMetrics()
            }
        }
    }
    
    private func performPeriodicCollection() {
        currentMetrics.lastUpdated = Date()
        notifyDelegates()
    }
    
    private func updateCacheHitRate() {
        let totalRequests = currentMetrics.totalCacheRequests
        guard totalRequests > 0 else { return }
        
        currentMetrics.cacheHitRate = (Double(currentMetrics.totalCacheHits) / Double(totalRequests)) * 100.0
        
        // Update cache key effectiveness
        let uniqueOperations = currentMetrics.coalescedOperations + currentMetrics.sharedResults + currentMetrics.semanticMatches
        currentMetrics.cacheKeyEffectiveness = totalRequests > 0 ? (Double(uniqueOperations) / Double(totalRequests)) * 100.0 : 0.0
    }
    
    private func updateRedundancyReduction() {
        let totalSavedOperations = currentMetrics.coalescedOperations + currentMetrics.sharedResults + currentMetrics.semanticMatches
        let totalOperations = currentMetrics.totalDocumentsProcessed + totalSavedOperations
        
        guard totalOperations > 0 else { return }
        currentMetrics.redundancyReduction = (Double(totalSavedOperations) / Double(totalOperations)) * 100.0
    }
    
    private func updateProcessingTimeMetrics(_ processingTime: TimeInterval) {
        // Update peak processing time
        if processingTime > currentMetrics.peakProcessingTime {
            currentMetrics.peakProcessingTime = processingTime
        }
        
        // Update rolling average processing time
        let totalDocs = currentMetrics.totalDocumentsProcessed
        let currentAverage = currentMetrics.averageProcessingTime
        let newAverage = ((currentAverage * Double(totalDocs - 1)) + processingTime) / Double(totalDocs)
        currentMetrics.averageProcessingTime = newAverage
    }
    
    private func updateMemoryMetrics() {
        let currentUsage = getCurrentMemoryUsage()
        currentMetrics.currentMemoryUsage = currentUsage
        
        // Update peak memory usage
        if currentUsage > currentMetrics.peakMemoryUsage {
            currentMetrics.peakMemoryUsage = currentUsage
        }
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func notifyDelegates() {
        cleanupDelegates()
        for delegate in delegates {
            if let del = delegate.delegate {
                Task { await del.metricsDidUpdate(currentMetrics) }
            }
        }
    }
    
    private func cleanupDelegates() {
        delegates = delegates.filter { $0.delegate != nil }
    }
}

// MARK: - Delegate Support

/// Protocol for objects that want to receive metrics updates
protocol DeduplicationMetricsDelegate: AnyObject {
    func metricsDidUpdate(_ metrics: DeduplicationMetrics) async
}

/// Weak reference wrapper for delegates
private class WeakMetricsDelegate {
    weak var delegate: DeduplicationMetricsDelegate?
    
    init(_ delegate: DeduplicationMetricsDelegate) {
        self.delegate = delegate
    }
}

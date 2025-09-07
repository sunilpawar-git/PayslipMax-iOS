import Foundation
import Combine

/// Processing pipeline optimization logic containing performance tracking and memory pressure handling
/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: ~100/300 lines
class ProcessingPipelineOptimization {
    
    // MARK: - Configuration
    
    struct OptimizationConfig {
        static let maxConcurrentOperations = 3
        static let maxMetricsHistory = 100
    }
    
    // MARK: - Dependencies
    
    private let memoryManager: EnhancedMemoryManager
    
    // MARK: - Performance Tracking
    
    @Published private(set) var averageProcessingTime: TimeInterval = 0
    @Published private(set) var cacheHitRate: Double = 0
    @Published private(set) var redundancyReduction: Double = 0
    
    private var performanceMetrics: [ProcessingMetric] = []
    
    // MARK: - Initialization
    
    init(memoryManager: EnhancedMemoryManager = EnhancedMemoryManager()) {
        self.memoryManager = memoryManager
        setupMemoryPressureHandling()
    }
    
    // MARK: - Performance Optimization
    
    func calculateOptimalBatchSize(for itemCount: Int) -> Int {
        let memoryLevel = memoryManager.currentPressureLevel
        let recommendedConcurrency = memoryManager.recommendedConcurrency
        
        let baseBatchSize = max(1, itemCount / (recommendedConcurrency * 2))
        
        switch memoryLevel {
        case .normal:
            return min(baseBatchSize, 10)
        case .warning:
            return min(baseBatchSize, 5)
        case .critical:
            return min(baseBatchSize, 3)
        case .emergency:
            return 1
        }
    }
    
    // MARK: - Performance Tracking
    
    func recordProcessingMetric(processingTime: TimeInterval, wasCacheHit: Bool) {
        let metric = ProcessingMetric(
            processingTime: processingTime,
            wasCacheHit: wasCacheHit,
            timestamp: Date()
        )
        
        performanceMetrics.append(metric)
        
        // Keep only recent metrics
        if performanceMetrics.count > OptimizationConfig.maxMetricsHistory {
            performanceMetrics.removeFirst()
        }
        
        updatePerformanceStatistics()
    }
    
    func recordCacheHit() {
        recordProcessingMetric(processingTime: 0, wasCacheHit: true)
    }
    
    func recordDeduplication() {
        recordProcessingMetric(processingTime: 0, wasCacheHit: true)
    }
    
    private func updatePerformanceStatistics() {
        guard !performanceMetrics.isEmpty else { return }
        
        let processingTimes = performanceMetrics.compactMap { $0.wasCacheHit ? nil : $0.processingTime }
        let cacheHits = performanceMetrics.filter { $0.wasCacheHit }.count
        
        DispatchQueue.main.async {
            if !processingTimes.isEmpty {
                self.averageProcessingTime = processingTimes.reduce(0, +) / Double(processingTimes.count)
            }
            
            self.cacheHitRate = Double(cacheHits) / Double(self.performanceMetrics.count)
            self.redundancyReduction = self.cacheHitRate * 100
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    private func setupMemoryPressureHandling() {
        // Memory pressure handling is now coordinated through the main pipeline
        // This class provides the optimization logic called by the main pipeline
    }
    
    func handleMemoryPressure(_ notification: Notification, operationQueue: OperationQueue) {
        guard let level = notification.userInfo?["level"] as? EnhancedMemoryManager.MemoryPressureLevel else {
            return
        }
        
        switch level {
        case .warning:
            // Memory pressure handled by stages component
            break
        case .critical, .emergency:
            // Reduce concurrency
            operationQueue.maxConcurrentOperationCount = max(1, operationQueue.maxConcurrentOperationCount - 1)
        case .normal:
            // Restore normal concurrency
            operationQueue.maxConcurrentOperationCount = OptimizationConfig.maxConcurrentOperations
        }
    }
    
    // MARK: - Memory Manager Access
    
    var shouldThrottleOperations: Bool {
        return memoryManager.shouldThrottleOperations()
    }
}

// MARK: - Supporting Types

struct ProcessingMetric {
    let processingTime: TimeInterval
    let wasCacheHit: Bool
    let timestamp: Date
}

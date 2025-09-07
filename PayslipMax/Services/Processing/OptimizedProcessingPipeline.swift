import Foundation
import Combine

/// Optimized processing pipeline that eliminates redundant operations
/// and implements efficient data transformation with caching and deduplication
/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: ~200/300 lines
class OptimizedProcessingPipeline {
    
    // MARK: - Configuration
    
    private struct PipelineConfig {
        static let maxConcurrentOperations = 3
    }
    
    // MARK: - Dependencies
    
    private let stages: ProcessingPipelineStages
    private let optimization: ProcessingPipelineOptimization
    private let operationQueue: OperationQueue
    
    // MARK: - Performance Tracking (Forwarded)
    
    var averageProcessingTime: TimeInterval {
        optimization.averageProcessingTime
    }
    
    var cacheHitRate: Double {
        optimization.cacheHitRate
    }
    
    var redundancyReduction: Double {
        optimization.redundancyReduction
    }
    
    // MARK: - Initialization
    
    /// Dependency injection constructor (preferred)
    init(stages: ProcessingPipelineStages, optimization: ProcessingPipelineOptimization) {
        self.stages = stages
        self.optimization = optimization
        
        // Configure operation queue
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = PipelineConfig.maxConcurrentOperations
        self.operationQueue.qualityOfService = .userInitiated
        
        setupMemoryPressureHandling()
    }
    
    /// Legacy constructor for backward compatibility
    convenience init(memoryManager: EnhancedMemoryManager = EnhancedMemoryManager()) {
        let stages = ProcessingPipelineStages()
        let optimization = ProcessingPipelineOptimization(memoryManager: memoryManager)
        self.init(stages: stages, optimization: optimization)
    }
    
    // MARK: - Public Interface
    
    /// Process data through optimized pipeline with deduplication and caching
    func processData<T, R>(_ input: T, 
                          using processor: @escaping (T) async throws -> R) async throws -> R {
        let cacheKey = stages.generateCacheKey(for: input)
        let startTime = Date()
        
        // Check for cached result first
        if let cachedResult = stages.getCachedResult(for: cacheKey) as? R {
            optimization.recordCacheHit()
            return cachedResult
        }
        
        // Check for duplicate operation in progress
        if let existingOperation = stages.getActiveOperation(for: cacheKey) {
            optimization.recordDeduplication()
            return try await stages.waitForOperation(existingOperation)
        }
        
        // Create new operation
        let operation = ProcessingOperation(
            cacheKey: cacheKey,
            processor: { try await processor(input) }
        )
        
        // Register active operation
        stages.setActiveOperation(operation, for: cacheKey)
        
        // Execute operation
        do {
            let result = try await stages.executeOperation(operation, operationQueue: operationQueue)
            
            // Cache successful result
            stages.cacheResult(result, for: cacheKey)
            
            // Record performance metrics
            let processingTime = Date().timeIntervalSince(startTime)
            optimization.recordProcessingMetric(processingTime: processingTime, wasCacheHit: false)
            
            return result
        } catch {
            // Remove failed operation
            stages.removeActiveOperation(for: cacheKey)
            throw error
        }
    }
    
    /// Process multiple items with intelligent batching and parallelization
    func processBatch<T, R>(_ inputs: [T],
                           using processor: @escaping (T) async throws -> R) async throws -> [R] {
        let batchSize = optimization.calculateOptimalBatchSize(for: inputs.count)
        var results: [R] = []
        
        // Process in optimized batches
        for batchStart in stride(from: 0, to: inputs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, inputs.count)
            let batch = Array(inputs[batchStart..<batchEnd])
            
            // Process batch concurrently
            let batchResults = try await withThrowingTaskGroup(of: R.self) { group in
                for item in batch {
                    group.addTask {
                        return try await self.processData(item, using: processor)
                    }
                }
                
                var batchResults: [R] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Check memory pressure between batches
            if optimization.shouldThrottleOperations {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms pause
            }
        }
        
        return results
    }
    
    // MARK: - Memory Pressure Handling
    
    private func setupMemoryPressureHandling() {
        NotificationCenter.default.addObserver(
            forName: .memoryPressureDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleMemoryPressure(notification)
        }
    }
    
    private func handleMemoryPressure(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? EnhancedMemoryManager.MemoryPressureLevel else {
            return
        }
        
        switch level {
        case .warning:
            // Reduce cache size
            stages.clearExpiredCache()
        case .critical, .emergency:
            // Clear all cache
            stages.clearAllCache()
            // Handle optimization adjustments
            optimization.handleMemoryPressure(notification, operationQueue: operationQueue)
        case .normal:
            // Restore normal concurrency
            operationQueue.maxConcurrentOperationCount = PipelineConfig.maxConcurrentOperations
        }
    }
}

import Foundation
import Combine

/// Optimized processing pipeline that eliminates redundant operations
/// and implements efficient data transformation with caching and deduplication
class OptimizedProcessingPipeline {
    
    // MARK: - Configuration
    
    fileprivate struct PipelineConfig {
        static let maxConcurrentOperations = 3
        static let cacheRetentionTime: TimeInterval = 300 // 5 minutes
        static let deduplicationWindow: TimeInterval = 60 // 1 minute
    }
    
    // MARK: - Dependencies
    
    private let memoryManager: EnhancedMemoryManager
    private let operationQueue: OperationQueue
    
    // MARK: - Caching & Deduplication
    
    private var processingCache: [String: CachedResult] = [:]
    private var activeOperations: [String: Operation] = [:]
    private let cacheQueue = DispatchQueue(label: "processing.cache", attributes: .concurrent)
    
    // MARK: - Performance Tracking
    
    @Published private(set) var averageProcessingTime: TimeInterval = 0
    @Published private(set) var cacheHitRate: Double = 0
    @Published private(set) var redundancyReduction: Double = 0
    
    private var performanceMetrics: [ProcessingMetric] = []
    private let maxMetricsHistory = 100
    
    // MARK: - Initialization
    
    init(memoryManager: EnhancedMemoryManager = EnhancedMemoryManager()) {
        self.memoryManager = memoryManager
        
        // Configure operation queue
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = PipelineConfig.maxConcurrentOperations
        self.operationQueue.qualityOfService = .userInitiated
        
        setupMemoryPressureHandling()
        startCacheCleanupTimer()
    }
    
    // MARK: - Public Interface
    
    /// Process data through optimized pipeline with deduplication and caching
    func processData<T, R>(_ input: T, 
                          using processor: @escaping (T) async throws -> R) async throws -> R {
        let cacheKey = generateCacheKey(for: input)
        let startTime = Date()
        
        // Check for cached result first
        if let cachedResult = getCachedResult(for: cacheKey) as? R {
            recordCacheHit()
            return cachedResult
        }
        
        // Check for duplicate operation in progress
        if let existingOperation = getActiveOperation(for: cacheKey) {
            recordDeduplication()
            return try await waitForOperation(existingOperation)
        }
        
        // Create new operation
        let operation = ProcessingOperation(
            cacheKey: cacheKey,
            processor: { try await processor(input) }
        )
        
        // Register active operation
        setActiveOperation(operation, for: cacheKey)
        
        // Execute operation
        do {
            let result = try await executeOperation(operation)
            
            // Cache successful result
            cacheResult(result, for: cacheKey)
            
            // Record performance metrics
            let processingTime = Date().timeIntervalSince(startTime)
            recordProcessingMetric(processingTime: processingTime, wasCacheHit: false)
            
            return result
        } catch {
            // Remove failed operation
            removeActiveOperation(for: cacheKey)
            throw error
        }
    }
    
    /// Process multiple items with intelligent batching and parallelization
    func processBatch<T, R>(_ inputs: [T],
                           using processor: @escaping (T) async throws -> R) async throws -> [R] {
        let batchSize = calculateOptimalBatchSize(for: inputs.count)
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
            if memoryManager.shouldThrottleOperations() {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms pause
            }
        }
        
        return results
    }
    
    // MARK: - Cache Management
    
    private func getCachedResult(for key: String) -> Any? {
        return cacheQueue.sync {
            guard let cached = processingCache[key],
                  !cached.isExpired else {
                processingCache.removeValue(forKey: key)
                return nil
            }
            return cached.result
        }
    }
    
    private func cacheResult(_ result: Any, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.processingCache[key] = CachedResult(
                result: result,
                timestamp: Date()
            )
        }
    }
    
    private func generateCacheKey<T>(for input: T) -> String {
        // Create deterministic cache key
        return "\(type(of: input))_\(String(describing: input).hash)"
    }
    
    // MARK: - Operation Management
    
    private func getActiveOperation(for key: String) -> Operation? {
        return cacheQueue.sync {
            activeOperations[key]
        }
    }
    
    private func setActiveOperation(_ operation: Operation, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.activeOperations[key] = operation
        }
    }
    
    private func removeActiveOperation(for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.activeOperations.removeValue(forKey: key)
        }
    }
    
    private func executeOperation<R>(_ operation: ProcessingOperation<R>) async throws -> R {
        defer {
            removeActiveOperation(for: operation.cacheKey)
        }
        
        return try await withUnsafeThrowingContinuation { continuation in
            operation.completionBlock = {
                if let error = operation.error {
                    continuation.resume(throwing: error)
                } else if let result = operation.result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: ProcessingError.operationFailed)
                }
            }
            
            operationQueue.addOperation(operation)
        }
    }
    
    private func waitForOperation<R>(_ operation: Operation) async throws -> R {
        return try await withUnsafeThrowingContinuation { continuation in
            let observer = operation.observe(\.isFinished) { operation, _ in
                if operation.isFinished {
                    if let processingOp = operation as? ProcessingOperation<R> {
                        if let error = processingOp.error {
                            continuation.resume(throwing: error)
                        } else if let result = processingOp.result {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: ProcessingError.operationFailed)
                        }
                    } else {
                        continuation.resume(throwing: ProcessingError.invalidOperation)
                    }
                }
            }
            
            // Clean up observer
            operation.completionBlock = {
                observer.invalidate()
            }
        }
    }
    
    // MARK: - Performance Optimization
    
    private func calculateOptimalBatchSize(for itemCount: Int) -> Int {
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
    
    private func recordProcessingMetric(processingTime: TimeInterval, wasCacheHit: Bool) {
        let metric = ProcessingMetric(
            processingTime: processingTime,
            wasCacheHit: wasCacheHit,
            timestamp: Date()
        )
        
        performanceMetrics.append(metric)
        
        // Keep only recent metrics
        if performanceMetrics.count > maxMetricsHistory {
            performanceMetrics.removeFirst()
        }
        
        updatePerformanceStatistics()
    }
    
    private func recordCacheHit() {
        recordProcessingMetric(processingTime: 0, wasCacheHit: true)
    }
    
    private func recordDeduplication() {
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
            clearExpiredCache()
        case .critical, .emergency:
            // Clear all cache
            clearAllCache()
            // Reduce concurrency
            operationQueue.maxConcurrentOperationCount = max(1, operationQueue.maxConcurrentOperationCount - 1)
        case .normal:
            // Restore normal concurrency
            operationQueue.maxConcurrentOperationCount = PipelineConfig.maxConcurrentOperations
        }
    }
    
    // MARK: - Cache Cleanup
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.clearExpiredCache()
        }
    }
    
    private func clearExpiredCache() {
        cacheQueue.async(flags: .barrier) {
            let now = Date()
            self.processingCache = self.processingCache.filter { _, cached in
                now.timeIntervalSince(cached.timestamp) < PipelineConfig.cacheRetentionTime
            }
        }
    }
    
    private func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.processingCache.removeAll()
        }
    }
}

// MARK: - Supporting Types

private struct CachedResult {
    let result: Any
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > OptimizedProcessingPipeline.PipelineConfig.cacheRetentionTime
    }
}

private struct ProcessingMetric {
    let processingTime: TimeInterval
    let wasCacheHit: Bool
    let timestamp: Date
}

private class ProcessingOperation<T>: Operation, @unchecked Sendable {
    let cacheKey: String
    private let processor: () async throws -> T
    
    var result: T?
    var error: Error?
    
    private var _isExecuting = false
    private var _isFinished = false
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    init(cacheKey: String, processor: @escaping () async throws -> T) {
        self.cacheKey = cacheKey
        self.processor = processor
        super.init()
    }
    
    override func start() {
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        Task {
            do {
                result = try await processor()
            } catch {
                self.error = error
            }
            
            _isExecuting = false
            _isFinished = true
        }
    }
}

enum ProcessingError: Error {
    case operationFailed
    case invalidOperation
}

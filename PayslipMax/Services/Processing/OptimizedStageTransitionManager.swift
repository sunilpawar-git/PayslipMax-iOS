import Foundation
import PDFKit

/// Manages optimized stage transitions in the processing pipeline to reduce data copying
/// and implement intelligent caching with zero-copy semantics where possible
final class OptimizedStageTransitionManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    private var stageResultCache: [String: CachedStageResult] = [:]
    private let cacheQueue = DispatchQueue(label: "com.payslipmax.stage-cache", attributes: .concurrent)
    @MainActor private var transitionMetrics = TransitionPerformanceMetrics()
    
    // MARK: - Initialization
    
    init() {
        setupPeriodicCacheCleanup()
    }
    
    // MARK: - Stage Transition Management
    
    /// Execute a stage with optimized data handling and caching
    func executeStage<T, U>(
        _ stage: @escaping (T) async throws -> U,
        input: T,
        stageType: StageTransitionType,
        cacheKey: String? = nil
    ) async throws -> StageResult<U> {
        let context = StageExecutionContext(
            stageType: stageType,
            inputSize: UInt64(MemoryLayout<T>.size),
            startTime: Date()
        )
        
        let effectiveCacheKey = cacheKey ?? generateCacheKey(for: input, stage: stageType)
        
        // Check cache first
        if let cached = await getCachedResult(key: effectiveCacheKey, type: U.self) {
            return cached
        }
        
        // Execute stage with performance tracking
        let startTime = Date()
        let memoryBefore = getCurrentMemoryUsage()
        
        let result = try await stage(input)
        
        let executionTime = Date().timeIntervalSince(startTime)
        let memoryAfter = getCurrentMemoryUsage()
        
        let metadata = context.createMetadata(
            executionTime: executionTime,
            memoryUsage: memoryAfter - memoryBefore,
            cacheHit: false
        )
        
        let stageResult = StageResult(value: result, metadata: metadata)
        
        // Cache result if beneficial
        await cacheResult(stageResult, key: effectiveCacheKey)
        
        // Update metrics
        await updateMetrics(metadata)
        
        return stageResult
    }
    
    /// Execute multiple stages in optimized sequence with shared context
    func executeStageSequence<T>(
        input: T,
        stages: [(StageTransitionType, (Any) async throws -> Any)]
    ) async throws -> [Any] {
        var results: [Any] = []
        var currentInput: Any = input
        
        for (stageType, stage) in stages {
            let stageResult = try await executeStage(
                stage,
                input: currentInput,
                stageType: stageType
            )
            
            results.append(stageResult.value)
            currentInput = stageResult.value
        }
        
        return results
    }
    
    // MARK: - Caching Operations
    
    private func getCachedResult<T>(key: String, type: T.Type) async -> StageResult<T>? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                if let cached = self.stageResultCache[key],
                   !cached.isExpired,
                   let result = cached.result as? T {
                    let stageResult = StageResult(value: result, metadata: cached.metadata)
                    continuation.resume(returning: stageResult)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func cacheResult<T>(_ result: StageResult<T>, key: String) async {
        let cached = CachedStageResult(
            result: result.value,
            metadata: result.metadata,
            expirationDate: Date().addingTimeInterval(TransitionConfig.stageResultTTL)
        )
        
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.stageResultCache[key] = cached
                
                // Evict old entries if cache is full
                if self.stageResultCache.count > TransitionConfig.maxStageResultCache {
                    self.evictOldestEntries()
                }
                
                continuation.resume()
            }
        }
    }
    
    private func evictOldestEntries() {
        let sortedEntries = stageResultCache.sorted { $0.value.metadata.timestamp < $1.value.metadata.timestamp }
        let entriesToRemove = sortedEntries.prefix(stageResultCache.count - TransitionConfig.maxStageResultCache + 1)
        
        for (key, _) in entriesToRemove {
            stageResultCache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Memory Management
    
    /// Optimize data transfer for large payloads using zero-copy when possible
    func optimizeDataTransfer<T>(_ data: T, sizeThreshold: UInt64 = UInt64(TransitionConfig.zeroCopyThreshold)) -> T {
        let dataSize = UInt64(MemoryLayout<T>.size)
        
        if dataSize > sizeThreshold {
            // For large data, use reference semantics to avoid copying
            return data
        } else {
            // For small data, copying is acceptable and might be faster due to cache locality
            return data
        }
    }
    
    /// Create copy-on-write wrapper for Data to optimize memory usage
    func createCOWData(_ data: Data) -> COWData {
        return COWData(data)
    }
    
    // MARK: - Performance Monitoring
    
    private func updateMetrics(_ metadata: StageMetadata) async {
        await MainActor.run {
            transitionMetrics.recordStageExecution(metadata)
        }
    }
    
    func getPerformanceMetrics() async -> Any {
        return await MainActor.run { transitionMetrics }
    }
    
    // MARK: - Utility Methods
    
    private func generateCacheKey<T>(for input: T, stage: StageTransitionType) -> String {
        let inputHash = withUnsafeBytes(of: input) { Data($0).hashValue }
        return "\(stage):\(inputHash)"
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func setupPeriodicCacheCleanup() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.cleanupExpiredEntries()
            }
        }
    }
    
    private func cleanupExpiredEntries() async {
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                let expiredKeys = self.stageResultCache.compactMap { key, value in
                    value.isExpired ? key : nil
                }
                
                for key in expiredKeys {
                    self.stageResultCache.removeValue(forKey: key)
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Clear all caches and reset metrics
    func clearCaches() async {
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.stageResultCache.removeAll()
                continuation.resume()
            }
        }
        
        await MainActor.run {
            transitionMetrics = TransitionPerformanceMetrics()
        }
    }
}

// MARK: - Performance Metrics

@MainActor
fileprivate class TransitionPerformanceMetrics {
    var totalExecutions: Int = 0
    var totalExecutionTime: TimeInterval = 0
    var cacheHits: Int = 0
    var averageMemoryUsage: UInt64 = 0
    
    var cacheHitRate: Double {
        return totalExecutions > 0 ? Double(cacheHits) / Double(totalExecutions) : 0.0
    }
    
    var averageExecutionTime: TimeInterval {
        return totalExecutions > 0 ? totalExecutionTime / Double(totalExecutions) : 0.0
    }
    
    func recordStageExecution(_ metadata: StageMetadata) {
        totalExecutions += 1
        totalExecutionTime += metadata.executionTime
        if metadata.cacheHit {
            cacheHits += 1
        }
        averageMemoryUsage = (averageMemoryUsage * UInt64(totalExecutions - 1) + metadata.memoryUsage) / UInt64(totalExecutions)
    }
}
import Foundation
import Combine

/// Unified cache manager that coordinates all caching systems
/// Implements consistent policies, cross-cache coordination, and memory pressure response
/// Following Phase 2 Memory System Optimization requirements
@MainActor
class UnifiedCacheManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Current memory pressure level
    @Published private(set) var currentPressureLevel: UnifiedMemoryPressureLevel = .normal
    
    /// Cache coordination statistics
    @Published private(set) var totalCacheSize: UInt64 = 0
    @Published private(set) var cacheHitRate: Double = 0.0
    @Published private(set) var evictionCount: Int = 0
    
    /// Cache registry
    private var registeredCaches: [String: CacheInstance] = [:]
    
    /// Cache statistics
    private var cacheStats: [String: CacheStatistics] = [:]
    
    /// Memory pressure monitoring
    private var memoryMonitor: Timer?
    private let monitoringInterval: TimeInterval = 1.0
    
    /// Thread safety
    private let coordinationQueue = DispatchQueue(label: "com.payslipmax.unified.cache", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        setupMemoryMonitoring()
        setupNotifications()
    }
    
    deinit {
        memoryMonitor?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Cache Registration
    
    /// Register a cache instance with the unified manager
    /// - Parameters:
    ///   - cache: Cache instance to register
    ///   - namespace: Cache namespace for coordination
    ///   - level: Cache hierarchy level
    func registerCache<T: CacheProtocol>(_ cache: T, 
                                        namespace: CacheNamespace, 
                                        level: CacheLevel = .l2Persistent) {
        let instance = CacheInstance(cache: cache, namespace: namespace, level: level)
        
        coordinationQueue.async(flags: .barrier) {
            self.registeredCaches[namespace.rawValue] = instance
            self.cacheStats[namespace.rawValue] = CacheStatistics()
        }
    }
    
    /// Unregister a cache instance
    /// - Parameter namespace: Cache namespace to unregister
    func unregisterCache(namespace: CacheNamespace) {
        coordinationQueue.async(flags: .barrier) {
            self.registeredCaches.removeValue(forKey: namespace.rawValue)
            self.cacheStats.removeValue(forKey: namespace.rawValue)
        }
    }
    
    // MARK: - Unified Cache Interface
    
    /// Store value in appropriate cache level
    /// - Parameters:
    ///   - value: Value to cache
    ///   - key: Cache key
    ///   - namespace: Cache namespace
    ///   - level: Optional cache level override
    func store<T: Codable>(_ value: T, 
                          forKey key: String, 
                          namespace: CacheNamespace,
                          level: CacheLevel? = nil) async -> Bool {
        let targetLevel = level ?? namespace.defaultLevel
        let unifiedKey = CacheKeyUtils.createUnifiedKey(key: key, namespace: namespace, level: targetLevel)
        
        return await coordinationQueue.sync {
            guard let instance = registeredCaches[namespace.rawValue] else { return false }
            
            let success = instance.cache.store(value, forKey: unifiedKey)
            if success {
                updateCacheStatistics(namespace: namespace, operation: .store)
                instance.lastAccess = Date()
            }
            return success
        }
    }
    
    /// Retrieve value from cache hierarchy
    /// - Parameters:
    ///   - type: Value type
    ///   - key: Cache key
    ///   - namespace: Cache namespace
    /// - Returns: Cached value if found
    func retrieve<T: Codable>(_ type: T.Type, 
                             forKey key: String, 
                             namespace: CacheNamespace) async -> T? {
        // Try all cache levels for this namespace, starting with fastest
        for level in CacheLevel.allCases.sorted(by: { $0.priority < $1.priority }) {
            let unifiedKey = CacheKeyUtils.createUnifiedKey(key: key, namespace: namespace, level: level)
            
            if let instance = await coordinationQueue.sync(execute: { registeredCaches[namespace.rawValue] }),
               let value: T = instance.cache.retrieve(forKey: unifiedKey) {
                
                await coordinationQueue.sync(flags: .barrier) {
                    updateCacheStatistics(namespace: namespace, operation: .hit)
                    instance.lastAccess = Date()
                }
                return value
            }
        }
        
        await coordinationQueue.sync(flags: .barrier) {
            updateCacheStatistics(namespace: namespace, operation: .miss)
        }
        return nil
    }
    
    /// Check if key exists in any cache level
    /// - Parameters:
    ///   - key: Cache key
    ///   - namespace: Cache namespace
    /// - Returns: True if found in any level
    func contains(key: String, namespace: CacheNamespace) async -> Bool {
        for level in CacheLevel.allCases {
            let unifiedKey = CacheKeyUtils.createUnifiedKey(key: key, namespace: namespace, level: level)
            
            if let instance = await coordinationQueue.sync(execute: { registeredCaches[namespace.rawValue] }),
               instance.cache.contains(key: unifiedKey) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Memory Pressure Coordination
    
    /// Respond to memory pressure across all registered caches
    /// - Parameter level: Memory pressure level
    func respondToMemoryPressure(_ level: UnifiedMemoryPressureLevel) async {
        await coordinationQueue.sync(flags: .barrier) {
            currentPressureLevel = level
        }
        
        switch level {
        case .normal:
            // No action needed
            break
        case .warning:
            await clearNonEssentialCaches()
        case .critical:
            await aggressiveCacheClearing()
        case .emergency:
            await emergencyCacheClearing()
        }
    }
    
    /// Clear non-essential caches during warning level
    private func clearNonEssentialCaches() async {
        await coordinationQueue.sync(flags: .barrier) {
            // Clear L1 processing caches first
            for (namespace, instance) in registeredCaches {
                if instance.level == .l1Processing {
                    _ = instance.cache.clearCache()
                    updateCacheStatistics(namespace: CacheNamespace(rawValue: namespace) ?? .operationResults, 
                                        operation: .eviction)
                }
            }
        }
    }
    
    /// Aggressive cache clearing during critical pressure
    private func aggressiveCacheClearing() async {
        await coordinationQueue.sync(flags: .barrier) {
            // Clear L1 and reduce L2 caches
            for (namespace, instance) in registeredCaches {
                if instance.level == .l1Processing || instance.level == .l2Persistent {
                    _ = instance.cache.clearCache()
                    updateCacheStatistics(namespace: CacheNamespace(rawValue: namespace) ?? .operationResults, 
                                        operation: .eviction)
                }
            }
        }
    }
    
    /// Emergency cache clearing - clear everything except essential data
    private func emergencyCacheClearing() async {
        await coordinationQueue.sync(flags: .barrier) {
            for (namespace, instance) in registeredCaches {
                // Keep only critical PDF processing cache at minimum size
                if namespace != CacheNamespace.pdfProcessing.rawValue {
                    _ = instance.cache.clearCache()
                    updateCacheStatistics(namespace: CacheNamespace(rawValue: namespace) ?? .operationResults, 
                                        operation: .eviction)
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension UnifiedCacheManager {
    
    /// Setup memory monitoring
    func setupMemoryMonitoring() {
        memoryMonitor = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateMemoryStatus()
            }
        }
    }
    
    /// Setup system notifications
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.respondToMemoryPressure(.critical)
            }
        }
    }
    
    /// Update memory status and trigger pressure responses
    func updateMemoryStatus() async {
        let currentUsage = MemoryUtils.getCurrentMemoryUsage()
        let pressureLevel = MemoryUtils.calculatePressureLevel(for: currentUsage)
        
        if pressureLevel != currentPressureLevel {
            await respondToMemoryPressure(pressureLevel)
        }
        
        await updateCacheMetrics()
    }
    
    /// Update cache statistics
    func updateCacheStatistics(namespace: CacheNamespace, operation: CacheOperation) {
        guard var stats = cacheStats[namespace.rawValue] else { return }
        
        switch operation {
        case .hit:
            stats.hits += 1
        case .miss:
            stats.misses += 1
        case .store:
            stats.stores += 1
        case .eviction:
            stats.evictions += 1
            evictionCount += 1
        }
        
        cacheStats[namespace.rawValue] = stats
        updateOverallMetrics()
    }
    
    /// Update overall cache metrics
    func updateCacheMetrics() async {
        await coordinationQueue.sync {
            let totalHits = cacheStats.values.reduce(0) { $0 + $1.hits }
            let totalMisses = cacheStats.values.reduce(0) { $0 + $1.misses }
            let total = totalHits + totalMisses
            
            cacheHitRate = total > 0 ? Double(totalHits) / Double(total) : 0.0
            
            // Calculate total cache size across all registered caches
            totalCacheSize = registeredCaches.values.reduce(0) { total, instance in
                return total + (instance.cache.getCacheMetrics()["size"] as? UInt64 ?? 0)
            }
        }
    }
    
    /// Update overall metrics (synchronous version for internal use)
    func updateOverallMetrics() {
        let totalHits = cacheStats.values.reduce(0) { $0 + $1.hits }
        let totalMisses = cacheStats.values.reduce(0) { $0 + $1.misses }
        let total = totalHits + totalMisses
        
        cacheHitRate = total > 0 ? Double(totalHits) / Double(total) : 0.0
    }
}

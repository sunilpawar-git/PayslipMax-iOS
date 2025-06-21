import Foundation

/// Adaptive cache manager with memory pressure awareness
///
/// Following Phase 4B modular pattern: Focused responsibility for intelligent caching
/// Implements LRU eviction and memory pressure response for optimal performance
class AdaptiveCacheManager {
    
    // MARK: - Configuration
    
    /// Maximum cache size in bytes
    private let maxCacheSize: UInt64
    
    /// Maximum number of cached items
    private let maxCacheItems: Int
    
    /// Memory pressure threshold for cache eviction
    private let memoryPressureThreshold: UInt64
    
    // MARK: - Cache Storage
    
    /// Main cache storage
    private var cache: [String: CacheItem] = [:]
    
    /// LRU tracking list (most recent first)
    private var accessOrder: [String] = []
    
    /// Current cache size in bytes
    private var currentCacheSize: UInt64 = 0
    
    /// Cache hit statistics
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    /// Thread safety queue
    private let cacheQueue = DispatchQueue(label: "com.payslipmax.cache", attributes: .concurrent)
    
    // MARK: - Cache Item Structure
    
    private struct CacheItem {
        let value: String
        let size: UInt64
        let timestamp: Date
        
        init(value: String) {
            self.value = value
            self.size = UInt64(value.count * 2) // Unicode character estimation
            self.timestamp = Date()
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize adaptive cache manager
    /// - Parameters:
    ///   - maxCacheSize: Maximum cache size in bytes (default: 50MB)
    ///   - maxCacheItems: Maximum number of items (default: 100)
    ///   - memoryPressureThreshold: Memory pressure threshold (default: 150MB)
    init(
        maxCacheSize: UInt64 = 50 * 1024 * 1024, // 50MB
        maxCacheItems: Int = 100,
        memoryPressureThreshold: UInt64 = 150 * 1024 * 1024 // 150MB
    ) {
        self.maxCacheSize = maxCacheSize
        self.maxCacheItems = maxCacheItems
        self.memoryPressureThreshold = memoryPressureThreshold
    }
    
    // MARK: - Cache Operations
    
    /// Store value in cache with memory awareness
    /// - Parameters:
    ///   - value: String value to cache
    ///   - key: Cache key
    /// - Returns: True if successfully cached
    func store(_ value: String, forKey key: String) -> Bool {
        return cacheQueue.sync(flags: .barrier) {
            let newItem = CacheItem(value: value)
            
            // Check if adding this item would exceed limits
            if newItem.size > maxCacheSize {
                return false // Item too large for cache
            }
            
            // Remove existing item if present
            if let existingItem = cache[key] {
                currentCacheSize -= existingItem.size
                if let index = accessOrder.firstIndex(of: key) {
                    accessOrder.remove(at: index)
                }
            }
            
            // Ensure space for new item
            while (currentCacheSize + newItem.size > maxCacheSize) || 
                  (cache.count >= maxCacheItems) {
                if !evictLeastRecentlyUsed() {
                    break // No more items to evict
                }
            }
            
            // Check memory pressure and evict if necessary
            if isMemoryPressureHigh() {
                evictBasedOnMemoryPressure()
            }
            
            // Add new item
            cache[key] = newItem
            accessOrder.insert(key, at: 0) // Most recent first
            currentCacheSize += newItem.size
            
            return true
        }
    }
    
    /// Retrieve value from cache
    /// - Parameter key: Cache key
    /// - Returns: Cached value if found
    func retrieve(forKey key: String) -> String? {
        return cacheQueue.sync {
            if let item = cache[key] {
                // Update access order (move to front)
                if let index = accessOrder.firstIndex(of: key) {
                    accessOrder.remove(at: index)
                    accessOrder.insert(key, at: 0)
                }
                
                cacheHits += 1
                return item.value
            } else {
                cacheMisses += 1
                return nil
            }
        }
    }
    
    /// Remove specific item from cache
    /// - Parameter key: Cache key to remove
    func removeValue(forKey key: String) {
        cacheQueue.sync(flags: .barrier) {
            if let item = cache.removeValue(forKey: key) {
                currentCacheSize -= item.size
                if let index = accessOrder.firstIndex(of: key) {
                    accessOrder.remove(at: index)
                }
            }
        }
    }
    
    /// Clear entire cache
    func clearCache() {
        cacheQueue.sync(flags: .barrier) {
            cache.removeAll()
            accessOrder.removeAll()
            currentCacheSize = 0
        }
    }
    
    // MARK: - Cache Eviction Strategies
    
    /// Evict least recently used item
    /// - Returns: True if an item was evicted
    private func evictLeastRecentlyUsed() -> Bool {
        guard let lruKey = accessOrder.last,
              let lruItem = cache[lruKey] else {
            return false
        }
        
        cache.removeValue(forKey: lruKey)
        accessOrder.removeLast()
        currentCacheSize -= lruItem.size
        
        return true
    }
    
    /// Evict items based on memory pressure
    private func evictBasedOnMemoryPressure() {
        let targetEvictionCount = min(cache.count / 4, 10) // Evict 25% or max 10 items
        
        for _ in 0..<targetEvictionCount {
            if !evictLeastRecentlyUsed() {
                break
            }
        }
    }
    
    /// Evict items older than specified age
    /// - Parameter maxAge: Maximum age in seconds
    func evictItemsOlderThan(_ maxAge: TimeInterval) {
        cacheQueue.sync(flags: .barrier) {
            let cutoffDate = Date().addingTimeInterval(-maxAge)
            
            let keysToEvict = cache.compactMap { (key, item) in
                item.timestamp < cutoffDate ? key : nil
            }
            
            for key in keysToEvict {
                if let item = cache.removeValue(forKey: key) {
                    currentCacheSize -= item.size
                    if let index = accessOrder.firstIndex(of: key) {
                        accessOrder.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Monitoring
    
    /// Check if system memory pressure is high
    /// - Returns: True if memory pressure exceeds threshold
    private func isMemoryPressureHigh() -> Bool {
        let currentMemory = getCurrentMemoryUsage()
        return currentMemory > memoryPressureThreshold
    }
    
    /// Get current memory usage using shared utility
    /// - Returns: Current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        return MemoryUtils.getCurrentMemoryUsage()
    }
    
    // MARK: - Cache Statistics
    
    /// Get cache statistics
    /// - Returns: Tuple containing cache metrics
    func getCacheStatistics() -> (
        hitRatio: Double,
        itemCount: Int,
        sizeInBytes: UInt64,
        sizeInMB: Double
    ) {
        return cacheQueue.sync {
            let totalAccesses = cacheHits + cacheMisses
            let hitRatio = totalAccesses > 0 ? Double(cacheHits) / Double(totalAccesses) : 0.0
            let sizeInMB = Double(currentCacheSize) / (1024.0 * 1024.0)
            
            return (
                hitRatio: hitRatio,
                itemCount: cache.count,
                sizeInBytes: currentCacheSize,
                sizeInMB: sizeInMB
            )
        }
    }
    
    /// Reset cache statistics
    func resetStatistics() {
        cacheQueue.sync(flags: .barrier) {
            cacheHits = 0
            cacheMisses = 0
        }
    }
    
    /// Get memory pressure status
    /// - Returns: True if cache should reduce size due to memory pressure
    func shouldReduceCacheSize() -> Bool {
        return isMemoryPressureHigh() || (currentCacheSize > maxCacheSize * 3 / 4)
    }
    
    /// Perform adaptive cache maintenance
    func performMaintenance() {
        cacheQueue.sync(flags: .barrier) {
            // Remove items older than 1 hour
            evictItemsOlderThan(3600)
            
            // If memory pressure is high, evict additional items
            if isMemoryPressureHigh() {
                evictBasedOnMemoryPressure()
            }
        }
    }
} 
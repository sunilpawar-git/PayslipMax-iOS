import Foundation

/// Bridge adapters for migrating existing cache systems to UnifiedCacheManager
/// Ensures smooth transition while maintaining performance and data integrity

// MARK: - PDFProcessingCache Bridge
/// Adapter that makes PDFProcessingCache conform to CacheProtocol
class PDFProcessingCacheBridge: CacheProtocol {
    private let pdfCache: PDFProcessingCache
    
    init(pdfCache: PDFProcessingCache = PDFProcessingCache.shared) {
        self.pdfCache = pdfCache
    }
    
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool {
        return pdfCache.store(value, forKey: key)
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        return pdfCache.retrieve(forKey: key)
    }
    
    func contains(key: String) -> Bool {
        return pdfCache.contains(key: key)
    }
    
    func clearCache() -> Bool {
        return pdfCache.clearCache()
    }
    
    func getCacheMetrics() -> [String: Any] {
        let metrics = pdfCache.getCacheMetrics()
        return [
            "size": calculateCacheSize(),
            "hit_ratio": pdfCache.getHitRatio(),
            "type": "PDFProcessingCache",
            "levels": "memory+disk",
            "metrics": metrics
        ]
    }
    
    private func calculateCacheSize() -> UInt64 {
        // Estimate cache size from metrics
        if let metrics = getCacheMetrics()["metrics"] as? [String: Any],
           let diskSize = metrics["disk_size"] as? UInt64,
           let memorySize = metrics["memory_size"] as? UInt64 {
            return diskSize + memorySize
        }
        return 0
    }
}

// MARK: - AdaptiveCacheManager Bridge
/// Adapter that makes AdaptiveCacheManager conform to CacheProtocol
class AdaptiveCacheManagerBridge: CacheProtocol {
    private let adaptiveCache: AdaptiveCacheManager
    
    init(adaptiveCache: AdaptiveCacheManager) {
        self.adaptiveCache = adaptiveCache
    }
    
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(value)
            let stringValue = String(data: data, encoding: .utf8) ?? ""
            adaptiveCache.store(stringValue, forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        guard let stringValue = adaptiveCache.retrieve(forKey: key),
              let data = stringValue.data(using: .utf8) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
    
    func contains(key: String) -> Bool {
        return adaptiveCache.retrieve(forKey: key) != nil
    }
    
    func clearCache() -> Bool {
        adaptiveCache.clearCache()
        return true
    }
    
    func getCacheMetrics() -> [String: Any] {
        return [
            "size": adaptiveCache.getCurrentCacheSize(),
            "hit_ratio": adaptiveCache.getHitRate(),
            "type": "AdaptiveCacheManager",
            "levels": "memory_lru",
            "items": adaptiveCache.getCacheItemCount()
        ]
    }
}

// MARK: - OptimizedProcessingPipeline Cache Bridge
/// Adapter for OptimizedProcessingPipeline's internal cache
class ProcessingPipelineCacheBridge: CacheProtocol {
    private let pipeline: OptimizedProcessingPipeline
    
    init(pipeline: OptimizedProcessingPipeline) {
        self.pipeline = pipeline
    }
    
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool {
        // OptimizedProcessingPipeline manages its own cache internally
        // This is a read-only bridge for metrics and clearing
        return false // Direct storage not supported
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        // Direct retrieval not supported - pipeline manages internally
        return nil
    }
    
    func contains(key: String) -> Bool {
        // Not directly queryable
        return false
    }
    
    func clearCache() -> Bool {
        pipeline.clearProcessingCache()
        return true
    }
    
    func getCacheMetrics() -> [String: Any] {
        return [
            "size": estimateInternalCacheSize(),
            "hit_ratio": pipeline.cacheHitRate,
            "type": "OptimizedProcessingPipeline",
            "levels": "processing_deduplication",
            "avg_processing_time": pipeline.averageProcessingTime,
            "redundancy_reduction": pipeline.redundancyReduction
        ]
    }
    
    private func estimateInternalCacheSize() -> UInt64 {
        // Estimate based on processing metrics
        // This is an approximation since pipeline doesn't expose size directly
        return UInt64(pipeline.cacheHitRate * 10 * 1024 * 1024) // Rough estimate
    }
}

// MARK: - Memory Cache Bridge (NSCache-based systems)
/// Generic bridge for NSCache-based cache systems
class NSCacheBridge<KeyType: NSObject, ValueType: NSObject>: CacheProtocol where KeyType: NSCopying {
    private let nsCache: NSCache<KeyType, ValueType>
    private let keyConverter: (String) -> KeyType
    private let valueConverter: (Any) -> ValueType?
    private let reverseConverter: (ValueType) -> Any?
    
    init(
        nsCache: NSCache<KeyType, ValueType>,
        keyConverter: @escaping (String) -> KeyType,
        valueConverter: @escaping (Any) -> ValueType?,
        reverseConverter: @escaping (ValueType) -> Any?
    ) {
        self.nsCache = nsCache
        self.keyConverter = keyConverter
        self.valueConverter = valueConverter
        self.reverseConverter = reverseConverter
    }
    
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool {
        guard let convertedValue = valueConverter(value) else { return false }
        let convertedKey = keyConverter(key)
        nsCache.setObject(convertedValue, forKey: convertedKey)
        return true
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        let convertedKey = keyConverter(key)
        guard let value = nsCache.object(forKey: convertedKey),
              let reconverted = reverseConverter(value) as? T else {
            return nil
        }
        return reconverted
    }
    
    func contains(key: String) -> Bool {
        let convertedKey = keyConverter(key)
        return nsCache.object(forKey: convertedKey) != nil
    }
    
    func clearCache() -> Bool {
        nsCache.removeAllObjects()
        return true
    }
    
    func getCacheMetrics() -> [String: Any] {
        return [
            "size": estimateNSCacheSize(),
            "hit_ratio": 0.0, // NSCache doesn't provide hit ratio
            "type": "NSCache",
            "levels": "memory",
            "name": nsCache.name ?? "unnamed"
        ]
    }
    
    private func estimateNSCacheSize() -> UInt64 {
        // NSCache doesn't provide direct size access
        // Return cost limit as approximation
        return UInt64(nsCache.totalCostLimit)
    }
}

// MARK: - DocumentAnalysis Cache Bridge
/// Bridge for DocumentAnalysisCoordinator's internal cache
class DocumentAnalysisCacheBridge: CacheProtocol {
    private var analysisCache: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "document.analysis.cache", attributes: .concurrent)
    private var hitCount = 0
    private var missCount = 0
    
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool {
        cacheQueue.async(flags: .barrier) {
            self.analysisCache[key] = value
        }
        return true
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        return cacheQueue.sync {
            if let value = analysisCache[key] as? T {
                hitCount += 1
                return value
            }
            missCount += 1
            return nil
        }
    }
    
    func contains(key: String) -> Bool {
        return cacheQueue.sync {
            return analysisCache[key] != nil
        }
    }
    
    func clearCache() -> Bool {
        cacheQueue.async(flags: .barrier) {
            self.analysisCache.removeAll()
        }
        return true
    }
    
    func getCacheMetrics() -> [String: Any] {
        return cacheQueue.sync {
            let total = hitCount + missCount
            return [
                "size": UInt64(analysisCache.count * 1024), // Rough estimate
                "hit_ratio": total > 0 ? Double(hitCount) / Double(total) : 0.0,
                "type": "DocumentAnalysisCache",
                "levels": "memory_dict",
                "items": analysisCache.count
            ]
        }
    }
}


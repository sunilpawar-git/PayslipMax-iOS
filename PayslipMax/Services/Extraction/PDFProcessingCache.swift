import Foundation
import PDFKit

/// Protocol for PDF processing cache
protocol PDFProcessingCacheProtocol {
    /// Store result in the cache
    /// - Parameters:
    ///   - result: The result to cache
    ///   - key: The key to store the result under
    /// - Returns: True if successful, false otherwise
    func store<T>(_ result: T, forKey key: String) -> Bool where T: Codable
    
    /// Retrieve a result from the cache
    /// - Parameter key: The key to retrieve
    /// - Returns: The cached result, or nil if not found
    func retrieve<T>(forKey key: String) -> T? where T: Codable
    
    /// Check if a key exists in the cache
    /// - Parameter key: The key to check
    /// - Returns: True if found, false otherwise
    func contains(key: String) -> Bool
    
    /// Remove an item from the cache
    /// - Parameter key: The key to remove
    /// - Returns: True if removed, false otherwise
    func removeItem(forKey key: String) -> Bool
    
    /// Clear the entire cache
    /// - Returns: True if successful, false otherwise
    func clearCache() -> Bool
    
    /// Get cache hit ratio
    /// - Returns: Cache hit ratio (0.0-1.0)
    func getHitRatio() -> Double
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache statistics
    func getCacheMetrics() -> [String: Any]
}

/// Multi-level cache for PDF processing results
class PDFProcessingCache: PDFProcessingCacheProtocol {
    // MARK: - Cache Levels
    
    /// Defines the different cache levels
    enum CacheLevel: Int, CaseIterable {
        case memory = 0
        case disk = 1
    }
    
    // MARK: - Cache Statistics
    
    /// Statistics for measuring cache performance
    private struct CacheStats {
        var hits: Int = 0
        var misses: Int = 0
        var writes: Int = 0
        var evictions: Int = 0
        
        var hitRatio: Double {
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0.0
        }
    }
    
    // MARK: - Properties
    
    /// In-memory cache for fastest access
    private let memoryCache = NSCache<NSString, NSData>()
    
    /// Cache directory for disk storage
    private let cacheDirectory: URL
    
    /// Queue for synchronizing cache operations
    private let cacheQueue = DispatchQueue(label: "com.payslipmax.pdfcache", attributes: .concurrent)
    
    /// Statistics for cache performance monitoring
    private var stats = CacheStats()
    
    /// Maximum memory cache size (in bytes)
    private let maxMemoryCacheSize: Int
    
    /// Maximum disk cache size (in bytes)
    private let maxDiskCacheSize: Int
    
    /// Cache expiration time (in seconds)
    private let cacheExpirationTime: TimeInterval
    
    /// Identifier for marking the files in the cache directory
    private let cacheIdentifier = "com.payslipmax.pdfcache"
    
    // MARK: - Initialization
    
    /// Initialize a new PDF processing cache
    /// - Parameters:
    ///   - memoryCacheSize: Maximum size of the memory cache in MB (default: 50MB)
    ///   - diskCacheSize: Maximum size of the disk cache in MB (default: 200MB)
    ///   - expirationTime: Cache expiration time in hours (default: 24 hours)
    init(memoryCacheSize: Int = 50, diskCacheSize: Int = 200, expirationTime: TimeInterval = 24 * 3600) {
        self.maxMemoryCacheSize = memoryCacheSize * 1024 * 1024
        self.maxDiskCacheSize = diskCacheSize * 1024 * 1024
        self.cacheExpirationTime = expirationTime
        
        // Create cache directory in the app's cache directory
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("PDFProcessingCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("[PDFProcessingCache] Failed to create cache directory: \(error)")
            }
        }
        
        // Configure memory cache
        memoryCache.name = "PDFProcessingMemoryCache"
        memoryCache.totalCostLimit = maxMemoryCacheSize
        
        // Start monitoring for cache cleanup
        setupCacheMonitoring()
    }
    
    // MARK: - PDFProcessingCacheProtocol Implementation
    
    /// Store result in the cache
    /// - Parameters:
    ///   - result: The result to cache
    ///   - key: The key to store the result under
    /// - Returns: True if successful, false otherwise
    func store<T>(_ result: T, forKey key: String) -> Bool where T: Codable {
        do {
            let data = try JSONEncoder().encode(result)
            
            // Store in memory cache
            cacheQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                self.stats.writes += 1
            }
            
            // Store in disk cache
            let fileURL = cacheFileURL(for: key)
            try data.write(to: fileURL)
            
            // Update file attributes with timestamp
            try FileManager.default.setAttributes([
                .creationDate: Date(),
                .modificationDate: Date()
            ], ofItemAtPath: fileURL.path)
            
            return true
        } catch {
            print("[PDFProcessingCache] Failed to store cache item: \(error)")
            return false
        }
    }
    
    /// Retrieve a result from the cache
    /// - Parameter key: The key to retrieve
    /// - Returns: The cached result, or nil if not found
    func retrieve<T>(forKey key: String) -> T? where T: Codable {
        var result: T?
        
        // Check memory cache first (synchronously)
        if let cachedData = memoryCache.object(forKey: key as NSString) as Data? {
            do {
                result = try JSONDecoder().decode(T.self, from: cachedData)
                
                cacheQueue.async { [weak self] in
                    self?.stats.hits += 1
                }
                
                return result
            } catch {
                print("[PDFProcessingCache] Error decoding memory cache data: \(error)")
                // Continue to check disk cache
            }
        }
        
        // Check disk cache
        let fileURL = cacheFileURL(for: key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                result = try JSONDecoder().decode(T.self, from: data)
                
                // Update memory cache with disk data
                cacheQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    self.memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                    self.stats.hits += 1
                }
                
                // Update file access time
                try FileManager.default.setAttributes([
                    .modificationDate: Date()
                ], ofItemAtPath: fileURL.path)
                
                return result
            } catch {
                print("[PDFProcessingCache] Error reading disk cache: \(error)")
            }
        }
        
        // Cache miss
        cacheQueue.async { [weak self] in
            self?.stats.misses += 1
        }
        
        return nil
    }
    
    /// Check if a key exists in the cache
    /// - Parameter key: The key to check
    /// - Returns: True if found, false otherwise
    func contains(key: String) -> Bool {
        // Check memory cache
        if memoryCache.object(forKey: key as NSString) != nil {
            return true
        }
        
        // Check disk cache
        let fileURL = cacheFileURL(for: key)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Remove an item from the cache
    /// - Parameter key: The key to remove
    /// - Returns: True if removed, false otherwise
    func removeItem(forKey key: String) -> Bool {
        var success = true
        
        // Remove from memory cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeObject(forKey: key as NSString)
        }
        
        // Remove from disk cache
        let fileURL = cacheFileURL(for: key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("[PDFProcessingCache] Failed to remove item from disk cache: \(error)")
                success = false
            }
        }
        
        return success
    }
    
    /// Clear the entire cache
    /// - Returns: True if successful, false otherwise
    func clearCache() -> Bool {
        var success = true
        
        // Clear memory cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAllObjects()
        }
        
        // Clear disk cache
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("[PDFProcessingCache] Failed to clear disk cache: \(error)")
            success = false
        }
        
        return success
    }
    
    /// Get cache hit ratio
    /// - Returns: Cache hit ratio (0.0-1.0)
    func getHitRatio() -> Double {
        var hitRatio: Double = 0.0
        
        cacheQueue.sync {
            hitRatio = stats.hitRatio
        }
        
        return hitRatio
    }
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache statistics
    func getCacheMetrics() -> [String: Any] {
        var metrics: [String: Any] = [:]
        
        cacheQueue.sync {
            metrics = [
                "hits": stats.hits,
                "misses": stats.misses,
                "writes": stats.writes,
                "evictions": stats.evictions,
                "hitRatio": stats.hitRatio,
                "memoryItems": memoryCache.totalCostLimit,
                "diskCacheSize": getDiskCacheSize()
            ]
        }
        
        return metrics
    }
    
    // MARK: - Private Methods
    
    /// Create a file URL for a cache key
    /// - Parameter key: The cache key
    /// - Returns: A file URL for the key
    private func cacheFileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ".", with: "_")
        return cacheDirectory.appendingPathComponent("\(cacheIdentifier)_\(safeKey)")
    }
    
    /// Set up monitoring for cache cleanup
    private func setupCacheMonitoring() {
        // Add notification observer for app background/termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cleanupExpiredItems),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Schedule periodic cleanup
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3600) { [weak self] in
            self?.cleanupExpiredItems()
        }
    }
    
    /// Cleanup expired or excess cache items
    @objc private func cleanupExpiredItems() {
        let fileManager = FileManager.default
        
        do {
            // Check disk cache size
            if getDiskCacheSize() > maxDiskCacheSize {
                // Clean up based on last access time
                let files = try fileManager.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
                )
                
                let sortedFiles = try files.sorted { file1, file2 in
                    let date1 = try file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    let date2 = try file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    return date1 < date2
                }
                
                // Remove oldest files until under size limit
                var currentSize = getDiskCacheSize()
                var evictionCount = 0
                
                for file in sortedFiles {
                    if currentSize <= Int64(Double(maxDiskCacheSize) * 0.8) { // Keep removing until 80% of max
                        break
                    }
                    
                    let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    try fileManager.removeItem(at: file)
                    currentSize -= Int64(fileSize)
                    evictionCount += 1
                }
                
                cacheQueue.async { [weak self] in
                    self?.stats.evictions += evictionCount
                }
            }
            
            // Check for expired items
            let now = Date()
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            var expiredCount = 0
            
            for file in files {
                if let modificationDate = try file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   now.timeIntervalSince(modificationDate) > cacheExpirationTime {
                    try fileManager.removeItem(at: file)
                    expiredCount += 1
                }
            }
            
            if expiredCount > 0 {
                print("[PDFProcessingCache] Removed \(expiredCount) expired items")
                cacheQueue.async { [weak self] in
                    self?.stats.evictions += expiredCount
                }
            }
            
        } catch {
            print("[PDFProcessingCache] Error during cache cleanup: \(error)")
        }
    }
    
    /// Get the current size of the disk cache
    /// - Returns: Size in bytes
    private func getDiskCacheSize() -> Int64 {
        let fileManager = FileManager.default
        let prefetchKeys: Set<URLResourceKey> = [.fileSizeKey]
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: Array(prefetchKeys)
            )
            
            return try files.reduce(0) { result, fileURL in
                let resourceValues = try fileURL.resourceValues(forKeys: prefetchKeys)
                return result + Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            print("[PDFProcessingCache] Error calculating disk cache size: \(error)")
            return 0
        }
    }
}

// MARK: - Extensions

/// Extension for making PDF document compatible with the cache
extension PDFDocument {
    /// Generate a cache key for the document
    /// - Returns: A cache key string
    func cacheKey() -> String {
        if let documentURL = self.documentURL?.absoluteString {
            return "pdf_\(documentURL.hashValue)"
        } else if let documentData = self.dataRepresentation() {
            // Use hash of first 1KB of data for better performance
            let dataPrefix = documentData.prefix(1024)
            return "pdf_\(dataPrefix.hashValue)_\(pageCount)"
        } else {
            // Fallback using page count and text from first page
            var textHash = 0
            if let firstPage = self.page(at: 0)?.string {
                textHash = firstPage.prefix(100).hashValue
            }
            return "pdf_\(pageCount)_\(textHash)"
        }
    }
}

/// Extension for caching extracted text
extension String {
    /// Generate a cache key for extracted text
    /// - Parameter identifier: Optional identifier to differentiate similar texts
    /// - Returns: A cache key string
    func textCacheKey(identifier: String = "") -> String {
        let prefix = prefix(min(100, count))
        let suffix = suffix(min(100, count))
        return "text_\(identifier)_\(prefix.hashValue)_\(suffix.hashValue)_\(count)"
    }
} 
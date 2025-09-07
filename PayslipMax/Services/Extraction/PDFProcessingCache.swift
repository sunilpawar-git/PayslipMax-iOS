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
final class PDFProcessingCache: PDFProcessingCacheProtocol {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = PDFProcessingCache()
    
    // MARK: - Properties
    
    /// In-memory cache for fastest access
    private let memoryCache = NSCache<NSString, NSData>()
    
    /// Queue for synchronizing cache operations
    private let cacheQueue = DispatchQueue(label: "com.payslipmax.pdfcache", attributes: .concurrent)
    
    /// Cache configuration
    private let configuration: PDFCacheConfiguration
    
    /// Cache metrics handler
    private let metrics: PDFCacheMetrics
    
    /// Cache cleanup handler
    private let cleanup: PDFCacheCleanup
    
    // MARK: - Initialization
    
    /// Initialize a new PDF processing cache
    /// - Parameters:
    ///   - memoryCacheSize: Maximum size of the memory cache in MB (default: 50MB)
    ///   - diskCacheSize: Maximum size of the disk cache in MB (default: 200MB)
    ///   - expirationTime: Cache expiration time in hours (default: 24 hours)
    init(memoryCacheSize: Int = 50, diskCacheSize: Int = 200, expirationTime: TimeInterval = 24 * 3600) {
        self.configuration = PDFCacheConfiguration(
            memoryCacheSize: memoryCacheSize,
            diskCacheSize: diskCacheSize,
            expirationTime: expirationTime
        )
        self.metrics = PDFCacheMetrics()
        self.cleanup = PDFCacheCleanup(configuration: configuration, metrics: metrics)
        
        // Configure memory cache
        memoryCache.name = "PDFProcessingMemoryCache"
        memoryCache.totalCostLimit = configuration.maxMemoryCacheSize
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
                self.metrics.recordWrite()
            }
            
            // Store in disk cache
            let fileURL = configuration.fileURL(for: key)
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
                metrics.recordHit()
                return result
            } catch {
                print("[PDFProcessingCache] Error decoding memory cache data: \(error)")
                // Continue to check disk cache
            }
        }
        
        // Check disk cache
        let fileURL = configuration.fileURL(for: key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                result = try JSONDecoder().decode(T.self, from: data)
                
                // Update memory cache with disk data
                cacheQueue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    self.memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                }
                
                metrics.recordHit()
                
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
        metrics.recordMiss()
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
        let fileURL = configuration.fileURL(for: key)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Remove an item from the cache
    /// - Parameter key: The key to remove
    /// - Returns: True if removed, false otherwise
    func removeItem(forKey key: String) -> Bool {
        // Remove from memory cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeObject(forKey: key as NSString)
        }
        
        // Remove from disk cache using cleanup component
        return cleanup.removeItem(forKey: key)
    }
    
    /// Clear the entire cache
    /// - Returns: True if successful, false otherwise
    func clearCache() -> Bool {
        // Clear memory cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAllObjects()
        }
        
        // Clear disk cache using cleanup component
        return cleanup.clearAllCache()
    }
    
    /// Get cache hit ratio
    /// - Returns: Cache hit ratio (0.0-1.0)
    func getHitRatio() -> Double {
        return metrics.getHitRatio()
    }
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache statistics
    func getCacheMetrics() -> [String: Any] {
        let diskCacheSize = cleanup.getDiskCacheSize()
        return metrics.getCacheMetrics(memoryCache: memoryCache, diskCacheSize: diskCacheSize)
    }
    
}

// MARK: - Extensions

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

// MARK: - PDF Processing Cache Extension Methods

extension PDFProcessingCache {
    /// Store processed text with document identifier
    /// - Parameters:
    ///   - text: The extracted text to store
    ///   - documentId: Document identifier
    /// - Returns: True if stored successfully
    func storeProcessedText(_ text: String, for documentId: String) -> Bool {
        return store(text, forKey: "text_\(documentId)")
    }
    
    /// Retrieve processed text for document
    /// - Parameter documentId: Document identifier
    /// - Returns: The cached text if available
    func retrieveProcessedText(for documentId: String) -> String? {
        return retrieve(forKey: "text_\(documentId)")
    }
} 
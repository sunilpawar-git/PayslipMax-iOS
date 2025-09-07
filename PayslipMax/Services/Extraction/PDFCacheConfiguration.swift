import Foundation

/// Configuration for PDF processing cache
struct PDFCacheConfiguration {
    // MARK: - Constants
    
    /// Default cache identifier
    static let defaultIdentifier = "com.payslipmax.pdfcache"
    
    // MARK: - Properties
    
    /// Maximum memory cache size (in bytes)
    let maxMemoryCacheSize: Int
    
    /// Maximum disk cache size (in bytes)
    let maxDiskCacheSize: Int
    
    /// Cache expiration time (in seconds)
    let cacheExpirationTime: TimeInterval
    
    /// Cache directory for disk storage
    let cacheDirectory: URL
    
    /// Identifier for marking the files in the cache directory
    let cacheIdentifier: String
    
    // MARK: - Initialization
    
    /// Initialize cache configuration
    /// - Parameters:
    ///   - memoryCacheSize: Maximum size of the memory cache in MB (default: 50MB)
    ///   - diskCacheSize: Maximum size of the disk cache in MB (default: 200MB)
    ///   - expirationTime: Cache expiration time in hours (default: 24 hours)
    ///   - identifier: Cache identifier (default: com.payslipmax.pdfcache)
    init(memoryCacheSize: Int = 50, 
         diskCacheSize: Int = 200, 
         expirationTime: TimeInterval = 24 * 3600,
         identifier: String = PDFCacheConfiguration.defaultIdentifier) {
        self.maxMemoryCacheSize = memoryCacheSize * 1024 * 1024
        self.maxDiskCacheSize = diskCacheSize * 1024 * 1024
        self.cacheExpirationTime = expirationTime
        self.cacheIdentifier = identifier
        
        // Create cache directory in the app's cache directory
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("PDFProcessingCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Create cache directory if it doesn't exist
    func createCacheDirectoryIfNeeded() {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("[PDFCacheConfiguration] Failed to create cache directory: \(error)")
            }
        }
    }
    
    /// Create a file URL for a cache key
    /// - Parameter key: The cache key
    /// - Returns: A file URL for the key
    func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ".", with: "_")
        return cacheDirectory.appendingPathComponent("\(cacheIdentifier)_\(safeKey)")
    }
}

// MARK: - Cache Levels

/// Defines the different cache levels
enum CacheLevel: Int, CaseIterable {
    case memory = 0
    case disk = 1
}

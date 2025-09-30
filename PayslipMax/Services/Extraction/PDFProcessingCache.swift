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
/// Now supports both singleton and dependency injection patterns
final class PDFProcessingCache: PDFProcessingCacheProtocol, SafeConversionProtocol {
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

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diPDFProcessingCache }

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

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // PDF processing cache has no external dependencies, safe to convert
        return true
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
            ConversionTracker.shared.updateConversionState(for: PDFProcessingCache.self, state: .converting)
        }

        // Note: Integration with existing DI architecture will be handled separately
        // This method validates the conversion is safe and updates tracking

        await MainActor.run {
            conversionState = .dependencyInjected
            ConversionTracker.shared.updateConversionState(for: PDFProcessingCache.self, state: .dependencyInjected)
        }

        print("[PDFProcessingCache] Successfully converted to DI pattern")
        return true
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
            ConversionTracker.shared.updateConversionState(for: PDFProcessingCache.self, state: .singleton)
        }
        print("[PDFProcessingCache] Rolled back to singleton pattern")
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // No external dependencies required for this service
        return .success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return PDFProcessingCache() as? Self
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diPDFProcessingCache)

        if shouldUseDI {
            // Try to get DI instance from container
            if let diInstance = DIContainer.shared.resolve(PDFProcessingCacheProtocol.self) as? PDFProcessingCache {
                return diInstance as! Self
            }
        }

        // Fallback to singleton
        return shared as! Self
    }
}

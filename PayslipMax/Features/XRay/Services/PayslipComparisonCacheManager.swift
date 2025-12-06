import Foundation

// MARK: - Protocol

/// Protocol for caching payslip comparison results
protocol PayslipComparisonCacheManagerProtocol {
    /// Retrieves a cached comparison for the given payslip ID
    /// - Parameter id: The UUID of the payslip
    /// - Returns: The cached comparison, or nil if not found
    func getComparison(for id: UUID) -> PayslipComparison?

    /// Stores a comparison in the cache
    /// - Parameters:
    ///   - comparison: The comparison to cache
    ///   - id: The UUID of the payslip
    func setComparison(_ comparison: PayslipComparison, for id: UUID)

    /// Clears all cached comparisons
    func clearCache()

    /// Invalidates (removes) a specific comparison from the cache
    /// - Parameter id: The UUID of the payslip to invalidate
    func invalidateComparison(for id: UUID)
}

// MARK: - Implementation

/// Thread-safe cache manager for payslip comparisons
final class PayslipComparisonCacheManager: PayslipComparisonCacheManagerProtocol {

    // MARK: - Singleton

    static let shared = PayslipComparisonCacheManager()

    // MARK: - Properties

    /// In-memory cache storing comparisons by payslip UUID
    private var cache: [UUID: PayslipComparison] = [:]

    /// Concurrent queue for thread-safe cache access
    /// - Reads use sync (concurrent reads allowed)
    /// - Writes use async with barrier (exclusive write access)
    /// This ensures no race conditions when multiple threads access the cache
    private let queue = DispatchQueue(label: "com.payslipmax.xray.cache", attributes: .concurrent)

    /// Maximum number of cached comparisons before LRU eviction
    /// 50 items ≈ 10-25 KB memory usage (negligible)
    private let maxCacheSize = 50

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func getComparison(for id: UUID) -> PayslipComparison? {
        return queue.sync {
            return cache[id]
        }
    }

    func setComparison(_ comparison: PayslipComparison, for id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // Add to cache
            self.cache[id] = comparison

            // Enforce cache size limit (LRU eviction)
            if self.cache.count > self.maxCacheSize {
                // Remove oldest entry (simple FIFO for now)
                if let firstKey = self.cache.keys.first {
                    self.cache.removeValue(forKey: firstKey)
                }
            }
        }
    }

    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }

    func invalidateComparison(for id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: id)
        }
    }

    // MARK: - Internal (for testing)

    /// Returns the current cache size (for testing purposes)
    var cacheSize: Int {
        return queue.sync {
            return cache.count
        }
    }

    /// Waits for all pending async operations to complete (for testing purposes)
    func waitForPendingOperations() {
        queue.sync(flags: .barrier) {
            // Barrier sync ensures all previous async operations have completed
        }
    }
}

//
//  ClassificationCacheManager.swift
//  PayslipMax
//
//  Created for Phase 6: Performance Optimization
//  Manages intelligent caching for classification operations with memory efficiency
//

import Foundation

/// Protocol for classification caching operations
protocol ClassificationCacheManagerProtocol {
    /// Retrieves cached classification result
    /// - Parameter key: The cache key
    /// - Returns: Cached classification result or nil
    func getCachedClassification(for key: String) -> ComponentClassification?

    /// Stores classification result in cache
    /// - Parameters:
    ///   - key: The cache key
    ///   - classification: The classification result to cache
    func cacheClassification(_ classification: ComponentClassification, for key: String)

    /// Retrieves cached context classification result
    /// - Parameter key: The cache key
    /// - Returns: Cached context classification result or nil
    func getCachedContextClassification(for key: String) -> PayCodeClassificationResult?

    /// Stores context classification result in cache
    /// - Parameters:
    ///   - key: The cache key
    ///   - result: The classification result to cache
    func cacheContextClassification(_ result: PayCodeClassificationResult, for key: String)

    /// Clears all caches
    func clearAllCaches()

    /// Gets cache statistics
    /// - Returns: Tuple with cache sizes
    func getCacheStatistics() -> (classificationCacheSize: Int, contextCacheSize: Int)
}

/// Intelligent cache manager for classification operations
/// Provides memory-efficient caching with automatic cleanup
final class ClassificationCacheManager: ClassificationCacheManagerProtocol {

    // MARK: - Properties

    /// Cache for basic classification results
    private var classificationCache: [String: ComponentClassification] = [:]

    /// Cache for context-based classification results
    private var contextClassificationCache: [String: PayCodeClassificationResult] = [:]

    /// Maximum cache size for memory management
    private let maxCacheSize: Int = 500

    /// Access timestamps for LRU cache management
    private var accessTimestamps: [String: Date] = [:]

    /// Queue for thread-safe operations
    private let queue = DispatchQueue(label: "classification.cache.queue", qos: .utility)

    // MARK: - Public Methods

    /// Retrieves cached classification result
    func getCachedClassification(for key: String) -> ComponentClassification? {
        return queue.sync {
            guard let classification = classificationCache[key] else { return nil }

            // Update access timestamp for LRU management
            accessTimestamps[key] = Date()
            return classification
        }
    }

    /// Stores classification result in cache with memory management
    func cacheClassification(_ classification: ComponentClassification, for key: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // Clear cache if it gets too large
            if self.classificationCache.count >= self.maxCacheSize {
                self.clearOldestEntries()
            }

            self.classificationCache[key] = classification
            self.accessTimestamps[key] = Date()
        }
    }

    /// Retrieves cached context classification result
    func getCachedContextClassification(for key: String) -> PayCodeClassificationResult? {
        return queue.sync {
            guard let result = contextClassificationCache[key] else { return nil }

            // Update access timestamp for LRU management
            accessTimestamps[key] = Date()
            return result
        }
    }

    /// Stores context classification result in cache with memory management
    func cacheContextClassification(_ result: PayCodeClassificationResult, for key: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // Clear cache if it gets too large
            if self.contextClassificationCache.count >= self.maxCacheSize {
                self.clearOldestEntries()
            }

            self.contextClassificationCache[key] = result
            self.accessTimestamps[key] = Date()
        }
    }

    /// Clears all caches for memory management
    func clearAllCaches() {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.classificationCache.removeAll()
            self.contextClassificationCache.removeAll()
            self.accessTimestamps.removeAll()

            print("[ClassificationCacheManager] All caches cleared for memory optimization")
        }
    }

    /// Gets cache statistics for performance monitoring
    func getCacheStatistics() -> (classificationCacheSize: Int, contextCacheSize: Int) {
        return queue.sync {
            return (classificationCache.count, contextClassificationCache.count)
        }
    }

    // MARK: - Private Methods

    /// Clears oldest cache entries using LRU algorithm
    private func clearOldestEntries() {
        let totalEntries = classificationCache.count + contextClassificationCache.count
        let entriesToRemove = max(1, totalEntries / 4) // Remove 25% of total cache

        // Sort by access timestamp to find least recently used entries
        let sortedTimestamps = accessTimestamps.sorted { $0.value < $1.value }
        let keysToRemove = Array(sortedTimestamps.prefix(entriesToRemove).map { $0.key })

        var removedCount = 0
        for key in keysToRemove {
            if classificationCache.removeValue(forKey: key) != nil {
                removedCount += 1
            }
            if contextClassificationCache.removeValue(forKey: key) != nil {
                removedCount += 1
            }
            accessTimestamps.removeValue(forKey: key)
        }

        print("[ClassificationCacheManager] Cleared \(removedCount) oldest cache entries using LRU algorithm")
    }
}

// MARK: - Shared Instance

extension ClassificationCacheManager {
    /// Shared cache manager instance
    static let shared = ClassificationCacheManager()
}

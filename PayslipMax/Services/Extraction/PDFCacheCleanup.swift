import Foundation
import UIKit

/// Handles cache cleanup and maintenance for PDF processing cache
final class PDFCacheCleanup {
    // MARK: - Properties
    
    /// Cache configuration
    private let configuration: PDFCacheConfiguration
    
    /// Metrics instance for tracking evictions
    private weak var metrics: PDFCacheMetrics?
    
    /// Queue for cleanup operations
    private let cleanupQueue = DispatchQueue(label: "com.payslipmax.pdfcache.cleanup", qos: .background)
    
    // MARK: - Initialization
    
    /// Initialize cache cleanup manager
    /// - Parameters:
    ///   - configuration: Cache configuration
    ///   - metrics: Metrics instance for tracking
    init(configuration: PDFCacheConfiguration, metrics: PDFCacheMetrics? = nil) {
        self.configuration = configuration
        self.metrics = metrics
        
        setupCacheMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Cleanup expired or excess cache items
    func cleanupExpiredItems() {
        cleanupQueue.async { [weak self] in
            self?.performCleanup()
        }
    }
    
    /// Clear the entire cache
    /// - Returns: True if successful, false otherwise
    func clearAllCache() -> Bool {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: configuration.cacheDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                try fileManager.removeItem(at: file)
            }
            
            return true
        } catch {
            print("[PDFCacheCleanup] Failed to clear disk cache: \(error)")
            return false
        }
    }
    
    /// Remove specific item from disk cache
    /// - Parameter key: Cache key to remove
    /// - Returns: True if removed successfully
    func removeItem(forKey key: String) -> Bool {
        let fileURL = configuration.fileURL(for: key)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                return true
            } catch {
                print("[PDFCacheCleanup] Failed to remove item from disk cache: \(error)")
                return false
            }
        }
        
        return true // Item doesn't exist, consider it successful
    }
    
    /// Get the current size of the disk cache
    /// - Returns: Size in bytes
    func getDiskCacheSize() -> Int64 {
        let fileManager = FileManager.default
        let prefetchKeys: Set<URLResourceKey> = [.fileSizeKey]
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: configuration.cacheDirectory,
                includingPropertiesForKeys: Array(prefetchKeys)
            )
            
            return try files.reduce(0) { result, fileURL in
                let resourceValues = try fileURL.resourceValues(forKeys: prefetchKeys)
                return result + Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            print("[PDFCacheCleanup] Error calculating disk cache size: \(error)")
            return 0
        }
    }
    
    // MARK: - Private Methods
    
    /// Set up monitoring for cache cleanup
    private func setupCacheMonitoring() {
        // Add notification observer for app background/termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Schedule periodic cleanup
        schedulePeriodicCleanup()
    }
    
    /// Handle app going to background
    @objc private func handleAppBackground() {
        cleanupExpiredItems()
    }
    
    /// Schedule periodic cleanup
    private func schedulePeriodicCleanup() {
        cleanupQueue.asyncAfter(deadline: .now() + 3600) { [weak self] in
            self?.cleanupExpiredItems()
            self?.schedulePeriodicCleanup() // Reschedule
        }
    }
    
    /// Perform the actual cleanup operation
    private func performCleanup() {
        do {
            // First, clean up based on size if exceeded
            try cleanupBySize()
            
            // Then, clean up expired items
            try cleanupExpiredItemsInternal()
            
        } catch {
            print("[PDFCacheCleanup] Error during cache cleanup: \(error)")
        }
    }
    
    /// Clean up cache if size limit is exceeded
    private func cleanupBySize() throws {
        let currentSize = getDiskCacheSize()
        
        if currentSize > configuration.maxDiskCacheSize {
            // Clean up based on last access time
            let files = try FileManager.default.contentsOfDirectory(
                at: configuration.cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
            )
            
            let sortedFiles = try files.sorted { file1, file2 in
                let date1 = try file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                let date2 = try file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                return date1 < date2
            }
            
            // Remove oldest files until under size limit
            var updatedSize = currentSize
            var evictionCount = 0
            
            for file in sortedFiles {
                if updatedSize <= Int64(Double(configuration.maxDiskCacheSize) * 0.8) { // Keep removing until 80% of max
                    break
                }
                
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                try FileManager.default.removeItem(at: file)
                updatedSize -= Int64(fileSize)
                evictionCount += 1
            }
            
            if evictionCount > 0 {
                metrics?.recordEvictions(count: evictionCount)
                print("[PDFCacheCleanup] Evicted \(evictionCount) items due to size limit")
            }
        }
    }
    
    /// Clean up expired items
    private func cleanupExpiredItemsInternal() throws {
        let now = Date()
        let files = try FileManager.default.contentsOfDirectory(
            at: configuration.cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )
        
        var expiredCount = 0
        
        for file in files {
            if let modificationDate = try file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               now.timeIntervalSince(modificationDate) > configuration.cacheExpirationTime {
                try FileManager.default.removeItem(at: file)
                expiredCount += 1
            }
        }
        
        if expiredCount > 0 {
            metrics?.recordEvictions(count: expiredCount)
            print("[PDFCacheCleanup] Removed \(expiredCount) expired items")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

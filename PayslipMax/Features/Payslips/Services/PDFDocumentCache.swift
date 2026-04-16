import Foundation
import PDFKit

/// Protocol for PDF Document Cache to enable dependency injection
protocol PDFDocumentCacheProtocol {
    /// Cache a PDF document with the given key
    func cacheDocument(_ document: PDFDocument, for key: String)

    /// Retrieve a cached PDF document by key
    func getDocument(for key: String) -> PDFDocument?

    /// Clear all cached documents
    func clearCache()
}

/// PDF Document Cache for improved performance
/// Provides LRU cache functionality for PDFDocument objects
/// Now supports both singleton and dependency injection patterns
class PDFDocumentCache: PDFDocumentCacheProtocol {
    static let shared = PDFDocumentCache()

    private var cache: [String: PDFDocument] = [:]
    private let cacheLimit: Int
    private var lruKeys: [String] = []

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Dependencies including optional cacheLimit
    init(dependencies: [String: Any] = [:]) {
        if let limit = dependencies["cacheLimit"] as? Int {
            self.cacheLimit = limit
        } else {
            self.cacheLimit = 20 // Default value
        }
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    func cacheDocument(_ document: PDFDocument, for key: String) {
        // Remove least recently used if at capacity
        if cache.count >= cacheLimit && !lruKeys.isEmpty {
            if let lruKey = lruKeys.first {
                cache.removeValue(forKey: lruKey)
                lruKeys.removeFirst()
            }
        }

        // Add to cache
        cache[key] = document

        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)
    }

    func getDocument(for key: String) -> PDFDocument? {
        guard let document = cache[key] else { return nil }

        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)

        return document
    }

    func clearCache() {
        cache.removeAll()
        lruKeys.removeAll()
    }

}

import Foundation
import PDFKit

/// PDF Document Cache for improved performance
/// Provides LRU cache functionality for PDFDocument objects
class PDFDocumentCache {
    static let shared = PDFDocumentCache()
    
    private var cache: [String: PDFDocument] = [:]
    private let cacheLimit = 20
    private var lruKeys: [String] = []
    
    private init() {}
    
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

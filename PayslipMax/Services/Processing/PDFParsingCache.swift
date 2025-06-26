import Foundation
import PDFKit

/// Manages caching of PDF parsing results
final class PDFParsingCache {
    
    // MARK: - Types
    
    struct ParsingResult {
        let payslipItem: PayslipItem
        let confidence: ParsingConfidence
        let parserName: String
        let timestamp: Date
    }
    
    // MARK: - Properties
    
    private var cache: [String: ParsingResult] = [:]
    private let maxCacheSize: Int = 50
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    // MARK: - Public Methods
    
    /// Gets a cached result for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The cached result, if available and not expired
    func getCachedResult(for pdfDocument: PDFDocument) -> ParsingResult? {
        guard let documentID = generateDocumentID(for: pdfDocument),
              let cachedResult = cache[documentID] else {
            return nil
        }
        
        // Check if cache entry has expired
        if Date().timeIntervalSince(cachedResult.timestamp) > cacheExpirationTime {
            cache.removeValue(forKey: documentID)
            return nil
        }
        
        return cachedResult
    }
    
    /// Caches a parsing result for a PDF document
    /// - Parameters:
    ///   - result: The parsing result to cache
    ///   - pdfDocument: The PDF document
    func cacheResult(_ result: PDFParsingEngine.ParsingResult, for pdfDocument: PDFDocument) {
        guard let documentID = generateDocumentID(for: pdfDocument),
              let payslipItem = result.payslipItem else {
            return
        }
        
        // Clean up old entries if cache is getting too large
        cleanupCacheIfNeeded()
        
        let cacheEntry = ParsingResult(
            payslipItem: payslipItem,
            confidence: result.confidence,
            parserName: result.parserName,
            timestamp: Date()
        )
        
        cache[documentID] = cacheEntry
        print("[PDFParsingCache] Cached result for document \(documentID) from parser \(result.parserName)")
    }
    
    /// Clears the parsing cache
    func clearCache() {
        cache.removeAll()
        print("[PDFParsingCache] Cache cleared")
    }
    
    /// Gets cache statistics
    /// - Returns: Dictionary containing cache statistics
    func getCacheStatistics() -> [String: Any] {
        let totalEntries = cache.count
        let expiredEntries = cache.values.filter { entry in
            Date().timeIntervalSince(entry.timestamp) > cacheExpirationTime
        }.count
        
        let parserCounts = Dictionary(grouping: cache.values, by: { $0.parserName })
            .mapValues { $0.count }
        
        return [
            "totalEntries": totalEntries,
            "expiredEntries": expiredEntries,
            "parserCounts": parserCounts,
            "maxSize": maxCacheSize
        ]
    }
    
    // MARK: - Private Methods
    
    /// Generates a unique identifier for a PDF document
    /// - Parameter pdfDocument: The PDF document to identify
    /// - Returns: A unique identifier for the document, or nil if one cannot be generated
    private func generateDocumentID(for pdfDocument: PDFDocument) -> String? {
        // If the document has a URL, use its path
        if let url = pdfDocument.documentURL {
            return url.absoluteString
        }
        
        // Otherwise, generate an ID from the document's contents
        var contentHash = ""
        if let firstPage = pdfDocument.page(at: 0), let text = firstPage.string {
            // Use first 100 characters of text as a simple hash
            let prefix = String(text.prefix(100))
            contentHash = "\(prefix.hashValue)"
        }
        
        // Include page count in the ID to help with uniqueness
        return "pdf_\(pdfDocument.pageCount)_\(contentHash)"
    }
    
    /// Cleans up expired entries and enforces cache size limits
    private func cleanupCacheIfNeeded() {
        // Remove expired entries
        let now = Date()
        let expiredKeys = cache.compactMap { (key, value) in
            now.timeIntervalSince(value.timestamp) > cacheExpirationTime ? key : nil
        }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
        
        // If still over limit, remove oldest entries
        if cache.count >= maxCacheSize {
            let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheSize + 10) // Remove extra to avoid frequent cleanup
            
            for (key, _) in entriesToRemove {
                cache.removeValue(forKey: key)
            }
        }
    }
} 
import Foundation
import PDFKit

// MARK: - PDFDocument Extensions

extension PDFDocument {
    /// Generate a unique cache key for this document
    /// - Returns: A unique string identifier for caching purposes
    func uniqueCacheKey() -> String {
        // Simple implementation that combines unique identifier based on hash value and modification date
        let id = String(self.hashValue)
        let date = documentAttributes?["ModDate"] as? String ?? ""
        return "\(id)-\(date)"
    }
}
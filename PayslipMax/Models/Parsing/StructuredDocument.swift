import Foundation
import CoreGraphics

/// Represents a complete structured document with multiple pages
/// This is the main container for spatial parsing results
struct StructuredDocument: Codable, Identifiable {
    /// Unique identifier for this document
    let id: UUID
    /// Array of structured pages
    let pages: [StructuredPage]
    /// Document-level metadata
    let metadata: [String: String]
    /// Timestamp when this document was processed
    let processedAt: Date
    /// Total processing time in seconds
    let processingDuration: TimeInterval?
    
    /// Initializes a new structured document
    /// - Parameters:
    ///   - pages: Array of structured pages
    ///   - metadata: Document metadata (defaults to empty)
    ///   - processingDuration: Time taken to process (optional)
    init(
        pages: [StructuredPage],
        metadata: [String: String] = [:],
        processingDuration: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.pages = pages
        self.metadata = metadata
        self.processedAt = Date()
        self.processingDuration = processingDuration
    }
    
    // MARK: - Convenience Properties
    
    /// Total number of pages in the document
    var pageCount: Int {
        return pages.count
    }
    
    /// Total number of elements across all pages
    var totalElementCount: Int {
        return pages.reduce(0) { $0 + $1.elementCount }
    }
    
    /// All elements from all pages
    var allElements: [PositionalElement] {
        return pages.flatMap { $0.elements }
    }
    
    /// All labels from all pages
    var allLabels: [PositionalElement] {
        return allElements.filter { $0.type == .label }
    }
    
    /// All values from all pages
    var allValues: [PositionalElement] {
        return allElements.filter { $0.type == .value }
    }
    
    /// All headers from all pages
    var allHeaders: [PositionalElement] {
        return allElements.filter { $0.type == .header }
    }
    
    /// Original text content for backward compatibility
    var originalText: [String: String] {
        var result: [String: String] = [:]
        for page in pages {
            result["page_\(page.pageIndex + 1)"] = page.text
        }
        return result
    }
    
    // MARK: - Document Analysis Methods
    
    /// Finds elements matching specific criteria across all pages
    /// - Parameter predicate: Filtering predicate
    /// - Returns: Array of matching elements
    func findElements(matching predicate: (PositionalElement) -> Bool) -> [PositionalElement] {
        return allElements.filter(predicate)
    }
    
    /// Gets elements from a specific page
    /// - Parameter pageIndex: 0-based page index
    /// - Returns: Array of elements on that page, or empty array if page doesn't exist
    func elementsOnPage(_ pageIndex: Int) -> [PositionalElement] {
        guard pageIndex >= 0 && pageIndex < pages.count else {
            return []
        }
        return pages[pageIndex].elements
    }
    
    /// Detects table structures across all pages
    /// - Returns: Dictionary with page index as key and table regions as value
    func detectAllTableStructures() -> [Int: [CGRect]] {
        var tableStructures: [Int: [CGRect]] = [:]
        
        for page in pages {
            let tableRegions = page.detectTableRegions()
            if !tableRegions.isEmpty {
                tableStructures[page.pageIndex] = tableRegions
            }
        }
        
        return tableStructures
    }
    
    /// Analyzes document complexity based on element distribution
    /// - Returns: Complexity metrics
    func analyzeComplexity() -> DocumentComplexity {
        let totalElements = totalElementCount
        let tablesDetected = detectAllTableStructures().values.flatMap { $0 }.count
        let averageElementsPerPage = totalElements > 0 ? Double(totalElements) / Double(pageCount) : 0
        
        return DocumentComplexity(
            totalElements: totalElements,
            averageElementsPerPage: averageElementsPerPage,
            tablesDetected: tablesDetected,
            pageCount: pageCount
        )
    }
}

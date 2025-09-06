import Foundation
import CoreGraphics

/// Represents a structured page with positional elements
/// Contains the original text plus spatial element information
struct StructuredPage: Codable, Identifiable {
    /// Unique identifier for this page
    let id: UUID
    /// Original text content extracted from the page (for backward compatibility)
    let text: String
    /// Page bounds in the PDF coordinate system
    let bounds: CGRect
    /// Array of positional elements found on this page
    let elements: [PositionalElement]
    /// Page number (0-based index)
    let pageIndex: Int
    /// Additional metadata for this page
    let metadata: [String: String]
    /// Timestamp when this page was processed
    let processedAt: Date
    
    /// Initializes a new structured page
    /// - Parameters:
    ///   - text: Original text content
    ///   - bounds: Page bounds
    ///   - elements: Array of positional elements
    ///   - pageIndex: Page number (0-based)
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        text: String,
        bounds: CGRect,
        elements: [PositionalElement],
        pageIndex: Int,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.text = text
        self.bounds = bounds
        self.elements = elements
        self.pageIndex = pageIndex
        self.metadata = metadata
        self.processedAt = Date()
    }
    
    // MARK: - Convenience Properties
    
    /// Number of elements on this page
    var elementCount: Int {
        return elements.count
    }
    
    /// Elements grouped by type
    var elementsByType: [ElementType: [PositionalElement]] {
        return Dictionary(grouping: elements) { $0.type }
    }
    
    /// All labels on this page
    var labels: [PositionalElement] {
        return elements.filter { $0.type == .label }
    }
    
    /// All values on this page
    var values: [PositionalElement] {
        return elements.filter { $0.type == .value }
    }
    
    /// All headers on this page
    var headers: [PositionalElement] {
        return elements.filter { $0.type == .header }
    }
    
    /// All table cells on this page
    var tableCells: [PositionalElement] {
        return elements.filter { $0.type == .tableCell }
    }
    
    // MARK: - Spatial Analysis Methods
    
    /// Finds elements within a specific region of the page
    /// - Parameter region: The CGRect defining the region to search
    /// - Returns: Array of elements within the region
    func elementsInRegion(_ region: CGRect) -> [PositionalElement] {
        return elements.filter { region.intersects($0.bounds) }
    }
    
    /// Finds the closest element to a given point
    /// - Parameter point: The point to search from
    /// - Returns: The closest element, or nil if no elements exist
    func closestElementTo(_ point: CGPoint) -> PositionalElement? {
        return elements.min { first, second in
            let firstDistance = sqrt(pow(first.center.x - point.x, 2) + pow(first.center.y - point.y, 2))
            let secondDistance = sqrt(pow(second.center.x - point.x, 2) + pow(second.center.y - point.y, 2))
            return firstDistance < secondDistance
        }
    }
    
    /// Groups elements into approximate rows based on Y position
    /// - Parameter tolerance: Vertical tolerance for grouping (default: 20 points)
    /// - Returns: Dictionary with row identifier as key and elements as value
    func groupElementsIntoRows(tolerance: CGFloat = 20) -> [Int: [PositionalElement]] {
        return Dictionary(grouping: elements) { element in
            Int(element.center.y / tolerance) * Int(tolerance)
        }
    }
    
    /// Detects potential table structures on this page
    /// - Returns: Array of table regions detected
    func detectTableRegions() -> [CGRect] {
        let rowGroups = groupElementsIntoRows()
        var tableRegions: [CGRect] = []
        
        // Look for regions with multiple aligned rows
        let sortedRows = rowGroups.keys.sorted()
        var currentTableRows: [Int] = []
        
        for rowY in sortedRows {
            let elementsInRow = rowGroups[rowY]?.count ?? 0
            
            // If this row has multiple elements, it might be part of a table
            if elementsInRow >= 2 {
                currentTableRows.append(rowY)
            } else {
                // End of potential table
                if currentTableRows.count >= 2 {
                    let tableRegion = calculateTableRegion(for: currentTableRows, in: rowGroups)
                    tableRegions.append(tableRegion)
                }
                currentTableRows.removeAll()
            }
        }
        
        // Handle the last table if it exists
        if currentTableRows.count >= 2 {
            let tableRegion = calculateTableRegion(for: currentTableRows, in: rowGroups)
            tableRegions.append(tableRegion)
        }
        
        return tableRegions
    }
    
    /// Calculates the bounding rectangle for a table region
    /// - Parameters:
    ///   - rowYPositions: Array of Y positions for table rows
    ///   - rowGroups: Dictionary of row groups with elements
    /// - Returns: CGRect encompassing the table region
    private func calculateTableRegion(
        for rowYPositions: [Int],
        in rowGroups: [Int: [PositionalElement]]
    ) -> CGRect {
        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for rowY in rowYPositions {
            guard let elementsInRow = rowGroups[rowY] else { continue }
            
            for element in elementsInRow {
                minX = min(minX, element.bounds.minX)
                maxX = max(maxX, element.bounds.maxX)
                minY = min(minY, element.bounds.minY)
                maxY = max(maxY, element.bounds.maxY)
            }
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

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


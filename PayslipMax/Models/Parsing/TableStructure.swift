import Foundation
import CoreGraphics

/// Represents a complete table structure with rows, columns, and spatial relationships
/// Core model for enhanced table processing that maintains spatial intelligence
struct TableStructure: Codable, Identifiable, Equatable {
    /// Unique identifier for this table structure
    let id: UUID
    /// Array of table rows in order (top to bottom)
    let rows: [TableRow]
    /// Detected column boundaries within the table
    let columnBoundaries: [ColumnBoundary]
    /// Overall bounding rectangle of the table
    let bounds: CGRect
    /// Additional metadata for this table
    let metadata: [String: String]
    /// Timestamp when this structure was created
    let createdAt: Date
    
    /// Initializes a new table structure
    /// - Parameters:
    ///   - rows: Array of table rows
    ///   - columnBoundaries: Array of column boundaries
    ///   - bounds: Table bounding rectangle
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        rows: [TableRow],
        columnBoundaries: [ColumnBoundary] = [],
        bounds: CGRect,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.rows = rows.sorted { $0.yPosition < $1.yPosition } // Ensure top-to-bottom order
        self.columnBoundaries = columnBoundaries.sorted { $0.xPosition < $1.xPosition }
        self.bounds = bounds
        self.metadata = metadata
        self.createdAt = Date()
    }
    
    // MARK: - Convenience Properties
    
    /// Number of rows in the table
    var rowCount: Int {
        return rows.count
    }
    
    /// Number of columns based on detected boundaries
    var columnCount: Int {
        return columnBoundaries.count + 1
    }
    
    /// Total number of elements across all rows
    var totalElementCount: Int {
        return rows.reduce(0) { $0 + $1.elementCount }
    }
    
    /// All elements from all rows
    var allElements: [PositionalElement] {
        return rows.flatMap { $0.elements }
    }
    
    /// Table header row (first row if it looks like a header)
    var headerRow: TableRow? {
        return rows.first { $0.isLikelyHeader }
    }
    
    /// Data rows (excluding header)
    var dataRows: [TableRow] {
        if let headerRow = headerRow {
            return rows.filter { $0.id != headerRow.id }
        }
        return rows
    }
    
    /// Table complexity score based on structure
    var complexityScore: Double {
        let baseScore = Double(rowCount) * 0.3 + Double(columnCount) * 0.2
        let elementDensity = totalElementCount > 0 ? Double(totalElementCount) / Double(rowCount * columnCount) : 0
        return min(1.0, baseScore + elementDensity * 0.5)
    }
    
    /// Whether this appears to be a financial table (contains numeric data)
    var isFinancialTable: Bool {
        let numericElements = allElements.filter { $0.isNumeric || $0.isCurrency }
        let numericRatio = allElements.isEmpty ? 0.0 : Double(numericElements.count) / Double(allElements.count)
        return numericRatio >= 0.3
    }
    
    // MARK: - Table Analysis Methods
    
    // Analysis methods are in TableAnalysis.swift extension
    // Validation methods are in TableValidation.swift extension
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: TableStructure, rhs: TableStructure) -> Bool {
        return lhs.id == rhs.id
    }
}

// MergedCell and validation types are now defined in SpatialTypes.swift and TableValidation.swift

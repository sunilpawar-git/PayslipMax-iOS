import Foundation
import CoreGraphics

/// Service responsible for validating row consistency and quality
/// Extracted component for single responsibility - row validation logic
final class RowValidationService {
    
    // MARK: - Properties
    
    /// Configuration for validation
    private let configuration: RowAssociationConfiguration
    
    // MARK: - Initialization
    
    /// Initializes the row validation service
    /// - Parameter configuration: Configuration for validation
    init(configuration: RowAssociationConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Validates row consistency across table structure
    /// - Parameters:
    ///   - rows: Array of table rows to validate
    ///   - expectedColumnCount: Expected number of columns (optional)
    /// - Returns: Validation result with consistency metrics
    /// - Throws: RowAssociationError for validation failures
    func validateRowConsistency(
        rows: [TableRow],
        expectedColumnCount: Int? = nil
    ) async throws -> RowConsistencyValidation {
        
        guard !rows.isEmpty else {
            return RowConsistencyValidation.empty
        }
        
        // Analyze column count consistency
        let columnCounts = rows.map { $0.elements.count }
        let avgColumnCount = Double(columnCounts.reduce(0, +)) / Double(columnCounts.count)
        let columnCountVariance = calculateColumnCountVariance(columnCounts, average: avgColumnCount)
        
        // Analyze vertical spacing consistency
        let verticalSpacings = calculateVerticalSpacings(rows)
        let avgSpacing = verticalSpacings.isEmpty ? 0.0 : verticalSpacings.reduce(0, +) / Double(verticalSpacings.count)
        let spacingVariance = calculateSpacingVariance(verticalSpacings, average: avgSpacing)
        
        // Calculate overall consistency score
        let columnConsistency = 1.0 - min(columnCountVariance / avgColumnCount, 1.0)
        let spacingConsistency = avgSpacing > 0 ? (1.0 - min(spacingVariance / avgSpacing, 1.0)) : 1.0
        let overallScore = (columnConsistency * 0.6) + (spacingConsistency * 0.4)
        
        return RowConsistencyValidation(
            overallScore: overallScore,
            columnConsistency: columnConsistency,
            spacingConsistency: spacingConsistency,
            averageColumnCount: avgColumnCount,
            columnCountVariance: columnCountVariance,
            averageVerticalSpacing: avgSpacing,
            spacingVariance: spacingVariance,
            isValid: overallScore >= configuration.minimumConsistencyScore
        )
    }
    
    /// Detects multi-line cells within table rows
    /// - Parameters:
    ///   - rows: Array of table rows to analyze
    ///   - maxLinesToleranceRatio: Maximum ratio of line height variation (optional)
    /// - Returns: Array of rows with multi-line cells merged
    /// - Throws: RowAssociationError for detection failures
    func detectMultiLineCells(
        in rows: [TableRow],
        maxLinesToleranceRatio: Double? = nil
    ) async throws -> [TableRow] {
        
        guard !rows.isEmpty else {
            return []
        }
        
        let effectiveRatio = maxLinesToleranceRatio ?? configuration.multiLineTolerance
        var processedRows: [TableRow] = []
        
        for row in rows {
            let processedRow = try await processMultiLineElements(
                in: row,
                toleranceRatio: effectiveRatio
            )
            processedRows.append(processedRow)
        }
        
        return processedRows
    }
    
    // MARK: - Private Implementation
    
    /// Calculates column count variance
    private func calculateColumnCountVariance(
        _ columnCounts: [Int],
        average: Double
    ) -> Double {
        
        guard columnCounts.count > 1 else { return 0.0 }
        
        let variance = columnCounts.reduce(0.0) { sum, count in
            let diff = Double(count) - average
            return sum + (diff * diff)
        } / Double(columnCounts.count - 1)
        
        return sqrt(variance)
    }
    
    /// Calculates vertical spacings between rows
    private func calculateVerticalSpacings(_ rows: [TableRow]) -> [Double] {
        guard rows.count > 1 else { return [] }
        
        let sortedRows = rows.sorted { $0.yPosition < $1.yPosition }
        var spacings: [Double] = []
        
        for i in 1..<sortedRows.count {
            let spacing = Double(sortedRows[i].yPosition - sortedRows[i-1].yPosition)
            spacings.append(spacing)
        }
        
        return spacings
    }
    
    /// Calculates spacing variance
    private func calculateSpacingVariance(
        _ spacings: [Double],
        average: Double
    ) -> Double {
        
        guard spacings.count > 1 else { return 0.0 }
        
        let variance = spacings.reduce(0.0) { sum, spacing in
            let diff = spacing - average
            return sum + (diff * diff)
        } / Double(spacings.count - 1)
        
        return sqrt(variance)
    }
    
    /// Processes multi-line elements within a row
    private func processMultiLineElements(
        in row: TableRow,
        toleranceRatio: Double
    ) async throws -> TableRow {
        
        // For now, return the row as-is
        // This is a placeholder for future multi-line cell detection logic
        return row
    }
}

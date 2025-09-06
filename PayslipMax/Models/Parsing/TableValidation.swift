import Foundation
import CoreGraphics

/// Result of table structure validation
struct TableValidationResult: Codable {
    /// Whether the table structure is valid
    let isValid: Bool
    /// Quality score (0.0 to 1.0)
    let qualityScore: Double
    /// Issues detected in the table structure
    let issues: [TableValidationIssue]
    /// Validation timestamp
    let validatedAt: Date
    
    init(isValid: Bool, qualityScore: Double, issues: [TableValidationIssue]) {
        self.isValid = isValid
        self.qualityScore = min(1.0, max(0.0, qualityScore))
        self.issues = issues
        self.validatedAt = Date()
    }
}

/// Issues that can be detected in table structures
enum TableValidationIssue: String, Codable, CaseIterable {
    /// Not enough rows for a meaningful table
    case insufficientRows = "Insufficient rows"
    /// Not enough columns for a meaningful table
    case insufficientColumns = "Insufficient columns"
    /// Rows have inconsistent number of elements
    case inconsistentRowStructure = "Inconsistent row structure"
    /// Table has very few elements relative to its structure
    case sparseData = "Sparse data"
    /// Table bounds are invalid
    case invalidBounds = "Invalid table bounds"
    /// Column boundaries don't align properly
    case misalignedColumns = "Misaligned columns"
    /// Row heights are inconsistent
    case inconsistentRowHeights = "Inconsistent row heights"
    
    var description: String {
        return rawValue
    }
}

/// Extension for table structure validation methods
extension TableStructure {
    /// Validates the table structure for quality assurance
    /// - Returns: Validation result with quality metrics
    func validateStructure() -> TableValidationResult {
        var issues: [TableValidationIssue] = []
        var qualityScore: Double = 1.0
        
        // Check for minimum structure requirements
        if rowCount < 2 {
            issues.append(.insufficientRows)
            qualityScore *= 0.5
        }
        
        if columnCount < 2 {
            issues.append(.insufficientColumns)
            qualityScore *= 0.5
        }
        
        // Check for consistent row structures
        let elementCounts = rows.map { $0.elementCount }
        let avgElementCount = elementCounts.reduce(0, +) / elementCounts.count
        let inconsistentRows = elementCounts.filter { abs($0 - avgElementCount) > 2 }.count
        
        if inconsistentRows > rowCount / 3 {
            issues.append(.inconsistentRowStructure)
            qualityScore *= 0.8
        }
        
        // Check for reasonable element distribution
        if totalElementCount < rowCount * 2 {
            issues.append(.sparseData)
            qualityScore *= 0.7
        }
        
        // Check bounds validity
        if bounds.width <= 0 || bounds.height <= 0 {
            issues.append(.invalidBounds)
            qualityScore *= 0.6
        }
        
        return TableValidationResult(
            isValid: qualityScore >= 0.5,
            qualityScore: qualityScore,
            issues: issues
        )
    }
}

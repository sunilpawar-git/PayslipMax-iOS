import Foundation
import CoreGraphics

// MARK: - Configuration Types

/// Configuration for row association
struct RowAssociationConfiguration {
    let minimumElementsForRowDetection: Int
    let minimumElementsPerRow: Int
    let verticalAlignmentTolerance: CGFloat
    let multiLineTolerance: Double
    let minimumConsistencyScore: Double
    
    static let payslipDefault = RowAssociationConfiguration(
        minimumElementsForRowDetection: 4,
        minimumElementsPerRow: 2,
        verticalAlignmentTolerance: 15.0,
        multiLineTolerance: 0.3,
        minimumConsistencyScore: 0.7
    )
}

// MARK: - Core Row Types

/// Represents a cluster of elements forming a table row
struct RowCluster {
    let centerY: CGFloat
    let tolerance: CGFloat
    let elementIndices: [Int]
    let confidence: Double
}

/// Analysis of vertical element distribution
struct VerticalDistributionAnalysis {
    let yPositions: [CGFloat]
    let topEdges: [CGFloat]
    let bottomEdges: [CGFloat]
    let clusters: [VerticalCluster]
    let elementCount: Int
}

/// Vertical cluster data
struct VerticalCluster {
    let centerY: CGFloat
    let spread: CGFloat
    let confidence: Double
}

/// Result of row consistency validation
struct RowConsistencyValidation {
    let overallScore: Double
    let columnConsistency: Double
    let spacingConsistency: Double
    let averageColumnCount: Double
    let columnCountVariance: Double
    let averageVerticalSpacing: Double
    let spacingVariance: Double
    let isValid: Bool
    
    static let empty = RowConsistencyValidation(
        overallScore: 0.0,
        columnConsistency: 0.0,
        spacingConsistency: 0.0,
        averageColumnCount: 0.0,
        columnCountVariance: 0.0,
        averageVerticalSpacing: 0.0,
        spacingVariance: 0.0,
        isValid: false
    )
}

// MARK: - Error Types

/// Error types for row association
enum RowAssociationError: Error, LocalizedError {
    case insufficientElements(count: Int)
    case clusteringFailure(String)
    case validationFailure(String)
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .insufficientElements(let count):
            return "Insufficient elements for row association: \(count)"
        case .clusteringFailure(let message):
            return "Row clustering failed: \(message)"
        case .validationFailure(let message):
            return "Row validation failed: \(message)"
        case .processingTimeout:
            return "Row association processing timeout"
        }
    }
}

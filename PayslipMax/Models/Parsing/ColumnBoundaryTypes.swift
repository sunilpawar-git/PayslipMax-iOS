import Foundation
import CoreGraphics

// MARK: - Configuration Types

/// Configuration for column boundary detection
struct ColumnBoundaryConfiguration {
    let minimumElementsForDetection: Int
    let minimumColumnWidth: CGFloat
    let minimumGapWidth: CGFloat
    let maximumExpectedGap: CGFloat
    let minimumBoundaryConfidence: Double
    let minimumAlignmentScore: Double
    let alignmentTolerance: CGFloat
    let densitySearchRadius: CGFloat
    let clusteringGapThreshold: CGFloat
    
    static let payslipDefault = ColumnBoundaryConfiguration(
        minimumElementsForDetection: 6,
        minimumColumnWidth: 40.0,
        minimumGapWidth: 20.0,
        maximumExpectedGap: 200.0,
        minimumBoundaryConfidence: 0.5,
        minimumAlignmentScore: 0.3,
        alignmentTolerance: 10.0,
        densitySearchRadius: 25.0,
        clusteringGapThreshold: 15.0
    )
}

// MARK: - Core Boundary Types

/// Represents a detected column boundary
struct ColumnBoundary: Identifiable, Codable {
    let id: UUID
    let xPosition: CGFloat
    let confidence: Double
    let width: CGFloat
    let detectionMethod: BoundaryDetectionMethod
    let metadata: [String: String]
    
    init(
        xPosition: CGFloat,
        confidence: Double,
        width: CGFloat,
        detectionMethod: BoundaryDetectionMethod,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.xPosition = xPosition
        self.confidence = confidence
        self.width = width
        self.detectionMethod = detectionMethod
        self.metadata = metadata
    }
}

/// Methods used to detect column boundaries
enum BoundaryDetectionMethod: String, Codable {
    case gapAnalysis = "gap_analysis"
    case alignmentValidated = "alignment_validated"
    case statistical = "statistical"
    case manual = "manual"
}

// MARK: - Analysis Types

/// Analysis of horizontal element distribution
struct HorizontalDistributionAnalysis {
    let leftEdgeStatistics: ElementStatistics
    let rightEdgeStatistics: ElementStatistics
    let leftClusters: [PositionCluster]
    let rightClusters: [PositionCluster]
    let allXPositions: [CGFloat]
}

/// Cluster of positions in similar locations
struct PositionCluster {
    let centerX: CGFloat
    let minX: CGFloat
    let maxX: CGFloat
    let positions: [CGFloat]
    let elementCount: Int
}

/// Validation scores for boundary analysis
struct ValidationScores {
    let individual: [Double]
    let average: Double
    let minimum: Double
    let maximum: Double
}

// MARK: - Error Types

/// Error types for column detection
enum ColumnDetectionError: Error, LocalizedError {
    case insufficientElements(count: Int)
    case processingTimeout
    case invalidConfiguration
    case analysisFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientElements(let count):
            return "Insufficient elements for column detection: \(count)"
        case .processingTimeout:
            return "Column detection processing timeout"
        case .invalidConfiguration:
            return "Invalid column detection configuration"
        case .analysisFailure(let message):
            return "Column analysis failed: \(message)"
        }
    }
}

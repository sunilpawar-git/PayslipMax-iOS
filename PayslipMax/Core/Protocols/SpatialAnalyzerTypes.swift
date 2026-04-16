import Foundation
import CoreGraphics

// MARK: - Relationship Score

/// Represents a spatial relationship score between two elements
struct ElementRelationshipScore: Codable {
    /// Overall relationship score (0.0 to 1.0)
    let score: Double
    /// Type of spatial relationship detected
    let relationshipType: SpatialRelationshipType
    /// Distance between elements in points
    let distance: CGFloat
    /// Confidence in the relationship classification
    let confidence: Double
    /// Additional scoring details
    let scoringDetails: SpatialScoringDetails

    init(
        score: Double,
        relationshipType: SpatialRelationshipType,
        distance: CGFloat,
        confidence: Double,
        scoringDetails: SpatialScoringDetails
    ) {
        self.score = min(1.0, max(0.0, score))
        self.relationshipType = relationshipType
        self.distance = distance
        self.confidence = min(1.0, max(0.0, confidence))
        self.scoringDetails = scoringDetails
    }
}

// MARK: - Relationship Types

/// Types of spatial relationships between elements
enum SpatialRelationshipType: String, Codable, CaseIterable {
    /// Elements are adjacent horizontally (same row)
    case adjacentHorizontal = "Adjacent Horizontal"
    /// Elements are adjacent vertically (same column)
    case adjacentVertical = "Adjacent Vertical"
    /// Elements are aligned horizontally
    case alignedHorizontal = "Aligned Horizontal"
    /// Elements are aligned vertically
    case alignedVertical = "Aligned Vertical"
    /// Elements are grouped in same section
    case grouped = "Grouped"
    /// Elements are part of same table
    case tabular = "Tabular"
    /// No clear spatial relationship
    case unrelated = "Unrelated"

    var description: String {
        return rawValue
    }
}

// MARK: - Scoring Details

/// Detailed scoring information for spatial relationships
struct SpatialScoringDetails: Codable {
    /// Horizontal alignment score (0.0 to 1.0)
    let horizontalAlignment: Double
    /// Vertical alignment score (0.0 to 1.0)
    let verticalAlignment: Double
    /// Proximity score based on distance (0.0 to 1.0)
    let proximityScore: Double
    /// Size similarity score (0.0 to 1.0)
    let sizeSimilarity: Double
    /// Font similarity score (0.0 to 1.0)
    let fontSimilarity: Double

    init(
        horizontalAlignment: Double,
        verticalAlignment: Double,
        proximityScore: Double,
        sizeSimilarity: Double,
        fontSimilarity: Double
    ) {
        self.horizontalAlignment = min(1.0, max(0.0, horizontalAlignment))
        self.verticalAlignment = min(1.0, max(0.0, verticalAlignment))
        self.proximityScore = min(1.0, max(0.0, proximityScore))
        self.sizeSimilarity = min(1.0, max(0.0, sizeSimilarity))
        self.fontSimilarity = min(1.0, max(0.0, fontSimilarity))
    }
}

// MARK: - Validation Result

/// Result of spatial analysis validation
struct SpatialAnalysisValidationResult: Codable {
    /// Whether the analysis passed quality checks
    let isValid: Bool
    /// Overall quality score (0.0 to 1.0)
    let qualityScore: Double
    /// Number of relationships analyzed
    let relationshipCount: Int
    /// Number of high-confidence relationships
    let highConfidenceCount: Int
    /// Detected issues during analysis
    let issues: [SpatialAnalysisIssue]
    /// Validation timestamp
    let validatedAt: Date

    /// High-confidence relationship ratio
    var highConfidenceRatio: Double {
        guard relationshipCount > 0 else { return 0.0 }
        return Double(highConfidenceCount) / Double(relationshipCount)
    }

    init(
        isValid: Bool,
        qualityScore: Double,
        relationshipCount: Int,
        highConfidenceCount: Int,
        issues: [SpatialAnalysisIssue] = []
    ) {
        self.isValid = isValid
        self.qualityScore = min(1.0, max(0.0, qualityScore))
        self.relationshipCount = relationshipCount
        self.highConfidenceCount = highConfidenceCount
        self.issues = issues
        self.validatedAt = Date()
    }
}

// MARK: - Analysis Issues

/// Types of spatial analysis issues that can be detected
enum SpatialAnalysisIssue: String, Codable, CaseIterable {
    /// Too few relationships detected for document complexity
    case lowRelationshipCount = "Low relationship count"
    /// Many relationships have low confidence scores
    case poorConfidence = "Poor confidence scores"
    /// Inconsistent spatial patterns detected
    case inconsistentPatterns = "Inconsistent spatial patterns"
    /// Elements appear to be misaligned
    case alignmentIssues = "Alignment issues detected"
    /// Potential table structure not recognized
    case missedTableStructure = "Missed table structure"
    /// Performance degradation during analysis
    case performanceIssues = "Performance issues"

    var description: String {
        return rawValue
    }
}

// MARK: - Analysis Errors

/// Errors that can occur during spatial analysis
enum SpatialAnalysisError: Error, LocalizedError, Equatable {
    /// Insufficient elements for meaningful analysis
    case insufficientElements(count: Int)
    /// Analysis timeout exceeded
    case timeout
    /// Memory pressure during analysis
    case memoryError
    /// Invalid configuration parameters
    case invalidConfiguration(String)
    /// Element processing failed
    case processingFailed(String)
    /// Unknown error during analysis
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .insufficientElements(let count):
            return "Insufficient elements for analysis: \(count) found, minimum 2 required"
        case .timeout:
            return "Spatial analysis timeout exceeded"
        case .memoryError:
            return "Memory error during spatial analysis"
        case .invalidConfiguration(let message):
            return "Invalid spatial analysis configuration: \(message)"
        case .processingFailed(let message):
            return "Spatial analysis processing failed: \(message)"
        case .unknown(let message):
            return "Unknown spatial analysis error: \(message)"
        }
    }
}

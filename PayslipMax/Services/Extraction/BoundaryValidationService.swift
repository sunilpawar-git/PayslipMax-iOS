import CoreGraphics
import Foundation

/// Service responsible for validating column boundaries through alignment and scoring
/// Extracted component for single responsibility - boundary validation logic
final class BoundaryValidationService {

    // MARK: - Properties

    /// Configuration for validation
    private let configuration: ColumnBoundaryConfiguration

    // MARK: - Initialization

    /// Initializes the boundary validation service
    /// - Parameter configuration: Configuration for validation
    init(configuration: ColumnBoundaryConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public Interface

    /// Validates boundaries using element alignment patterns
    /// - Parameters:
    ///   - boundaries: Array of boundaries to validate
    ///   - elements: Elements to validate against
    /// - Returns: Array of validated boundaries
    /// - Throws: ColumnDetectionError for validation failures
    func validateWithAlignment(
        boundaries: [ColumnBoundary],
        elements: [PositionalElement]
    ) async throws -> [ColumnBoundary] {

        var validatedBoundaries: [ColumnBoundary] = []

        for boundary in boundaries {
            let alignmentScore = try await calculateAlignmentScore(
                boundary: boundary,
                elements: elements
            )

            if alignmentScore >= configuration.minimumAlignmentScore {
                var updatedMetadata = boundary.metadata
                updatedMetadata["alignmentScore"] = String(describing: alignmentScore)

                let validatedBoundary = ColumnBoundary(
                    xPosition: boundary.xPosition,
                    confidence: boundary.confidence * alignmentScore, // Combine scores
                    width: boundary.width,
                    detectionMethod: .alignmentValidated,
                    metadata: updatedMetadata
                )

                validatedBoundaries.append(validatedBoundary)
            }
        }

        return validatedBoundaries
    }

    /// Applies final confidence scoring based on multiple factors
    /// - Parameters:
    ///   - boundaries: Array of boundaries to score
    ///   - elements: Elements for scoring context
    /// - Returns: Array of scored boundaries
    /// - Throws: ColumnDetectionError for scoring failures
    func applyConfidenceScoring(
        boundaries: [ColumnBoundary],
        elements: [PositionalElement]
    ) async throws -> [ColumnBoundary] {

        var scoredBoundaries: [ColumnBoundary] = []

        for boundary in boundaries {
            let finalConfidence = try await calculateFinalConfidence(
                boundary: boundary,
                elements: elements
            )

            let scoredBoundary = ColumnBoundary(
                xPosition: boundary.xPosition,
                confidence: finalConfidence,
                width: boundary.width,
                detectionMethod: boundary.detectionMethod,
                metadata: boundary.metadata
            )

            scoredBoundaries.append(scoredBoundary)
        }

        return scoredBoundaries
    }

    /// Validates a boundary across multiple table rows
    /// - Parameters:
    ///   - boundary: Boundary to validate
    ///   - rows: Table rows to validate against
    /// - Returns: Validation scores
    /// - Throws: ColumnDetectionError for validation failures
    func validateBoundaryAcrossRows(
        boundary: ColumnBoundary,
        rows: [TableRow]
    ) async throws -> ValidationScores {

        var scores: [Double] = []

        for row in rows {
            let rowElements = row.elements
            let score = try await calculateAlignmentScore(
                boundary: boundary,
                elements: rowElements
            )
            scores.append(score)
        }

        return ValidationScores(
            individual: scores,
            average: scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count),
            minimum: scores.min() ?? 0.0,
            maximum: scores.max() ?? 0.0
        )
    }

    // MARK: - Private Implementation

    /// Calculates alignment score for elements around a boundary
    private func calculateAlignmentScore(
        boundary: ColumnBoundary,
        elements: [PositionalElement]
    ) async throws -> Double {

        let tolerance = configuration.alignmentTolerance
        let alignedElements = elements.filter { element in
            abs(element.bounds.minX - boundary.xPosition) <= tolerance ||
            abs(element.bounds.maxX - boundary.xPosition) <= tolerance
        }

        let alignmentRatio = Double(alignedElements.count) / Double(elements.count)
        return min(alignmentRatio * 1.2, 1.0) // Boost alignment importance
    }

    /// Calculates final confidence incorporating multiple validation factors
    private func calculateFinalConfidence(
        boundary: ColumnBoundary,
        elements: [PositionalElement]
    ) async throws -> Double {

        let baseConfidence = boundary.confidence

        // Factor in element density around boundary
        let densityScore = try await calculateElementDensity(
            around: boundary.xPosition,
            elements: elements
        )

        // Combine scores with weights
        let weightedScore = (baseConfidence * 0.6) + (densityScore * 0.4)

        return min(weightedScore, 1.0)
    }

    /// Calculates element density around a potential boundary position
    private func calculateElementDensity(
        around xPosition: CGFloat,
        elements: [PositionalElement]
    ) async throws -> Double {
        let searchRadius = configuration.densitySearchRadius
        let nearbyElements = elements.filter { element in
            abs(element.center.x - xPosition) <= searchRadius
        }

        let maxPossibleElements = elements.count
        let densityRatio = Double(nearbyElements.count) / Double(maxPossibleElements)

        // Invert density - boundaries should have fewer elements nearby
        return 1.0 - min(densityRatio * 2.0, 1.0)
    }
}

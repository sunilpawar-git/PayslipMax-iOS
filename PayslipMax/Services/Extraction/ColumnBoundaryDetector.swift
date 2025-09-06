import Foundation
import CoreGraphics

/// Service responsible for detecting column boundaries in tabulated data
/// Analyzes spatial distribution and gaps to identify table structure
final class ColumnBoundaryDetector {
    
    // MARK: - Properties
    
    /// Statistical calculator for element distribution analysis
    private let distributionCalculator: ElementDistributionCalculator
    
    /// Validation service for boundary scoring and validation
    private let validationService: BoundaryValidationService
    
    // MARK: - Initialization
    
    /// Initializes the column boundary detector with required dependencies
    /// - Parameters:
    ///   - distributionCalculator: Service for statistical analysis
    ///   - validationService: Service for boundary validation
    init(
        distributionCalculator: ElementDistributionCalculator = ElementDistributionCalculator(configuration: .payslipDefault),
        validationService: BoundaryValidationService = BoundaryValidationService(configuration: .payslipDefault)
    ) {
        self.distributionCalculator = distributionCalculator
        self.validationService = validationService
    }
    
    // MARK: - Public Interface
    
    /// Detects column boundaries in a set of positional elements
    /// - Parameter elements: Array of positional elements to analyze
    /// - Returns: Array of detected column boundaries
    func detectColumnBoundaries(from elements: [PositionalElement]) async throws -> [ColumnBoundary] {
        guard !elements.isEmpty else {
            throw ColumnDetectionError.insufficientElements(count: 0)
        }
        
        // Extract X positions for analysis
        let xPositions = elements.map { $0.bounds.minX }
        
        // Calculate basic statistics for gap analysis
        let statistics = try await distributionCalculator.calculateStatistics(for: xPositions)
        
        // Identify gap-based boundaries
        let gapBoundaries = identifyGapBasedBoundaries(from: statistics, elements: elements)
        
        // Validate and score boundaries
        let validatedBoundaries = try await validationService.validateWithAlignment(boundaries: gapBoundaries, elements: elements)
        
        // Filter by confidence threshold
        return validatedBoundaries.filter { $0.confidence > 0.7 }
    }
    
    // MARK: - Private Methods
    
    /// Identifies column boundaries based on horizontal gaps between elements
    private func identifyGapBasedBoundaries(
        from statistics: ElementStatistics,
        elements: [PositionalElement]
    ) -> [ColumnBoundary] {
        var boundaries: [ColumnBoundary] = []
        
        // Sort elements by X position
        let sortedElements = elements.sorted { $0.bounds.minX < $1.bounds.minX }
        guard sortedElements.count > 1 else { return boundaries }
        
        // Find significant gaps between elements
        for i in 0..<sortedElements.count - 1 {
            let currentElement = sortedElements[i]
            let nextElement = sortedElements[i + 1]
            
            let gapWidth = nextElement.bounds.minX - currentElement.bounds.maxX
            
            // Consider gaps larger than a threshold as potential column boundaries
            if gapWidth > 20.0 { // 20pt minimum gap
                let boundaryX = currentElement.bounds.maxX + (gapWidth / 2)
                let confidence = calculateGapConfidence(gap: gapWidth, context: statistics)
                
                let boundary = ColumnBoundary(
                    xPosition: boundaryX,
                    confidence: confidence,
                    width: gapWidth,
                    detectionMethod: .gapAnalysis,
                    metadata: [
                        "gap_width": String(format: "%.1f", gapWidth),
                        "elements_before": String(i + 1),
                        "elements_after": String(sortedElements.count - i - 1)
                    ]
                )
                
                boundaries.append(boundary)
            }
        }
        
        return boundaries
    }
    
    /// Calculates confidence score for a detected gap
    private func calculateGapConfidence(gap: CGFloat, context: ElementStatistics) -> Double {
        // Base confidence on gap size relative to standard deviation
        let normalizedGap = gap / context.standardDeviation
        
        // Higher confidence for larger gaps
        let gapScore = min(1.0, Double(normalizedGap) / 3.0) // Max at 3x std dev
        
        // Consider consistency with other detected gaps
        let consistencyScore = 0.8 // Simplified for now
        
        return gapScore * consistencyScore
    }
}


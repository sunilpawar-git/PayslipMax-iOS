import Foundation
import CoreGraphics

/// Represents a paired relationship between two positional elements
/// Core model for spatial intelligence that maintains relationships discovered through geometric analysis
struct ElementPair: Codable, Identifiable, Equatable {
    /// Unique identifier for this element pair
    let id: UUID
    /// The label element (typically contains descriptive text)
    let label: PositionalElement
    /// The value element (typically contains data or numeric values)
    let value: PositionalElement
    /// Confidence score for this pairing (0.0 to 1.0)
    let confidence: Double
    /// Type of spatial relationship between elements
    let relationshipType: SpatialRelationshipType
    /// Distance between element centers in points
    let distance: CGFloat
    /// Additional metadata for this relationship
    let metadata: [String: String]
    /// Timestamp when this pair was created
    let createdAt: Date
    
    /// Initializes a new element pair
    /// - Parameters:
    ///   - label: The label element
    ///   - value: The value element
    ///   - confidence: Confidence score (defaults to 0.5)
    ///   - relationshipType: Type of spatial relationship
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        label: PositionalElement,
        value: PositionalElement,
        confidence: Double = 0.5,
        relationshipType: SpatialRelationshipType = .adjacentHorizontal,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.confidence = min(1.0, max(0.0, confidence))
        self.relationshipType = relationshipType
        self.distance = label.distanceTo(value)
        self.metadata = metadata
        self.createdAt = Date()
    }
    
    // MARK: - Convenience Properties
    
    /// Whether this is a high-confidence pairing
    var isHighConfidence: Bool {
        return confidence >= 0.7
    }
    
    /// Whether elements are horizontally aligned (same row)
    var areHorizontallyAligned: Bool {
        return label.isHorizontallyAlignedWith(value)
    }
    
    /// Whether elements are vertically aligned (same column)
    var areVerticallyAligned: Bool {
        return label.isVerticallyAlignedWith(value)
    }
    
    /// Combined text representation of the pair
    var combinedText: String {
        return "\(label.text): \(value.text)"
    }
    
    /// Bounding rectangle encompassing both elements
    var combinedBounds: CGRect {
        return label.bounds.union(value.bounds)
    }
    
    // MARK: - Spatial Analysis Methods
    
    /// Validates the spatial relationship between elements
    /// - Returns: Validation result with quality metrics
    func validateRelationship() -> PairValidationResult {
        var issues: [PairValidationIssue] = []
        var qualityScore: Double = confidence
        
        // Check for reasonable distance
        if distance > 200 {
            issues.append(.excessiveDistance)
            qualityScore *= 0.8
        }
        
        // Check for alignment consistency
        if relationshipType == .adjacentHorizontal && !areHorizontallyAligned {
            issues.append(.misalignedElements)
            qualityScore *= 0.7
        }
        
        if relationshipType == .adjacentVertical && !areVerticallyAligned {
            issues.append(.misalignedElements)
            qualityScore *= 0.7
        }
        
        // Check for overlapping elements
        if label.bounds.intersects(value.bounds) {
            issues.append(.overlappingElements)
            qualityScore *= 0.6
        }
        
        // Check for size consistency
        let sizeRatio = min(label.bounds.width, value.bounds.width) / max(label.bounds.width, value.bounds.width)
        if sizeRatio < 0.3 {
            issues.append(.sizeMismatch)
            qualityScore *= 0.9
        }
        
        return PairValidationResult(
            isValid: qualityScore >= 0.3,
            qualityScore: qualityScore,
            issues: issues
        )
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: ElementPair, rhs: ElementPair) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Result of element pair validation
struct PairValidationResult: Codable {
    /// Whether the pair is considered valid
    let isValid: Bool
    /// Quality score for this pair (0.0 to 1.0)
    let qualityScore: Double
    /// Issues detected with this pair
    let issues: [PairValidationIssue]
    /// Validation timestamp
    let validatedAt: Date
    
    init(isValid: Bool, qualityScore: Double, issues: [PairValidationIssue]) {
        self.isValid = isValid
        self.qualityScore = min(1.0, max(0.0, qualityScore))
        self.issues = issues
        self.validatedAt = Date()
    }
}

/// Issues that can be detected in element pairs
enum PairValidationIssue: String, Codable, CaseIterable {
    /// Elements are too far apart
    case excessiveDistance = "Excessive distance between elements"
    /// Elements are not properly aligned
    case misalignedElements = "Misaligned elements"
    /// Elements overlap each other
    case overlappingElements = "Overlapping elements"
    /// Significant size difference between elements
    case sizeMismatch = "Size mismatch between elements"
    /// Inconsistent font or styling
    case fontMismatch = "Font mismatch between elements"
    
    var description: String {
        return rawValue
    }
}

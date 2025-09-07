import Foundation
import CoreGraphics

/// Represents a text match from traditional regex pattern matching
struct TextMatch: Identifiable {
    /// Unique identifier for this match
    let id: UUID
    /// The matched text content
    let text: String
    /// Captured groups from the regex pattern
    let captureGroups: [String]
    /// The element containing this match
    let element: PositionalElement
    /// Range of the match within the element's text (not Codable)
    let range: Range<String.Index>
    /// Timestamp when match was found
    let foundAt: Date
    
    /// Initializes a new text match
    /// - Parameters:
    ///   - text: Matched text content
    ///   - captureGroups: Regex capture groups
    ///   - element: Element containing the match
    ///   - range: Range within element text
    init(
        text: String,
        captureGroups: [String],
        element: PositionalElement,
        range: Range<String.Index>
    ) {
        self.id = UUID()
        self.text = text
        self.captureGroups = captureGroups
        self.element = element
        self.range = range
        self.foundAt = Date()
    }
    
    /// Whether this match has capture groups
    var hasCaptureGroups: Bool {
        return !captureGroups.isEmpty
    }
    
    /// Primary captured value (first capture group if available)
    var primaryCapture: String? {
        return captureGroups.first
    }
    
    /// Secondary captured value (second capture group if available)
    var secondaryCapture: String? {
        return captureGroups.count > 1 ? captureGroups[1] : nil
    }
}

/// Represents a pattern match validated with spatial context
struct ContextualMatch: Identifiable {
    /// Unique identifier for this contextual match
    let id: UUID
    /// The underlying text match (not Codable due to Range<String.Index>)
    let textMatch: TextMatch
    /// Confidence score after spatial validation (0.0 to 1.0)
    let confidence: Double
    /// Whether this match passed spatial validation
    let isValid: Bool
    /// Evidence from spatial analysis
    let spatialEvidence: [String: String] // Simplified for Codable
    /// Extracted structured data from the match
    let extractedData: [String: String] // Simplified for Codable
    /// Validation mode used for this match
    let validationMode: SpatialValidationMode
    /// Timestamp when validation was completed
    let validatedAt: Date
    
    /// Initializes a new contextual match
    /// - Parameters:
    ///   - textMatch: Underlying text match
    ///   - confidence: Confidence after spatial validation
    ///   - isValid: Whether match passed validation
    ///   - spatialEvidence: Evidence from spatial analysis
    ///   - extractedData: Structured data extracted
    ///   - validationMode: Validation mode used
    init(
        textMatch: TextMatch,
        confidence: Double,
        isValid: Bool,
        spatialEvidence: [String: Any],
        extractedData: [String: Any],
        validationMode: SpatialValidationMode
    ) {
        self.id = UUID()
        self.textMatch = textMatch
        self.confidence = min(1.0, max(0.0, confidence))
        self.isValid = isValid
        self.validationMode = validationMode
        self.validatedAt = Date()
        
        // Convert Any to String for Codable compliance
        self.spatialEvidence = spatialEvidence.mapValues { String(describing: $0) }
        self.extractedData = extractedData.mapValues { String(describing: $0) }
    }
    
    // MARK: - Convenience Properties
    
    /// Whether this is a high-confidence match
    var isHighConfidence: Bool {
        return confidence >= 0.8 && isValid
    }
    
    /// Whether this is a medium-confidence match
    var isMediumConfidence: Bool {
        return confidence >= 0.6 && confidence < 0.8 && isValid
    }
    
    /// Combined description including spatial evidence
    var detailedDescription: String {
        var description = "Match: '\(textMatch.text)' (confidence: \(String(format: "%.2f", confidence)))"
        
        if !spatialEvidence.isEmpty {
            description += " - Evidence: \(spatialEvidence)"
        }
        
        return description
    }
    
    /// Financial code if this match represents financial data
    var financialCode: String? {
        return extractedData["code"]
    }
    
    /// Financial amount if this match represents financial data
    var financialAmount: Double? {
        guard let amountStr = extractedData["amount"] else { return nil }
        let cleanedAmount = amountStr.replacingOccurrences(of: ",", with: "")
        return Double(cleanedAmount)
    }
}

/// Result of spatial relationship validation
struct SpatialValidationResult: Codable {
    /// Whether the spatial validation passed
    let isValid: Bool
    /// Confidence score for the validation (0.0 to 1.0)
    let confidence: Double
    /// Valid relationships found during validation
    let validRelationshipCount: Int
    /// Text that was searched for
    let searchText: String
    /// Expected relationship type
    let expectedRelationship: SpatialRelationshipType
    /// Validation timestamp
    let validatedAt: Date
    
    /// Initializes a spatial validation result
    /// - Parameters:
    ///   - isValid: Whether validation passed
    ///   - confidence: Confidence score
    ///   - validRelationships: Valid relationships found
    ///   - searchText: Text searched for
    ///   - expectedRelationship: Expected relationship type
    init(
        isValid: Bool,
        confidence: Double,
        validRelationships: [ElementPair],
        searchText: String,
        expectedRelationship: SpatialRelationshipType
    ) {
        self.isValid = isValid
        self.confidence = min(1.0, max(0.0, confidence))
        self.validRelationshipCount = validRelationships.count
        self.searchText = searchText
        self.expectedRelationship = expectedRelationship
        self.validatedAt = Date()
    }
    
    /// Quality description based on confidence
    var qualityDescription: String {
        switch confidence {
        case 0.8...:
            return "Excellent"
        case 0.6..<0.8:
            return "Good"
        case 0.4..<0.6:
            return "Fair"
        case 0.2..<0.4:
            return "Poor"
        default:
            return "Very Poor"
        }
    }
}

/// Result of financial data extraction with contextual validation
struct FinancialExtractionResult: Codable {
    /// Extracted earnings data
    let earnings: [String: Double]
    /// Extracted deductions data
    let deductions: [String: Double]
    /// All contextual matches found
    let matchCount: Int
    /// Overall confidence score
    let confidence: Double
    /// Extraction timestamp
    let extractedAt: Date
    
    /// Initializes a financial extraction result
    /// - Parameters:
    ///   - earnings: Earnings data
    ///   - deductions: Deductions data
    ///   - matches: Contextual matches
    ///   - confidence: Overall confidence
    init(
        earnings: [String: Double],
        deductions: [String: Double],
        matches: [ContextualMatch],
        confidence: Double
    ) {
        self.earnings = earnings
        self.deductions = deductions
        self.matchCount = matches.count
        self.confidence = min(1.0, max(0.0, confidence))
        self.extractedAt = Date()
    }
    
    // MARK: - Convenience Properties
    
    /// Total earnings amount
    var totalEarnings: Double {
        return earnings.values.reduce(0, +)
    }
    
    /// Total deductions amount
    var totalDeductions: Double {
        return deductions.values.reduce(0, +)
    }
    
    /// Net pay (earnings minus deductions)
    var netPay: Double {
        return totalEarnings - totalDeductions
    }
    
    /// Total number of financial items extracted
    var totalItemCount: Int {
        return earnings.count + deductions.count
    }
    
    /// Whether this extraction has meaningful data
    var hasSignificantData: Bool {
        return totalItemCount >= 3 && confidence >= 0.5
    }
    
    /// Quality assessment of the extraction
    var qualityAssessment: ExtractionQuality {
        switch (confidence, totalItemCount) {
        case (0.8..., 5...):
            return .excellent
        case (0.6..., 3...):
            return .good
        case (0.4..., 2...):
            return .fair
        case (0.2..., 1...):
            return .poor
        default:
            return .failed
        }
    }
}

/// Quality levels for financial extraction - moved to separate file for compliance
enum ExtractionQuality: String, Codable, CaseIterable {
    /// Excellent extraction (high confidence, many items)
    case excellent = "Excellent"
    /// Good extraction (decent confidence, some items)
    case good = "Good"
    /// Fair extraction (moderate confidence, few items)
    case fair = "Fair"
    /// Poor extraction (low confidence, minimal items)
    case poor = "Poor"
    /// Failed extraction (very low confidence or no items)
    case failed = "Failed"

    var description: String {
        return rawValue
    }
}

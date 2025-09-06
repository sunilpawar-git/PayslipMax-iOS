import Foundation
import CoreGraphics

/// Enhanced pattern matcher that uses spatial context for validation
/// Reduces false positives by validating pattern matches against geometric relationships
@MainActor
final class ContextualPatternMatcher {
    
    // MARK: - Properties
    
    /// Configuration for pattern matching
    private let configuration: ContextualPatternConfiguration
    
    /// Spatial analyzer for validating matches
    private let spatialAnalyzer: SpatialAnalyzerProtocol
    
    // MARK: - Initialization
    
    /// Initializes the contextual pattern matcher
    /// - Parameters:
    ///   - configuration: Pattern matching configuration
    ///   - spatialAnalyzer: Spatial analyzer for context validation
    init(
        configuration: ContextualPatternConfiguration = .payslipDefault,
        spatialAnalyzer: SpatialAnalyzerProtocol
    ) {
        self.configuration = configuration
        self.spatialAnalyzer = spatialAnalyzer
    }
    
    // MARK: - Pattern Matching Methods
    
    /// Applies patterns with spatial context validation
    /// Enhanced version that uses element pairs to validate pattern matches
    /// - Parameters:
    ///   - pattern: Regular expression pattern to apply
    ///   - elements: Array of positional elements to search
    ///   - validationMode: Mode for spatial validation
    /// - Returns: Array of validated pattern matches
    /// - Throws: ContextualMatchingError if matching fails
    func applyWithContext(
        pattern: String,
        to elements: [PositionalElement],
        validationMode: SpatialValidationMode = .moderate
    ) async throws -> [ContextualMatch] {
        guard !elements.isEmpty else {
            throw ContextualMatchingError.insufficientElements
        }
        
        // First, perform traditional pattern matching on text content
        let textMatches = try PatternValidationHelper.extractTextMatches(pattern: pattern, from: elements)
        
        // Get spatial relationships between elements
        let elementPairs = try await spatialAnalyzer.findRelatedElements(elements, tolerance: nil)
        
        // Validate matches using spatial context
        var contextualMatches: [ContextualMatch] = []
        
        for textMatch in textMatches {
            let contextualMatch = await PatternValidationHelper.validateMatch(
                textMatch: textMatch,
                elementPairs: elementPairs,
                elements: elements,
                validationMode: validationMode
            )
            
            if contextualMatch.isValid {
                contextualMatches.append(contextualMatch)
            }
        }
        
        // Sort by confidence (highest first)
        return contextualMatches.sorted { $0.confidence > $1.confidence }
    }
    
    /// Applies financial pattern matching with enhanced spatial validation
    /// Specialized for payslip financial data extraction
    /// - Parameters:
    ///   - elements: Positional elements to analyze
    ///   - financialCodes: Array of expected financial codes
    /// - Returns: Dictionary with validated financial data
    /// - Throws: ContextualMatchingError if extraction fails
    func applyFinancialPatterns(
        to elements: [PositionalElement],
        financialCodes: [String] = []
    ) async throws -> FinancialExtractionResult {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        var matches: [ContextualMatch] = []
        
        // Create pattern for financial code-value pairs
        let financialPattern = "([A-Z]{2,6})\\s*([\\d,]+\\.?\\d*)"
        
        // Apply pattern with spatial context
        let contextualMatches = try await applyWithContext(
            pattern: financialPattern,
            to: elements,
            validationMode: .strict
        )
        
        // Process validated matches
        for match in contextualMatches {
            guard let code = match.extractedData["code"],
                  let amountStr = match.extractedData["amount"],
                  let amount = Double(amountStr.replacingOccurrences(of: ",", with: "")) else {
                continue
            }
            
            // Additional validation for financial codes if provided
            if !financialCodes.isEmpty && !financialCodes.contains(code.uppercased()) {
                continue
            }
            
            // Categorize based on spatial context and code type
            if isEarningsCode(code) {
                earnings[code] = amount
            } else if isDeductionCode(code) {
                deductions[code] = amount
            }
            
            matches.append(match)
        }
        
        return FinancialExtractionResult(
            earnings: earnings,
            deductions: deductions,
            matches: matches,
            confidence: calculateOverallConfidence(matches: matches)
        )
    }
    
    /// Validates a pattern match against spatial relationships
    /// - Parameters:
    ///   - elements: Elements to search within
    ///   - searchText: Text to find
    ///   - expectedRelationship: Expected spatial relationship type
    /// - Returns: Validation result with confidence
    /// - Throws: ContextualMatchingError if validation fails
    func validateSpatialRelationship(
        in elements: [PositionalElement],
        searchText: String,
        expectedRelationship: SpatialRelationshipType
    ) async throws -> SpatialValidationResult {
        // Find elements containing the search text
        let matchingElements = elements.filter { $0.text.contains(searchText) }
        
        guard !matchingElements.isEmpty else {
            throw ContextualMatchingError.textNotFound(searchText)
        }
        
        // Get spatial relationships
        let elementPairs = try await spatialAnalyzer.findRelatedElements(elements, tolerance: nil)
        
        // Check if any pairs match the expected relationship
        var validRelationships: [ElementPair] = []
        
        for pair in elementPairs {
            if (pair.label.text.contains(searchText) || pair.value.text.contains(searchText)) &&
               pair.relationshipType == expectedRelationship {
                validRelationships.append(pair)
            }
        }
        
        let confidence = validRelationships.isEmpty ? 0.0 : 
            validRelationships.map { $0.confidence }.reduce(0, +) / Double(validRelationships.count)
        
        return SpatialValidationResult(
            isValid: !validRelationships.isEmpty,
            confidence: confidence,
            validRelationships: validRelationships,
            searchText: searchText,
            expectedRelationship: expectedRelationship
        )
    }
    
    // MARK: - Private Helper Methods
    // Helper methods are now in PatternValidationHelper for better code organization
    
    /// Calculates overall confidence for a collection of matches
    private func calculateOverallConfidence(matches: [ContextualMatch]) -> Double {
        return PatternValidationHelper.calculateOverallConfidence(matches: matches)
    }
    
    /// Determines if a code represents earnings
    private func isEarningsCode(_ code: String) -> Bool {
        return PatternValidationHelper.isEarningsCode(code)
    }
    
    /// Determines if a code represents deductions
    private func isDeductionCode(_ code: String) -> Bool {
        return PatternValidationHelper.isDeductionCode(code)
    }
}

// MARK: - Supporting Types

/// Configuration for contextual pattern matching
struct ContextualPatternConfiguration: Codable {
    /// Default confidence threshold for accepting matches
    let confidenceThreshold: Double
    /// Whether to enable strict spatial validation
    let enableStrictValidation: Bool
    /// Maximum distance for spatial relationship validation
    let maxSpatialDistance: CGFloat
    /// Timeout for pattern matching operations
    let timeoutSeconds: TimeInterval
    
    /// Default configuration optimized for payslip processing
    static let payslipDefault = ContextualPatternConfiguration(
        confidenceThreshold: 0.6,
        enableStrictValidation: true,
        maxSpatialDistance: 100.0,
        timeoutSeconds: 15.0
    )
}

/// Modes for spatial validation
enum SpatialValidationMode: String, Codable, CaseIterable {
    /// Lenient validation (allows matches with weak spatial evidence)
    case lenient = "Lenient"
    /// Moderate validation (balanced approach)
    case moderate = "Moderate"
    /// Strict validation (requires strong spatial evidence)
    case strict = "Strict"
    
    var description: String {
        return rawValue
    }
}

/// Errors that can occur during contextual matching
enum ContextualMatchingError: Error, LocalizedError {
    /// Not enough elements for meaningful matching
    case insufficientElements
    /// Pattern compilation failed
    case invalidPattern(String)
    /// Text not found in elements
    case textNotFound(String)
    /// Spatial validation failed
    case spatialValidationFailed
    /// Timeout during matching
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .insufficientElements:
            return "Insufficient elements for contextual matching"
        case .invalidPattern(let pattern):
            return "Invalid pattern: \(pattern)"
        case .textNotFound(let text):
            return "Text not found: \(text)"
        case .spatialValidationFailed:
            return "Spatial validation failed"
        case .timeout:
            return "Contextual matching timeout"
        }
    }
}

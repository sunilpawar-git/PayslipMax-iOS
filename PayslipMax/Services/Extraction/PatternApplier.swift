import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [REFACTORED]/300 lines
/// Core pattern applier - delegates complex strategies to specialized components

/// A helper struct responsible for applying a single `ExtractorPattern` to text content.
///
/// This includes handling different pattern types (regex, keyword, position),
/// applying preprocessing steps to the input text, and applying postprocessing
/// steps to the extracted value. Uses dependency injection for strategy delegation.
struct PatternApplier {
    
    // MARK: - Dependencies
    
    private let strategies: PatternApplicationStrategies
    private let validation: PatternApplicationValidation
    
    // MARK: - Initialization
    
    /// Initializes the pattern applier with strategy and validation dependencies
    /// - Parameters:
    ///   - strategies: Pattern application strategies (optional, defaults to new instance)
    ///   - validation: Pattern validation logic (optional, defaults to new instance)
    init(
        strategies: PatternApplicationStrategies = PatternApplicationStrategies(),
        validation: PatternApplicationValidation = PatternApplicationValidation()
    ) {
        self.strategies = strategies
        self.validation = validation
    }
    
    // MARK: - Public Interface
    
    /// Applies a specific pattern to extract a value from the given text.
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` defining the extraction logic.
    ///   - text: The text content to extract from.
    /// - Returns: The extracted and postprocessed string value, or `nil` if extraction fails.
    func apply(_ pattern: ExtractorPattern, to text: String) -> String? {
        
        // Validate pattern before processing
        guard validation.validatePattern(pattern) else {
            Logger.warning("Invalid pattern provided: \(pattern.pattern)", category: "PatternExtraction")
            return nil
        }
        
        // Apply preprocessing to the text
        var processedText = text
        for step in pattern.preprocessing {
            processedText = strategies.applyPreprocessing(step, to: processedText)
        }
        
        // Extract value based on pattern type
        var extractedValue: String? = nil
        
        switch pattern.type {
        case .regex:
            extractedValue = strategies.applyRegexPattern(pattern, to: processedText)
        case .keyword:
            extractedValue = strategies.applyKeywordPattern(pattern, to: processedText)
        case .positionBased:
            extractedValue = strategies.applyPositionBasedPattern(pattern, to: processedText)
        }
        
        // Apply postprocessing if a value was found
        if var value = extractedValue {
            for step in pattern.postprocessing {
                value = strategies.applyPostprocessing(step, to: value)
            }
            // Final trim after all post-processing
            let finalValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate the final extracted value
            guard validation.validateExtractedValue(finalValue) else {
                Logger.debug("Extracted value failed validation: '\(finalValue)'", category: "PatternExtraction")
                return nil
            }
            
            return finalValue.isEmpty ? nil : finalValue
        }
        
        return nil
    }

} 
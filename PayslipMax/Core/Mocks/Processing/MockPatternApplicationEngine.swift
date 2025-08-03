import Foundation

/// Mock implementation of PatternApplicationEngineProtocol for testing purposes.
class MockPatternApplicationEngine: PatternApplicationEngineProtocol {
    
    /// Controls whether pattern matching should succeed
    var shouldFindValue: Bool = true
    
    /// The mock value to return when pattern matching succeeds
    var mockReturnValue: String = "mock_extracted_value"
    
    /// Dictionary to store specific return values for specific pattern keys
    var specificReturnValues: [String: String] = [:]
    
    /// Tracks the last pattern definition used
    var lastPatternDefinition: PatternDefinition?
    
    /// Tracks the last individual pattern used
    var lastPattern: ExtractorPattern?
    
    /// Tracks the last text searched
    var lastSearchedText: String = ""
    
    /// Number of times findValue was called
    var findValueCallCount = 0
    
    /// Number of times applyPattern was called
    var applyPatternCallCount = 0
    
    /// Attempts to find a value in the given text using the patterns defined in a PatternDefinition.
    /// - Parameters:
    ///   - patternDef: The pattern definition containing extraction patterns to try
    ///   - text: The text to search for matches
    /// - Returns: The extracted value if shouldFindValue is true, otherwise nil
    func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        findValueCallCount += 1
        lastPatternDefinition = patternDef
        lastSearchedText = text
        
        guard shouldFindValue else {
            return nil
        }
        
        // Check for specific return value for this pattern key
        if let specificValue = specificReturnValues[patternDef.key] {
            return specificValue
        }
        
        // Return mock value based on pattern key for more realistic testing
        switch patternDef.key {
        case "month":
            return "January"
        case "year":
            return "2024"
        case "name":
            return "Test User"
        case "credits":
            return "50000"
        case "debits":
            return "10000"
        case "tax":
            return "5000"
        case "dsop":
            return "2000"
        case "account_number":
            return "123456789"
        case "pan_number":
            return "ABCDE1234F"
        default:
            return mockReturnValue
        }
    }
    
    /// Applies a single extractor pattern to the text to extract a value.
    /// - Parameters:
    ///   - pattern: The extraction pattern to apply
    ///   - text: The text to extract from
    /// - Returns: The extracted value if shouldFindValue is true, otherwise nil
    func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        applyPatternCallCount += 1
        lastPattern = pattern
        lastSearchedText = text
        
        guard shouldFindValue else {
            return nil
        }
        
        // Simple mock implementation - return different values based on pattern type
        switch pattern.type {
        case .regex:
            return "regex_match"
        case .keyword:
            return "keyword_match"
        case .positionBased:
            return "position_match"
        }
    }
    
    /// Sets a specific return value for a pattern key
    /// - Parameters:
    ///   - value: The value to return
    ///   - key: The pattern key
    func setReturnValue(_ value: String, forKey key: String) {
        specificReturnValues[key] = value
    }
    
    /// Resets the mock to its initial state
    func reset() {
        shouldFindValue = true
        mockReturnValue = "mock_extracted_value"
        specificReturnValues = [:]
        lastPatternDefinition = nil
        lastPattern = nil
        lastSearchedText = ""
        findValueCallCount = 0
        applyPatternCallCount = 0
    }
}
import Foundation

/// Protocol for a service that handles pattern matching operations for payslip data extraction
protocol PatternMatchingServiceProtocol {
    /// Extracts values from text using predefined patterns
    /// - Parameter text: The text to extract values from
    /// - Returns: Dictionary of extracted values keyed by field names
    func extractData(from text: String) -> [String: String]
    
    /// Extracts tabular data (earnings and deductions) from text
    /// - Parameter text: The text to extract tabular data from
    /// - Returns: A tuple containing dictionaries of earnings and deductions
    func extractTabularData(from text: String) -> ([String: Double], [String: Double])
    
    /// Extracts a value for a specific pattern key from text
    /// - Parameters:
    ///   - key: The pattern key to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted value, or nil if not found
    func extractValue(for key: String, from text: String) -> String?
    
    /// Extracts a numeric value for a specific pattern key from text
    /// - Parameters:
    ///   - key: The pattern key to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted numeric value, or nil if not found or not a valid number
    func extractNumericValue(for key: String, from text: String) -> Double?
    
    /// Adds a new pattern to the patterns dictionary
    /// - Parameters:
    ///   - key: The key for the pattern
    ///   - pattern: The regex pattern
    func addPattern(key: String, pattern: String)
} 
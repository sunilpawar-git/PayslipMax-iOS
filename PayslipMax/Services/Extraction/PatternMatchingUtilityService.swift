import Foundation

/// Protocol for handling pattern matching utility operations
protocol PatternMatchingUtilityServiceProtocol {
    /// Extracts a value from a line of text by removing prefixes
    /// - Parameters:
    ///   - line: The line of text to extract from
    ///   - prefixes: The prefixes to remove
    /// - Returns: The extracted value
    func extractValue(from line: String, prefix prefixes: [String]) -> String
    
    /// Extracts a value for specific patterns from a line
    /// - Parameters:
    ///   - patterns: Array of patterns to match in the line
    ///   - line: The line of text to extract from
    /// - Returns: The extracted value if found, nil otherwise
    func extractValueForPatterns(_ patterns: [String], from line: String) -> String?
    
    /// Extracts an amount for specific patterns from a line
    /// - Parameters:
    ///   - patterns: Array of patterns to match in the line
    ///   - line: The line of text to extract from
    /// - Returns: The extracted amount if found, nil otherwise
    func extractAmountForPatterns(_ patterns: [String], from line: String) -> Double?
    
    /// Extracts an amount from a string with improved handling
    /// - Parameter string: The string to extract an amount from
    /// - Returns: The extracted amount if found, nil otherwise
    func extractAmount(from string: String) -> Double?
    
    /// Parses an amount string to a Double with improved handling
    /// - Parameter string: The string to parse
    /// - Returns: The parsed amount
    func parseAmount(_ string: String) -> Double
}

/// Service for handling pattern matching utility operations
class PatternMatchingUtilityService: PatternMatchingUtilityServiceProtocol {
    
    // MARK: - Public Methods
    
    /// Extracts a value from a line of text by removing prefixes
    /// - Parameters:
    ///   - line: The line of text to extract from
    ///   - prefixes: The prefixes to remove
    /// - Returns: The extracted value
    func extractValue(from line: String, prefix prefixes: [String]) -> String {
        var result = line
        for prefix in prefixes {
            if result.contains(prefix) {
                result = result.replacingOccurrences(of: prefix, with: "")
                break
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts a value for specific patterns from a line
    /// - Parameters:
    ///   - patterns: Array of patterns to match in the line
    ///   - line: The line of text to extract from
    /// - Returns: The extracted value if found, nil otherwise
    func extractValueForPatterns(_ patterns: [String], from line: String) -> String? {
        for pattern in patterns {
            if line.contains(pattern) {
                let value = extractValue(from: line, prefix: [pattern])
                if !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }
    
    /// Extracts an amount for specific patterns from a line
    /// - Parameters:
    ///   - patterns: Array of patterns to match in the line
    ///   - line: The line of text to extract from
    /// - Returns: The extracted amount if found, nil otherwise
    func extractAmountForPatterns(_ patterns: [String], from line: String) -> Double? {
        for pattern in patterns {
            if line.contains(pattern) {
                let valueString = extractValue(from: line, prefix: [pattern])
                if let amount = extractAmount(from: valueString) {
                    return amount
                }
            }
        }
        return nil
    }
    
    /// Extracts an amount from a string with improved handling
    /// - Parameter string: The string to extract an amount from
    /// - Returns: The extracted amount if found, nil otherwise
    func extractAmount(from string: String) -> Double? {
        // First, try to find a number pattern with currency symbols (including €, ₹, $, Rs.)
        if let amountMatch = string.range(of: "[₹€$Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)", options: .regularExpression) {
            let amountString = String(string[amountMatch])
            return parseAmount(amountString)
        }
        
        // If that fails, try to find any number pattern
        if let amountMatch = string.range(of: "(\\d+[,\\d]*\\.?\\d*)", options: .regularExpression) {
            let amountString = String(string[amountMatch])
            return parseAmount(amountString)
        }
        
        // If all else fails, try parsing the whole string
        return parseAmount(string)
    }
    
    /// Parses an amount string to a Double with improved handling
    /// - Parameter string: The string to parse
    /// - Returns: The parsed amount
    func parseAmount(_ string: String) -> Double {
        // Remove currency symbols and other non-numeric characters
        let cleanedString = string.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        
        // Handle Indian number format (e.g., 1,00,000.00)
        var processedString = cleanedString
        
        // Replace all commas with nothing
        processedString = processedString.replacingOccurrences(of: ",", with: "")
        
        // Try to parse the number
        if let amount = Double(processedString) {
            return amount
        }
        
        // If that fails, try alternative parsing with NumberFormatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        
        if let amount = formatter.number(from: cleanedString)?.doubleValue {
            return amount
        }
        
        // Try with Indian locale
        formatter.locale = Locale(identifier: "en_IN")
        if let amount = formatter.number(from: cleanedString)?.doubleValue {
            return amount
        }
        
        return 0.0
    }
} 
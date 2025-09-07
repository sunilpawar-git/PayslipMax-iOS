import Foundation

/// Validation utilities for text extraction
struct TextExtractionValidation {
    
    // MARK: - Blacklist Validation
    
    /// Checks if a term is blacklisted in a specific context
    /// - Parameters:
    ///   - term: The term to check
    ///   - context: The context (e.g., "earnings" or "deductions")
    ///   - patternProvider: Pattern provider for blacklist data
    /// - Returns: True if the term is blacklisted in the given context
    static func isBlacklisted(_ term: String, in context: String, patternProvider: PatternProvider) -> Bool {
        // Check global blacklist
        if patternProvider.blacklistedTerms.contains(term) {
            return true
        }
        
        // Check context-specific blacklist
        if let contextBlacklist = patternProvider.contextSpecificBlacklist[context], 
           contextBlacklist.contains(term) {
            return true
        }
        
        return false
    }
    
    // MARK: - Numeric Value Validation
    
    /// Cleans and validates numeric values from text
    /// - Parameter value: Raw numeric string value
    /// - Returns: Cleaned numeric string
    static func cleanNumericValue(_ value: String) -> String {
        // Remove common currency symbols and formatting
        var cleaned = value
        
        // Remove currency symbols
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "₹", with: "")
        cleaned = cleaned.replacingOccurrences(of: "€", with: "")
        cleaned = cleaned.replacingOccurrences(of: "£", with: "")
        cleaned = cleaned.replacingOccurrences(of: "¥", with: "")
        
        // Remove common formatting
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        
        // Handle negative values in parentheses
        if cleaned.hasPrefix("(") && cleaned.hasSuffix(")") {
            cleaned = "-" + String(cleaned.dropFirst().dropLast())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validates if a string represents a valid numeric value
    /// - Parameter value: String to validate
    /// - Returns: True if the string represents a valid number
    static func isValidNumericValue(_ value: String) -> Bool {
        let cleaned = cleanNumericValue(value)
        return Double(cleaned) != nil
    }
    
    /// Extracts and validates numeric value from text using a pattern
    /// - Parameters:
    ///   - text: Source text
    ///   - pattern: Regex pattern to match
    /// - Returns: Validated numeric value if found and valid
    static func extractValidatedNumericValue(from text: String, using pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let value = String(text[range])
                let cleaned = cleanNumericValue(value)
                
                if isValidNumericValue(cleaned) {
                    return Double(cleaned)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Code Validation and Cleaning
    
    /// Attempts to extract a clean code from a potentially merged code
    /// - Parameters:
    ///   - code: The code to clean
    ///   - patternProvider: Pattern provider for merge patterns
    /// - Returns: A tuple containing the cleaned code and any extracted value
    static func extractCleanCode(from code: String, patternProvider: PatternProvider) -> (cleanedCode: String, extractedValue: Double?) {
        // Check for numeric prefix pattern (e.g., "3600DSOP")
        if let regex = try? NSRegularExpression(pattern: patternProvider.mergedCodePatterns["numericPrefix"] ?? "^([0-9]+)([A-Z][A-Za-z0-9\\-]*)$", options: []),
           let match = regex.firstMatch(in: code, options: [], range: NSRange(code.startIndex..., in: code)),
           match.numberOfRanges == 3,
           let valueRange = Range(match.range(at: 1), in: code),
           let codeRange = Range(match.range(at: 2), in: code) {
            
            let valueStr = String(code[valueRange])
            let cleanedCode = String(code[codeRange])
            
            if let value = Double(valueStr) {
                return (cleanedCode, value)
            }
        }
        
        // Check for abbreviation with delimiter pattern (e.g., "ARR-RSHNA")
        if let regex = try? NSRegularExpression(pattern: patternProvider.mergedCodePatterns["abbreviationPrefix"] ?? "^([A-Z]+)\\-([A-Za-z0-9]+)$", options: []),
           let match = regex.firstMatch(in: code, options: [], range: NSRange(code.startIndex..., in: code)),
           match.numberOfRanges == 3,
           let abbreviationRange = Range(match.range(at: 1), in: code),
           let remainderRange = Range(match.range(at: 2), in: code) {
            
            let abbreviation = String(code[abbreviationRange])
            let remainder = String(code[remainderRange])
            
            // Check if the abbreviation has a known expansion through MilitaryAbbreviationsService
            if let militaryAbbreviation = MilitaryAbbreviationsService.shared.abbreviation(forCode: abbreviation) {
                return (militaryAbbreviation.description + remainder, nil)
            }
        }
        
        return (code, nil)
    }
    
    /// Validates if a code format is expected for the given context
    /// - Parameters:
    ///   - code: Code to validate
    ///   - context: Context (earnings/deductions)
    /// - Returns: True if code format is valid
    static func isValidCodeFormat(_ code: String, for context: String) -> Bool {
        // Basic validation rules
        guard !code.isEmpty else { return false }
        
        // Check for reasonable length (military codes are typically 2-8 characters)
        guard code.count >= 2 && code.count <= 8 else { return false }
        
        // Check for valid characters (alphanumeric and hyphens)
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let codeCharacterSet = CharacterSet(charactersIn: code)
        guard validCharacterSet.isSuperset(of: codeCharacterSet) else { return false }
        
        return true
    }
    
    // MARK: - Risk and Hardship Validation
    
    /// Gets risk/hardship description for a code with validation
    /// - Parameters:
    ///   - code: The code to look up
    ///   - patternProvider: Pattern provider (unused for now)
    /// - Returns: Description if valid code found
    static func getRiskHardshipDescription(for code: String, patternProvider: PatternProvider) -> String? {
        // Clean the code first
        let cleanedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Check using MilitaryAbbreviationsService
        if let abbreviation = MilitaryAbbreviationsService.shared.abbreviation(forCode: cleanedCode) {
            return abbreviation.description
        }
        
        // Check for hardcoded risk/hardship descriptions for now
        let riskHardshipDescriptions: [String: String] = [
            "RH11": "Risk and Hardship Level 1",
            "RH12": "Risk and Hardship Level 2", 
            "RH13": "Risk and Hardship Level 3",
            "RH21": "Risk and Hardship Level 2-1",
            "RH22": "Risk and Hardship Level 2-2",
            "RH23": "Risk and Hardship Level 2-3",
            "RH31": "Risk and Hardship Level 3-1",
            "RH32": "Risk and Hardship Level 3-2",
            "RH33": "Risk and Hardship Level 3-3"
        ]
        
        // Check direct match
        if let description = riskHardshipDescriptions[cleanedCode] {
            return description
        }
        
        // Check for partial matches (for codes that might have suffixes)
        for (key, description) in riskHardshipDescriptions {
            if cleanedCode.hasPrefix(key) || key.hasPrefix(cleanedCode) {
                return description
            }
        }
        
        return nil
    }
}

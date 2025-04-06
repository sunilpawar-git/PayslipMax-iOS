import Foundation

/// A service that handles pattern matching operations for payslip data extraction
class PatternMatchingService: PatternMatchingServiceProtocol {
    // MARK: - Properties
    
    /// Dictionary of regex patterns for extracting data from payslips
    private var patterns: [String: String] = [:]
    
    /// Dictionary of regex patterns for extracting earnings
    private var earningsPatterns: [String: String] = [:]
    
    /// Dictionary of regex patterns for extracting deductions
    private var deductionsPatterns: [String: String] = [:]
    
    /// Standard earnings components for categorization
    private let standardEarningsComponents: [String]
    
    /// Standard deductions components for categorization
    private let standardDeductionsComponents: [String]
    
    /// Terms that should never be considered as pay items (blacklist)
    private let blacklistedTerms: [String]
    
    /// Context-specific blacklisted terms
    private let contextSpecificBlacklist: [String: [String]]
    
    // MARK: - Initialization
    
    init() {
        // Copy patterns from PayslipPatternManager
        self.patterns = PayslipPatternManager.patterns
        self.earningsPatterns = PayslipPatternManager.earningsPatterns
        self.deductionsPatterns = PayslipPatternManager.deductionsPatterns
        self.standardEarningsComponents = PayslipPatternManager.standardEarningsComponents
        self.standardDeductionsComponents = PayslipPatternManager.standardDeductionsComponents
        self.blacklistedTerms = PayslipPatternManager.blacklistedTerms
        self.contextSpecificBlacklist = PayslipPatternManager.contextSpecificBlacklist
        
        print("PatternMatchingService: Initialized with \(patterns.count) patterns, \(earningsPatterns.count) earnings patterns, and \(deductionsPatterns.count) deductions patterns")
    }
    
    // MARK: - Public Methods
    
    /// Extracts values from text using predefined patterns
    /// - Parameter text: The text to extract values from
    /// - Returns: Dictionary of extracted values keyed by field names
    func extractData(from text: String) -> [String: String] {
        print("PatternMatchingService: Starting data extraction from text")
        var extractedData: [String: String] = [:]
        
        // Apply each pattern to extract data
        for (key, pattern) in patterns {
            if let value = extractValueUsingPattern(pattern, from: text) {
                extractedData[key] = value
                print("PatternMatchingService: Extracted '\(key)': \(value)")
            }
        }
        
        return extractedData
    }
    
    /// Extracts tabular data (earnings and deductions) from text
    /// - Parameter text: The text to extract tabular data from
    /// - Returns: A tuple containing dictionaries of earnings and deductions
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        print("PatternMatchingService: Starting tabular data extraction")
        
        // Initialize result dictionaries
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Extract using predefined earnings patterns
        for (key, pattern) in earningsPatterns {
            if let value = extractNumericValueUsingPattern(pattern, from: text) {
                earnings[key] = value
                print("PatternMatchingService: Extracted earnings '\(key)': \(value)")
            }
        }
        
        // Extract using predefined deductions patterns
        for (key, pattern) in deductionsPatterns {
            if let value = extractNumericValueUsingPattern(pattern, from: text) {
                deductions[key] = value
                print("PatternMatchingService: Extracted deduction '\(key)': \(value)")
            }
        }
        
        // Look for tabular data in the text
        extractTabularStructure(from: text, into: &earnings, and: &deductions)
        
        return (earnings, deductions)
    }
    
    /// Extracts a value for a specific pattern key from text
    /// - Parameters:
    ///   - key: The pattern key to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted value, or nil if not found
    func extractValue(for key: String, from text: String) -> String? {
        guard let pattern = patterns[key] else {
            print("PatternMatchingService: No pattern found for key '\(key)'")
            return nil
        }
        
        return extractValueUsingPattern(pattern, from: text)
    }
    
    /// Extracts a numeric value for a specific pattern key from text
    /// - Parameters:
    ///   - key: The pattern key to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted numeric value, or nil if not found or not a valid number
    func extractNumericValue(for key: String, from text: String) -> Double? {
        guard let pattern = patterns[key] else {
            print("PatternMatchingService: No pattern found for key '\(key)'")
            return nil
        }
        
        return extractNumericValueUsingPattern(pattern, from: text)
    }
    
    /// Adds a new pattern to the patterns dictionary
    /// - Parameters:
    ///   - key: The key for the pattern
    ///   - pattern: The regex pattern
    func addPattern(key: String, pattern: String) {
        patterns[key] = pattern
        print("PatternMatchingService: Added pattern for key '\(key)'")
    }
    
    // MARK: - Private Methods
    
    /// Extracts a value using a regex pattern
    /// - Parameters:
    ///   - pattern: The regex pattern to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted value, or nil if not found
    private func extractValueUsingPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            
            // Find the first match
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) {
                // Get capture group 1 (the part we want)
                if match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    if valueRange.location != NSNotFound {
                        let value = nsString.substring(with: valueRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        return value.isEmpty ? nil : value
                    }
                }
            }
        } catch {
            print("PatternMatchingService: Error creating regex for pattern '\(pattern)': \(error)")
        }
        
        return nil
    }
    
    /// Extracts a numeric value using a regex pattern
    /// - Parameters:
    ///   - pattern: The regex pattern to use
    ///   - text: The text to extract the value from
    /// - Returns: The extracted numeric value, or nil if not found or not a valid number
    private func extractNumericValueUsingPattern(_ pattern: String, from text: String) -> Double? {
        guard let valueString = extractValueUsingPattern(pattern, from: text) else {
            return nil
        }
        
        // Clean numeric string and convert to Double
        let cleanedString = valueString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanedString)
    }
    
    /// Extracts tabular structure data from text
    /// - Parameters:
    ///   - text: The text to extract from
    ///   - earnings: Dictionary to store earnings
    ///   - deductions: Dictionary to store deductions
    private func extractTabularStructure(from text: String, into earnings: inout [String: Double], and deductions: inout [String: Double]) {
        // Split the text into lines
        let lines = text.components(separatedBy: .newlines)
        
        // Look for possible tabular data in each line
        for line in lines {
            // Skip very short lines that are unlikely to contain tabular data
            if line.count < 5 {
                continue
            }
            
            // Look for patterns like: CODE AMOUNT
            let codeAmountPattern = "([A-Z][A-Z0-9]+)\\s+(\\d+[.,]?\\d*)"
            
            // Try to find code-amount pairs in the line
            do {
                let regex = try NSRegularExpression(pattern: codeAmountPattern, options: [])
                let nsString = line as NSString
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 2 {
                        let codeRange = match.range(at: 1)
                        let amountRange = match.range(at: 2)
                        
                        if codeRange.location != NSNotFound && amountRange.location != NSNotFound {
                            let code = nsString.substring(with: codeRange)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            let amountString = nsString.substring(with: amountRange)
                                .replacingOccurrences(of: ",", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if let amount = Double(amountString), amount > 0 {
                                // Determine if this is an earning or deduction based on code
                                categorizeItem(code: code, amount: amount, earnings: &earnings, deductions: &deductions)
                            }
                        }
                    }
                }
            } catch {
                print("PatternMatchingService: Error extracting tabular data: \(error)")
            }
        }
    }
    
    /// Categorizes an item as an earning or deduction based on its code
    /// - Parameters:
    ///   - code: The item code
    ///   - amount: The item amount
    ///   - earnings: Dictionary to store earnings
    ///   - deductions: Dictionary to store deductions
    private func categorizeItem(code: String, amount: Double, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Skip blacklisted terms
        if blacklistedTerms.contains(code) {
            return
        }
        
        // Check if code is a known earnings component
        if standardEarningsComponents.contains(code) {
            earnings[code] = amount
            print("PatternMatchingService: Categorized '\(code)' as earnings: \(amount)")
            return
        }
        
        // Check if code is a known deductions component
        if standardDeductionsComponents.contains(code) {
            deductions[code] = amount
            print("PatternMatchingService: Categorized '\(code)' as deduction: \(amount)")
            return
        }
        
        // If not clearly categorized, make a best guess
        // For now, assume it's an earning (can be improved with additional logic)
        earnings[code] = amount
        print("PatternMatchingService: Default categorized '\(code)' as earnings: \(amount)")
    }
} 
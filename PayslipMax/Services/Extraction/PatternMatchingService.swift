import Foundation

/// A service responsible for extracting structured data from payslip text content using pattern-based recognition.
///
/// This service is a core component in the Pattern Matching System architecture and serves as the primary 
/// implementation of the `PatternMatchingServiceProtocol`. It applies predefined regex patterns to extract
/// key-value data and tabular financial information from payslip text content.
///
/// The service handles several types of pattern matching:
/// - General key-value extraction (e.g., name, PAN number, dates)
/// - Financial data extraction (earnings and deductions)
/// - Tabular data structure identification and categorization
///
/// It works in conjunction with:
/// - `PatternProvider`: Supplies the regex patterns used for extraction
/// - `PayslipPatternManager`: Legacy interface providing default patterns
/// - `PatternMatchingUtilityService`: Helper service for pattern matching operations
///
/// The service is optimized for handling the diverse formatting found in various payslip types
/// (military, corporate, government) and can identify specific earnings and deduction codes
/// using predefined categorization rules.
class PatternMatchingService: PatternMatchingServiceProtocol {
    // MARK: - Properties
    
    /// Dictionary of regex patterns for extracting general key-value data from payslips.
    /// Keys represent field identifiers (e.g., "name", "panNumber") and values are regex patterns.
    private var patterns: [String: String] = [:]
    
    /// Dictionary of regex patterns specifically for extracting earnings-related financial data.
    /// Keys represent earning type identifiers (e.g., "basicPay", "hra") and values are regex patterns.
    private var earningsPatterns: [String: String] = [:]
    
    /// Dictionary of regex patterns specifically for extracting deduction-related financial data.
    /// Keys represent deduction type identifiers (e.g., "tax", "pf") and values are regex patterns.
    private var deductionsPatterns: [String: String] = [:]
    
    /// Standard earnings components for categorization of tabular data.
    /// Used to determine if an extracted code should be categorized as an earning.
    private let standardEarningsComponents: [String]
    
    /// Standard deductions components for categorization of tabular data.
    /// Used to determine if an extracted code should be categorized as a deduction.
    private let standardDeductionsComponents: [String]
    
    /// Terms that should never be considered as pay items (blacklist).
    /// Used to filter out false positives during tabular data extraction.
    private let blacklistedTerms: [String]
    
    /// Context-specific blacklisted terms mapped by context identifier.
    /// Provides more granular control over blacklisting based on the specific
    /// section or context within a document.
    private let contextSpecificBlacklist: [String: [String]]
    
    // MARK: - Initialization
    
    /// Initializes the service with default pattern sets from the PayslipPatternManager.
    ///
    /// This initializer configures the service with standard patterns for field extraction,
    /// earnings, deductions, and categorization rules. It relies on the PayslipPatternManager
    /// as a central repository of patterns.
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
    
    /// Extracts key-value data from text using predefined patterns.
    ///
    /// This method iterates through all registered patterns, applying each one to the input text
    /// and collecting successful matches into a dictionary. It is the primary method for extracting
    /// non-tabular information from payslip text.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    ///   The dictionary will only contain entries for patterns that successfully matched.
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
    
    /// Extracts tabular financial data (earnings and deductions) from payslip text.
    ///
    /// This method performs a three-stage extraction process:
    /// 1. Applies predefined earnings patterns to identify specific earnings items
    /// 2. Applies predefined deductions patterns to identify specific deductions items
    /// 3. Searches for tabular structures in the text to identify additional items
    ///
    /// The resulting dictionaries map item codes/names to their monetary values.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: A tuple containing two dictionaries:
    ///   - First dictionary: Earnings items (code/name -> amount)
    ///   - Second dictionary: Deductions items (code/name -> amount)
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
    
    /// Extracts a string value for a specific pattern key from text.
    ///
    /// This method provides a way to extract a single field value using its key,
    /// rather than extracting all fields. It first looks up the pattern associated
    /// with the key, then applies that pattern to the text.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction (e.g., "name", "panNumber").
    ///   - text: The text content to extract the value from.
    /// - Returns: The extracted string value if found, or nil if the pattern doesn't match
    ///   or the key doesn't exist in the patterns dictionary.
    func extractValue(for key: String, from text: String) -> String? {
        guard let pattern = patterns[key] else {
            print("PatternMatchingService: No pattern found for key '\(key)'")
            return nil
        }
        
        return extractValueUsingPattern(pattern, from: text)
    }
    
    /// Extracts a numeric value for a specific pattern key from text.
    ///
    /// Similar to `extractValue(for:from:)` but specifically for numeric fields.
    /// After extracting the text value, this method converts it to a Double,
    /// handling currency symbols and formatting characters.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction (e.g., "basicPay", "tax").
    ///   - text: The text content to extract the value from.
    /// - Returns: The extracted value as a Double if found and successfully converted,
    ///   or nil if the pattern doesn't match, the key doesn't exist, or the value
    ///   cannot be converted to a number.
    func extractNumericValue(for key: String, from text: String) -> Double? {
        guard let pattern = patterns[key] else {
            print("PatternMatchingService: No pattern found for key '\(key)'")
            return nil
        }
        
        return extractNumericValueUsingPattern(pattern, from: text)
    }
    
    /// Adds a new pattern to the patterns dictionary.
    ///
    /// This method allows for dynamic registration of new extraction patterns at runtime.
    /// New patterns can be used to extract fields that weren't anticipated when the service
    /// was initialized.
    ///
    /// - Parameters:
    ///   - key: The identifier for the pattern, used to retrieve the extracted value.
    ///   - pattern: The regex pattern string. Should include a capture group to extract the desired value.
    func addPattern(key: String, pattern: String) {
        patterns[key] = pattern
        print("PatternMatchingService: Added pattern for key '\(key)'")
    }
    
    // MARK: - Private Methods
    
    /// Extracts a value from text using a specific regex pattern.
    ///
    /// This is the core pattern matching implementation that:
    /// 1. Compiles the regex pattern
    /// 2. Searches for matches in the text
    /// 3. Extracts the first capture group (assumed to contain the desired value)
    /// 4. Cleans and returns the extracted value
    ///
    /// The pattern is expected to contain a capture group (parentheses) that isolates
    /// the specific data to be extracted.
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern string to use for matching.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value from the first capture group if found, or nil if no match.
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
    
    /// Extracts a numeric value from text using a regex pattern.
    ///
    /// This method extends `extractValueUsingPattern(_:from:)` by adding currency
    /// symbol removal and numeric conversion. It handles common currency notations
    /// found in payslips, including:
    /// - Indian Rupee symbol (₹)
    /// - 'Rs.' and 'Rs' prefixes
    /// - Dollar sign ($)
    /// - Comma-separated numbers (e.g., 1,000.00)
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern string to use for matching.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value as a Double if successfully found and converted, otherwise nil.
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
    
    /// Extracts tabular structure data from text content.
    ///
    /// This method searches for tabular data structures in the text, specifically
    /// looking for code-amount pairs that typically represent earnings or deductions
    /// items in a payslip. It uses a regex pattern to identify code-amount pairs
    /// and then categorizes each item as either an earning or deduction.
    ///
    /// The method is designed to handle various tabular formats found in payslips,
    /// particularly sections where financial items are listed in rows with codes and amounts.
    ///
    /// - Parameters:
    ///   - text: The text content to search for tabular data.
    ///   - earnings: Dictionary to store identified earnings items (modified in-place).
    ///   - deductions: Dictionary to store identified deductions items (modified in-place).
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
    
    /// Categorizes a financial item as either an earning or a deduction.
    ///
    /// This method uses several rules to determine whether an extracted code-amount pair
    /// represents an earning or a deduction:
    ///
    /// 1. First checks if the code is in the blacklist (terms to ignore)
    /// 2. Checks if the code is in the standardEarningsComponents list
    /// 3. Checks if the code is in the standardDeductionsComponents list
    /// 4. If not explicitly categorized, defaults to treating the item as an earning
    ///
    /// The categorization rules can be customized by modifying the standardEarningsComponents,
    /// standardDeductionsComponents, and blacklistedTerms properties during initialization.
    ///
    /// - Parameters:
    ///   - code: The item code or identifier extracted from the payslip.
    ///   - amount: The monetary amount associated with the code.
    ///   - earnings: Dictionary to store the item if categorized as an earning (modified in-place).
    ///   - deductions: Dictionary to store the item if categorized as a deduction (modified in-place).
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
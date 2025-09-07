import Foundation

/// Strategies for text extraction and data parsing
struct TextExtractionStrategies {
    
    // MARK: - Month and Year Extraction
    
    /// Extracts month and year from text using various patterns
    /// - Parameter text: Source text to extract from
    /// - Returns: Tuple with optional month and year strings
    static func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        var month: String?
        var year: String?
        
        // Try to extract month and year using regex patterns
        let monthYearPatterns = [
            // Pattern for "January 2024", "Feb 2024", etc.
            "(?i)(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+(\\d{4})",
            // Pattern for "01/2024", "1/2024", etc.
            "(\\d{1,2})/(\\d{4})",
            // Pattern for "2024-01", "2024/01", etc.
            "(\\d{4})[-/](\\d{1,2})"
        ]
        
        for pattern in monthYearPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                
                if match.numberOfRanges >= 3 {
                    let range1 = Range(match.range(at: 1), in: text)
                    let range2 = Range(match.range(at: 2), in: text)
                    
                    if let range1 = range1, let range2 = range2 {
                        let part1 = String(text[range1])
                        let part2 = String(text[range2])
                        
                        // Determine which part is month and which is year
                        if part2.count == 4 && Int(part2) != nil {
                            // part2 is year, part1 is month
                            year = part2
                            month = convertToMonthName(part1)
                        } else if part1.count == 4 && Int(part1) != nil {
                            // part1 is year, part2 is month
                            year = part1
                            month = convertToMonthName(part2)
                        }
                    }
                }
                
                // If we found both month and year, break
                if month != nil && year != nil {
                    break
                }
            }
        }
        
        return (month, year)
    }
    
    /// Converts month representation to standardized month name
    /// - Parameter monthInput: Month as string (number or name)
    /// - Returns: Standardized month name
    private static func convertToMonthName(_ monthInput: String) -> String {
        let monthNames = [
            "01": "January", "02": "February", "03": "March", "04": "April",
            "05": "May", "06": "June", "07": "July", "08": "August",
            "09": "September", "10": "October", "11": "November", "12": "December",
            "1": "January", "2": "February", "3": "March", "4": "April",
            "5": "May", "6": "June", "7": "July", "8": "August",
            "9": "September"
        ]
        
        let abbreviations = [
            "Jan": "January", "Feb": "February", "Mar": "March", "Apr": "April",
            "May": "May", "Jun": "June", "Jul": "July", "Aug": "August",
            "Sep": "September", "Oct": "October", "Nov": "November", "Dec": "December"
        ]
        
        // Check if it's already a full month name
        let fullMonths = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
        if fullMonths.contains(monthInput) {
            return monthInput
        }
        
        // Check abbreviations
        if let fullName = abbreviations[monthInput] {
            return fullName
        }
        
        // Check numeric representations
        if let fullName = monthNames[monthInput] {
            return fullName
        }
        
        return monthInput // Return as-is if no conversion found
    }
    
    // MARK: - Tabular Data Extraction
    
    /// Extracts earnings data using pattern matching
    /// - Parameters:
    ///   - text: Source text
    ///   - earningsPatterns: Dictionary of earnings patterns
    /// - Returns: Dictionary of earnings codes and values
    static func extractEarnings(from text: String, using earningsPatterns: [String: String]) -> [String: Double] {
        var earnings: [String: Double] = [:]
        
        for (code, pattern) in earningsPatterns {
            if let value = TextExtractionValidation.extractValidatedNumericValue(from: text, using: pattern) {
                earnings[code] = value
            }
        }
        
        return earnings
    }
    
    /// Extracts deductions data using pattern matching
    /// - Parameters:
    ///   - text: Source text
    ///   - deductionsPatterns: Dictionary of deductions patterns
    /// - Returns: Dictionary of deductions codes and values
    static func extractDeductions(from text: String, using deductionsPatterns: [String: String]) -> [String: Double] {
        var deductions: [String: Double] = [:]
        
        for (code, pattern) in deductionsPatterns {
            if let value = TextExtractionValidation.extractValidatedNumericValue(from: text, using: pattern) {
                deductions[code] = value
            }
        }
        
        return deductions
    }
    
    // MARK: - Pattern-Based Data Extraction
    
    /// Extracts general data using pattern dictionary
    /// - Parameters:
    ///   - text: Source text
    ///   - patterns: Dictionary of patterns to apply
    ///   - skipKeys: Keys to skip during extraction
    /// - Returns: Dictionary of extracted data
    static func extractPatternData(from text: String, 
                                 using patterns: [String: String], 
                                 skipKeys: Set<String> = []) -> [String: String] {
        var extractedData: [String: String] = [:]
        
        for (key, pattern) in patterns {
            // Skip specified keys
            if skipKeys.contains(key) {
                continue
            }
            
            // Handle numeric values
            if isNumericKey(key) {
                if let value = TextExtractionValidation.extractValidatedNumericValue(from: text, using: pattern) {
                    extractedData[key] = String(format: "%.2f", value)
                }
                continue
            }
            
            // Handle text values
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: text) {
                        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        extractedData[key] = value
                    }
                }
            }
        }
        
        return extractedData
    }
    
    /// Determines if a key represents numeric data
    /// - Parameter key: Key to check
    /// - Returns: True if key represents numeric data
    private static func isNumericKey(_ key: String) -> Bool {
        let numericKeys = ["grossPay", "totalDeductions", "netRemittance", "tax", "dsop", "credits", "debits"]
        return numericKeys.contains(key)
    }
    
    // MARK: - Advanced Extraction Strategies
    
    /// Extracts data with context awareness and validation
    /// - Parameters:
    ///   - text: Source text
    ///   - patterns: Patterns to use
    ///   - patternProvider: Provider for additional pattern context
    /// - Returns: Dictionary of validated extracted data
    static func extractContextualData(from text: String, 
                                    using patterns: [String: String],
                                    patternProvider: PatternProvider) -> [String: String] {
        let skipKeys: Set<String> = ["month", "year", "statementPeriod"]
        var extractedData = extractPatternData(from: text, using: patterns, skipKeys: skipKeys)
        
        // Add month and year with specialized extraction
        let (month, year) = extractMonthAndYear(from: text)
        if let month = month {
            extractedData["month"] = month
        }
        if let year = year {
            extractedData["year"] = year
        }
        
        // Validate extracted data against blacklists
        extractedData = validateAgainstBlacklists(extractedData, patternProvider: patternProvider)
        
        return extractedData
    }
    
    /// Validates extracted data against blacklists and removes invalid entries
    /// - Parameters:
    ///   - data: Raw extracted data
    ///   - patternProvider: Provider with blacklist information
    /// - Returns: Validated data dictionary
    private static func validateAgainstBlacklists(_ data: [String: String], 
                                               patternProvider: PatternProvider) -> [String: String] {
        var validatedData: [String: String] = [:]
        
        for (key, value) in data {
            let context = determineContext(for: key)
            
            if !TextExtractionValidation.isBlacklisted(value, in: context, patternProvider: patternProvider) {
                validatedData[key] = value
            }
        }
        
        return validatedData
    }
    
    /// Determines the context for a given key
    /// - Parameter key: Key to determine context for
    /// - Returns: Context string
    private static func determineContext(for key: String) -> String {
        if key.contains("earning") || key == "grossPay" {
            return "earnings"
        } else if key.contains("deduction") || key == "totalDeductions" {
            return "deductions"
        }
        return "general"
    }
}

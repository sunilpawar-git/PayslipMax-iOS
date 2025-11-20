import Foundation

/// Handles the actual pattern matching operations for payslip data extraction.
///
/// This component is responsible for the pattern matching concern extracted from
/// PatternMatchingService as part of the SOLID compliance improvement initiative.
/// It focuses solely on applying patterns to text and extracting structured data.
///
/// ## Single Responsibility
/// The PatternMatcher has one clear responsibility: applying regex patterns to text
/// and extracting structured data from matches. This separation allows pattern
/// matching algorithms to be optimized independently of pattern loading logic.
///
/// ## Pattern Matching Strategies
/// The class implements several matching strategies:
/// - Key-value extraction for general fields
/// - Financial data extraction for earnings/deductions
/// - Tabular structure parsing for complex layouts
/// - Categorization of extracted items
class PatternMatcher {

    // MARK: - Properties

    /// The pattern provider used for matching operations.
    private let patternProvider: PatternProvider

    /// The tabular data extractor for handling structured financial data.
    private let tabularExtractor: TabularDataExtractor

    // MARK: - Initialization

    /// Initializes the matcher.
    ///
    /// - Parameter patternProvider: The pattern provider to use for matching operations.
    init(patternProvider: PatternProvider = DefaultPatternProvider()) {
        self.patternProvider = patternProvider
        self.tabularExtractor = TabularDataExtractor()
    }

    // MARK: - Key-Value Extraction

    /// Extracts key-value data from text using the configured general patterns.
    ///
    /// This method iterates through all registered patterns, applying each one to the input text
    /// and collecting successful matches into a dictionary. It is the primary method for extracting
    /// non-tabular information from payslip text.
    ///
    /// The extraction process is non-destructive, meaning that if multiple patterns match different
    /// parts of the text, all matches will be included in the result dictionary.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    func extractKeyValueData(from text: String) -> [String: String] {
        print("PatternMatcher: Starting key-value data extraction from text")
        var extractedData: [String: String] = [:]

        // Apply each pattern to extract data
        for (key, pattern) in patternProvider.patterns {
            if let value = extractValue(using: pattern, from: text) {
                extractedData[key] = value
                print("PatternMatcher: Extracted '\(key)': \(value)")
            }
        }

        return extractedData
    }

    /// Extracts a specific value using a pattern key.
    ///
    /// This method looks up the pattern associated with the given key and applies it
    /// to the provided text. It provides a targeted extraction capability for when
    /// only specific fields need to be extracted.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value as a string if found, otherwise nil.
    func extractValue(for key: String, from text: String) -> String? {
        guard let pattern = patternProvider.patterns[key] else {
            print("PatternMatcher: No pattern found for key '\(key)'")
            return nil
        }

        return extractValue(using: pattern, from: text)
    }

    /// Extracts a numeric value using a pattern key.
    ///
    /// This method extends the basic value extraction by adding currency symbol removal
    /// and numeric conversion. It handles common currency notations found in payslips.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value as a Double if found and valid, otherwise nil.
    func extractNumericValue(for key: String, from text: String) -> Double? {
        guard let pattern = patternProvider.patterns[key] else {
            print("PatternMatcher: No pattern found for key '\(key)'")
            return nil
        }

        return extractNumericValue(using: pattern, from: text)
    }

    // MARK: - Financial Data Extraction

    /// Extracts tabular financial data (earnings and deductions) from payslip text.
    ///
    /// This method performs a three-stage extraction process:
    /// 1. Applies predefined earnings patterns to identify specific earnings items
    /// 2. Applies predefined deductions patterns to identify specific deductions items
    /// 3. Searches for tabular structures in the text to identify additional items
    ///
    /// - Parameter text: The text content to extract financial data from.
    /// - Returns: A tuple containing dictionaries of earnings and deductions mapped to their values.
    func extractFinancialData(from text: String) -> ([String: Double], [String: Double]) {
        print("PatternMatcher: Starting tabular data extraction from text")
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Extract earnings using specific patterns
        for (key, pattern) in patternProvider.earningsPatterns {
            if let value = extractNumericValue(using: pattern, from: text) {
                earnings[key] = value
                print("PatternMatcher: Extracted earnings '\(key)': \(value)")
            }
        }

        // Extract deductions using specific patterns
        for (key, pattern) in patternProvider.deductionsPatterns {
            if let value = extractNumericValue(using: pattern, from: text) {
                deductions[key] = value
                print("PatternMatcher: Extracted deduction '\(key)': \(value)")
            }
        }

        // Extract additional tabular structure data
        tabularExtractor.extractTabularStructure(from: text, into: &earnings, and: &deductions)

        return (earnings, deductions)
    }

    // MARK: - Private Extraction Methods

    /// Extracts a value from text using a regex pattern.
    ///
    /// This is the core pattern matching method that handles regex compilation,
    /// execution, and result extraction. It's designed to be reusable across
    /// different extraction scenarios.
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern string to use for matching.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value from the first capture group if found, otherwise nil.
    private func extractValue(using pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if let match = results.first, match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound {
                    let extractedValue = nsString.substring(with: range)
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !extractedValue.isEmpty {
                        return extractedValue
                    }
                }
            }
        } catch {
            print("PatternMatcher: Regex error for pattern '\(pattern)': \(error)")
        }

        return nil
    }

    /// Extracts a numeric value from text using a regex pattern.
    ///
    /// This method extends the basic value extraction by adding currency symbol removal
    /// and numeric conversion. It handles common currency notations found in payslips.
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern string to use for matching.
    ///   - text: The text content to search within.
    /// - Returns: The extracted value as a Double if found and valid, otherwise nil.
    private func extractNumericValue(using pattern: String, from text: String) -> Double? {
        guard let valueString = extractValue(using: pattern, from: text) else {
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
}

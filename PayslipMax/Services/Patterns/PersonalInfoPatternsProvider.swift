import Foundation

/// Provides patterns for extracting personal information from payslips.
///
/// This provider is part of the domain-specific pattern architecture, focusing
/// exclusively on personal identification and metadata patterns. It was extracted
/// from CorePatternsProvider as part of SOLID compliance improvements to achieve
/// better separation of concerns.
///
/// ## Single Responsibility
/// This provider handles only personal information patterns:
/// - Identity information (name, rank)
/// - Temporal information (month, year)
/// - Service information (service number)
/// - Document metadata
///
/// ## Pattern Categories
/// All patterns created by this provider belong to the `.personal` category
/// in the pattern classification system.
class PersonalInfoPatternsProvider {
    
    /// Creates pattern definitions for extracting personal information from payslips.
    ///
    /// This method defines patterns for extracting personal identification details including:
    /// - Full name: Handles various name formats with different prefixes and layouts
    /// - Rank/Grade: Extracts military rank or employment grade information
    /// - Month/Year: Identifies the payslip period using various date formats
    ///
    /// ## Pattern Types and Configurations
    ///
    /// ### Name Extraction Patterns
    /// Multiple patterns are used for name extraction to handle different formats:
    /// - Primary pattern: Matches "name:" or "officer:" followed by text
    /// - Keyword pattern: Identifies the "name" label and extracts text after it
    /// - Service number pattern: Handles military format with service number and name combined
    ///
    /// ### Rank/Grade Extraction
    /// A dedicated pattern that recognizes military ranks and civilian grade designations,
    /// which is crucial for correctly categorizing the document and understanding the
    /// pay scale applicable to the individual.
    ///
    /// ### Date Information Extraction
    /// Separate patterns for month and year extraction that handle various date formats:
    /// - Formats like "for Month YYYY"
    /// - Formats like "month: Month-YYYY"
    /// - Various delimiters (spaces, commas, hyphens)
    ///
    /// The patterns prioritize the most common formats first (higher priority values)
    /// and include fallback patterns for less standard formats.
    ///
    /// - Returns: An array of `PatternDefinition` objects for personal information extraction.
    static func getPersonalInfoPatterns() -> [PatternDefinition] {
        let namePatterns = [
            // Common name formats
            ExtractorPattern.regex(
                pattern: "(?:name|officer)[\\s:]*([A-Za-z\\s]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.keyword(
                keyword: "name",
                contextAfter: "\n",
                priority: 5
            ),
            ExtractorPattern.regex(
                pattern: "(?:service no & name)[\\s:]*\\d+\\s+([A-Za-z\\s]+)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim],
                priority: 8
            )
        ]
        
        // Create name pattern definition
        let namePattern = PatternDefinition.createCorePattern(
            name: "Full Name",
            key: "name",
            category: .personal,
            patterns: namePatterns
        )
        
        // Rank pattern
        let rankPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:rank|grade)[\\s:]*([A-Za-z0-9\\s]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            )
        ]
        
        let rankPattern = PatternDefinition.createCorePattern(
            name: "Rank/Grade",
            key: "rank",
            category: .personal,
            patterns: rankPatterns
        )
        
        // Month/Year extraction
        let datePatterns = [
            ExtractorPattern.regex(
                pattern: "(?:for|month of|period)[\\s:]*([A-Za-z]+)[\\s,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:date|month|period)[\\s:]*([A-Za-z]+)[\\s\\-,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 8
            )
        ]
        
        let monthPattern = PatternDefinition.createCorePattern(
            name: "Month",
            key: "month",
            category: .personal,
            patterns: datePatterns
        )
        
        let yearPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:for|month of|period)[\\s:]*[A-Za-z]+[\\s,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            )
        ]
        
        let yearPattern = PatternDefinition.createCorePattern(
            name: "Year",
            key: "year",
            category: .personal,
            patterns: yearPatterns
        )
        
        return [namePattern, rankPattern, monthPattern, yearPattern]
    }
}

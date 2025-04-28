import Foundation

/// Represents the different strategies available for extracting data using an `ExtractorPattern`.
///
/// Each type corresponds to a specific extraction logic:
/// - `.regex`: Uses regular expressions.
/// - `.keyword`: Searches for keywords and extracts nearby text.
/// - `.positionBased`: Extracts text from specific line/character positions.
enum ExtractorPatternType: String, Codable, CaseIterable {
    /// Regular expression based extraction. The `pattern` string is treated as a regex pattern.
    case regex
    /// Keyword-based extraction. The `pattern` string typically contains the keyword(s) to search for, potentially with context separators.
    case keyword
    /// Position-based extraction. The `pattern` string contains coordinates (line offset, start/end positions).
    case positionBased
    
    /// Provides a user-friendly display name for each pattern type.
    var displayName: String {
        switch self {
        case .regex: return "Regular Expression"
        case .keyword: return "Keyword Search"
        case .positionBased: return "Position Based"
        }
    }
}

/// Defines a specific, self-contained method for extracting a piece of data from text content.
///
/// An `ExtractorPattern` encapsulates:
/// - The type of extraction strategy (`type`).
/// - The core pattern string (`pattern`), interpreted based on the `type`.
/// - Optional text preprocessing steps (`preprocessing`) to apply before extraction.
/// - Optional value postprocessing steps (`postprocessing`) to apply after extraction.
/// - A `priority` level to determine the order in which patterns are attempted within a `PatternDefinition`.
struct ExtractorPattern: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// A unique identifier for this specific pattern instance.
    let id: UUID
    /// The type of extraction strategy this pattern uses (e.g., regex, keyword).
    var type: ExtractorPatternType
    /// The core pattern string used for extraction. Its interpretation depends on the `type`.
    /// - For `.regex`: A valid regular expression string.
    /// - For `.keyword`: The keyword(s) to search for, potentially with context (e.g., "before|keyword|after").
    /// - For `.positionBased`: Comma-separated position directives (e.g., "lineOffset:1,start:10,end:20").
    var pattern: String
    /// Determines the order in which this pattern is attempted relative to others within the same `PatternDefinition`. Higher numbers indicate higher priority (attempted first).
    var priority: Int
    
    /// An array of preprocessing steps to apply sequentially to the input text *before* attempting extraction with this pattern.
    var preprocessing: [PreprocessingStep] = []
    
    /// An array of postprocessing steps to apply sequentially to the extracted string value *after* successful extraction.
    var postprocessing: [PostprocessingStep] = []
    
    // MARK: - Preprocessing and Postprocessing Steps
    
    /// Defines available steps to preprocess text before applying an extraction pattern.
    enum PreprocessingStep: String, Codable, CaseIterable {
        /// Normalizes `\r\n` and `\r` to `\n`.
        case normalizeNewlines
        /// Converts the text to lowercase.
        case normalizeCase
        /// Removes all whitespace characters (spaces, tabs, newlines).
        case removeWhitespace
        /// Replaces sequences of multiple whitespace characters with a single space.
        case normalizeSpaces
        /// Trims leading/trailing whitespace from each line individually.
        case trimLines
    }
    
    /// Defines available steps to postprocess an extracted string value.
    enum PostprocessingStep: String, Codable, CaseIterable {
        /// Trims leading/trailing whitespace and newlines.
        case trim
        /// Attempts to format the value as currency based on the current locale.
        case formatAsCurrency
        /// Removes all characters except digits (0-9) and the period (.).
        case removeNonNumeric
        /// Converts the value to uppercase.
        case uppercase
        /// Converts the value to lowercase.
        case lowercase
    }
    
    // MARK: - Pattern Types (Static Factory Methods)
    
    /// Creates a new `ExtractorPattern` configured for regular expression extraction.
    ///
    /// - Parameters:
    ///   - pattern: The regular expression string to use for matching.
    ///   - preprocessing: An array of preprocessing steps to apply before matching. Defaults to `[.normalizeNewlines]`.
    ///   - postprocessing: An array of postprocessing steps to apply after successful extraction. Defaults to `[.trim]`.
    ///   - priority: The priority level for this pattern. Defaults to 10.
    /// - Returns: A configured `ExtractorPattern` instance of type `.regex`.
    static func regex(
        pattern: String,
        preprocessing: [PreprocessingStep] = [.normalizeNewlines],
        postprocessing: [PostprocessingStep] = [.trim],
        priority: Int = 10
    ) -> ExtractorPattern {
        return ExtractorPattern(
            id: UUID(),
            type: .regex,
            pattern: pattern,
            priority: priority,
            preprocessing: preprocessing,
            postprocessing: postprocessing
        )
    }
    
    /// Creates a new `ExtractorPattern` configured for keyword-based extraction.
    ///
    /// The `pattern` string is constructed internally based on the provided keyword and optional context strings,
    /// typically in the format "contextBefore|keyword|contextAfter".
    ///
    /// - Parameters:
    ///   - keyword: The primary keyword to search for within lines of text.
    ///   - contextBefore: Optional string that must appear on the same line *before* the keyword.
    ///   - contextAfter: Optional string that must appear on the same line *after* the keyword.
    ///   - preprocessing: An array of preprocessing steps. Defaults to `[.normalizeNewlines, .normalizeCase]`.
    ///   - postprocessing: An array of postprocessing steps. Defaults to `[.trim]`.
    ///   - priority: The priority level for this pattern. Defaults to 5.
    /// - Returns: A configured `ExtractorPattern` instance of type `.keyword`.
    static func keyword(
        keyword: String,
        contextBefore: String? = nil,
        contextAfter: String? = nil,
        preprocessing: [PreprocessingStep] = [.normalizeNewlines, .normalizeCase],
        postprocessing: [PostprocessingStep] = [.trim],
        priority: Int = 5
    ) -> ExtractorPattern {
        // Add context information to the pattern
        let patternWithContext = [
            contextBefore,
            keyword,
            contextAfter
        ]
        .compactMap { $0 }
        .joined(separator: "|")
        
        return ExtractorPattern(
            id: UUID(),
            type: .keyword,
            pattern: patternWithContext,
            priority: priority,
            preprocessing: preprocessing,
            postprocessing: postprocessing
        )
    }
    
    /// Creates a new `ExtractorPattern` configured for position-based extraction.
    ///
    /// The `pattern` string is constructed internally from the provided offset and position parameters,
    /// formatted like "lineOffset:N,start:M,end:P".
    ///
    /// - Parameters:
    ///   - lineOffset: The offset (number of lines) relative to a reference point (often the current line in an iteration) to find the target line.
    ///   - startPosition: Optional starting character index (0-based) within the target line.
    ///   - endPosition: Optional ending character index (0-based, exclusive) within the target line.
    ///   - preprocessing: An array of preprocessing steps. Defaults to `[.normalizeNewlines]`.
    ///   - postprocessing: An array of postprocessing steps. Defaults to `[.trim]`.
    ///   - priority: The priority level for this pattern. Defaults to 3.
    /// - Returns: A configured `ExtractorPattern` instance of type `.positionBased`.
    static func positionBased(
        lineOffset: Int,
        startPosition: Int? = nil,
        endPosition: Int? = nil,
        preprocessing: [PreprocessingStep] = [.normalizeNewlines],
        postprocessing: [PostprocessingStep] = [.trim],
        priority: Int = 3
    ) -> ExtractorPattern {
        // Create a pattern string representing position information
        let posInfo = [
            "lineOffset:\(lineOffset)",
            startPosition != nil ? "start:\(startPosition!)" : nil,
            endPosition != nil ? "end:\(endPosition!)" : nil
        ]
        .compactMap { $0 }
        .joined(separator: ",")
        
        return ExtractorPattern(
            id: UUID(),
            type: .positionBased,
            pattern: posInfo,
            priority: priority,
            preprocessing: preprocessing,
            postprocessing: postprocessing
        )
    }
} 
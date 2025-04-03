import Foundation

/// Types of patterns used for extracting data
enum ExtractorPatternType: String, Codable, CaseIterable {
    case regex         // Regular expression based extraction
    case keyword       // Keyword and surrounding text based extraction
    case positionBased // Fixed position based extraction (for fixed-layout PDFs)
    
    var displayName: String {
        switch self {
        case .regex: return "Regular Expression"
        case .keyword: return "Keyword Search"
        case .positionBased: return "Position Based"
        }
    }
}

/// Defines a specific method for extracting a value from text
struct ExtractorPattern: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    let id: UUID
    var type: ExtractorPatternType
    var pattern: String // The main extraction pattern
    var priority: Int // Higher numbers tried first
    
    /// Preprocessing steps to apply to text before extraction
    var preprocessing: [PreprocessingStep] = []
    
    /// Postprocessing steps to apply to the extracted value
    var postprocessing: [PostprocessingStep] = []
    
    // MARK: - Preprocessing and Postprocessing Steps
    
    /// Steps to preprocess text before extraction
    enum PreprocessingStep: String, Codable, CaseIterable {
        case normalizeNewlines
        case normalizeCase
        case removeWhitespace
        case normalizeSpaces
        case trimLines
    }
    
    /// Steps to postprocess extracted values
    enum PostprocessingStep: String, Codable, CaseIterable {
        case trim
        case formatAsCurrency
        case removeNonNumeric
        case uppercase
        case lowercase
    }
    
    // MARK: - Pattern Types
    
    /// Regular expression pattern type
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
    
    /// Keyword-based pattern type with optional context
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
    
    /// Position-based pattern for extracting data based on line position
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
import Foundation
import PDFKit

/// Protocol defining the interface for pattern testing services
/// This follows the SOLID principles by providing a clean abstraction
/// for pattern testing functionality in the MVVM architecture
public protocol PatternTestingServiceProtocol {

    /// Test a pattern against a PDF document
    /// - Parameters:
    ///   - pattern: The pattern definition to test
    ///   - document: The PDF document to test against
    /// - Returns: The extracted value if successful, nil otherwise
    func testPattern(_ pattern: PatternDefinition, against document: PDFDocument) async -> String?

    /// Save test results for analytics
    /// - Parameters:
    ///   - pattern: The pattern that was tested
    ///   - testValue: The extracted value (nil if extraction failed)
    func saveTestResults(pattern: PatternDefinition, testValue: String?)
}

/// Protocol for pattern application strategies
/// Enables dependency injection and testing of different pattern types
public protocol PatternApplicationStrategy {

    /// Apply a pattern to extract a value from text
    /// - Parameters:
    ///   - pattern: The extractor pattern to apply
    ///   - text: The text to extract from
    /// - Returns: The extracted value if successful, nil otherwise
    func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String?
}

/// Protocol for text preprocessing utilities
/// Provides clean abstraction for text normalization operations
public protocol TextPreprocessingProtocol {

    /// Apply a preprocessing step to text
    /// - Parameters:
    ///   - step: The preprocessing step to apply
    ///   - text: The text to preprocess
    /// - Returns: The preprocessed text
    func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String
}

/// Protocol for text postprocessing utilities
/// Provides clean abstraction for value refinement operations
public protocol TextPostprocessingProtocol {

    /// Apply a postprocessing step to a value
    /// - Parameters:
    ///   - step: The postprocessing step to apply
    ///   - value: The value to postprocess
    /// - Returns: The postprocessed value
    func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String
}

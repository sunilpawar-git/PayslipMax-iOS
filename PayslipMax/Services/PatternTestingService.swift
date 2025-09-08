import Foundation
import PDFKit

/// Main service for pattern testing functionality
/// Implements the PatternTestingServiceProtocol and coordinates all pattern testing operations
/// Follows SOLID principles with dependency injection and single responsibility
class PatternTestingService: PatternTestingServiceProtocol {

    // MARK: - Dependencies

    private let textExtractor: TextExtractor
    private let patternManager: PayslipPatternManager
    private let analyticsService: ExtractionAnalyticsProtocol
    private let preprocessingUtils: TextPreprocessingProtocol
    private let postprocessingUtils: TextPostprocessingProtocol

    // MARK: - Pattern Application

    private let patternStrategies: PatternApplicationStrategies

    // MARK: - Initialization

    /// Initialize the pattern testing service with dependencies
    /// - Parameters:
    ///   - textExtractor: Service for extracting text from PDFs
    ///   - patternManager: Manager for pattern registration and matching
    ///   - analyticsService: Service for recording pattern test analytics
    ///   - preprocessingUtils: Utilities for text preprocessing
    ///   - postprocessingUtils: Utilities for value postprocessing
    ///   - patternStrategies: Strategies for applying different pattern types
    init(
        textExtractor: TextExtractor,
        patternManager: PayslipPatternManager,
        analyticsService: ExtractionAnalyticsProtocol,
        preprocessingUtils: TextPreprocessingProtocol = TextPreprocessingUtilities(),
        postprocessingUtils: TextPostprocessingProtocol = TextPostprocessingUtilities(),
        patternStrategies: PatternApplicationStrategies = PatternApplicationStrategies()
    ) {
        self.textExtractor = textExtractor
        self.patternManager = patternManager
        self.analyticsService = analyticsService
        self.preprocessingUtils = preprocessingUtils
        self.postprocessingUtils = postprocessingUtils
        self.patternStrategies = patternStrategies
    }

    // MARK: - PatternTestingServiceProtocol Implementation

    /// Test a pattern against a PDF document
    /// - Parameters:
    ///   - pattern: The pattern definition to test
    ///   - document: The PDF document to test against
    /// - Returns: The extracted value if successful, nil otherwise
    func testPattern(_ pattern: PatternDefinition, against document: PDFDocument) async -> String? {
        // Extract text from the PDF document
        let pdfText = await textExtractor.extractText(from: document)

        // Find value using pattern
        return findValue(with: pattern, in: pdfText)
    }

    /// Save test results for analytics
    /// - Parameters:
    ///   - pattern: The pattern that was tested
    ///   - testValue: The extracted value (nil if extraction failed)
    func saveTestResults(pattern: PatternDefinition, testValue: String?) {
        if let extractedValue = testValue, !extractedValue.isEmpty {
            Task {
                await analyticsService.recordPatternSuccess(patternID: pattern.id, key: pattern.key)
            }
        } else {
            Task {
                await analyticsService.recordPatternFailure(patternID: pattern.id, key: pattern.key)
            }
        }
    }

    // MARK: - Private Methods

    /// Find a value in text using a pattern definition
    /// - Parameters:
    ///   - pattern: The pattern definition to use
    ///   - text: The text to search in
    /// - Returns: The extracted value if found, nil otherwise
    private func findValue(with pattern: PatternDefinition, in text: String) -> String? {
        // Sort patterns by priority (highest first)
        let sortedPatterns = pattern.patterns.sorted { $0.priority > $1.priority }

        // Try each pattern in order of priority
        for extractorPattern in sortedPatterns {
            if let extractedValue = applyPattern(extractorPattern, to: text) {
                return extractedValue
            }
        }

        return nil
    }

    /// Apply a specific extractor pattern to extract a value from text
    /// - Parameters:
    ///   - pattern: The extractor pattern containing pattern definition and processing steps
    ///   - text: The text to process and extract values from
    /// - Returns: The extracted and processed value if successful, otherwise nil
    private func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Apply text preprocessing
        var processedText = text
        for step in pattern.preprocessing {
            processedText = preprocessingUtils.applyPreprocessing(step, to: processedText)
        }

        // Apply the pattern based on its type
        var extractedValue: String?

        switch pattern.type {
        case .regex:
            // Use the pattern manager's extract data functionality for regex patterns
            // Note: We need to access the key from the parent PatternDefinition, not the ExtractorPattern
            // For now, we'll use the pattern manager's extraction directly
            extractedValue = patternStrategies.applyRegexPattern(pattern, to: processedText)

        case .keyword:
            extractedValue = patternStrategies.applyKeywordPattern(pattern, to: processedText)

        case .positionBased:
            extractedValue = patternStrategies.applyPositionBasedPattern(pattern, to: processedText)
        }

        // Apply postprocessing to the extracted value
        if var value = extractedValue {
            for step in pattern.postprocessing {
                value = postprocessingUtils.applyPostprocessing(step, to: value)
            }

            return value
        }

        return nil
    }
}

/// Extension providing convenience methods for pattern testing
extension PatternTestingService {

    /// Test a pattern against text directly (for testing purposes)
    /// - Parameters:
    ///   - pattern: The pattern definition to test
    ///   - text: The text to test against
    /// - Returns: The extracted value if successful, nil otherwise
    func testPattern(_ pattern: PatternDefinition, against text: String) -> String? {
        return findValue(with: pattern, in: text)
    }

    /// Validate that a pattern is properly configured
    /// - Parameter pattern: The pattern to validate
    /// - Returns: True if the pattern is valid for testing
    func isValidPattern(_ pattern: PatternDefinition) -> Bool {
        // Check that pattern has at least one extractor pattern
        guard !pattern.patterns.isEmpty else { return false }

        // Check that all extractor patterns have valid configurations
        for extractorPattern in pattern.patterns {
            if extractorPattern.pattern.isEmpty {
                return false
            }
        }

        return true
    }
}

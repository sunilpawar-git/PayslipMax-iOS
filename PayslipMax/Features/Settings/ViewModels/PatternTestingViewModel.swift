import Foundation
import PDFKit
import Combine

/// View model for pattern testing
class PatternTestingViewModel: ObservableObject {

    // MARK: - Properties

    // Loading state
    @Published var isLoading = false

    // PDF document
    @Published var pdfDocument: PDFDocument?

    // Error handling
    @Published var showError = false
    @Published var errorMessage = ""

    // Test results
    @Published var isTestSuccessful = false

    // Services
    private let patternRepository: PatternRepositoryProtocol
    private let analyticsService: ExtractionAnalyticsProtocol
    private let patternManager: PayslipPatternManager
    private let textExtractor: TextExtractor

    // MARK: - Initialization

    init() {
        // Resolve services from dependency container
        self.patternRepository = AppContainer.shared.resolve(PatternRepositoryProtocol.self)!
        self.analyticsService = AppContainer.shared.resolve(ExtractionAnalyticsProtocol.self)!

        // Initialize the new pattern manager and text extractor
        let patternProvider = AppContainer.shared.resolve(PatternProvider.self) ?? DefaultPatternProvider()
        self.textExtractor = AppContainer.shared.resolve(TextExtractor.self) ?? DefaultTextExtractor(patternProvider: patternProvider)
        let validator = PayslipValidator(patternProvider: patternProvider)
        let builder = PayslipBuilder(patternProvider: patternProvider, validator: validator)

        let patternMatcher = UnifiedPatternMatcher()
        let patternValidator = UnifiedPatternValidator(patternProvider: patternProvider)
        let patternDefinitions = UnifiedPatternDefinitions(patternProvider: patternProvider)

        self.patternManager = PayslipPatternManager(
            patternMatcher: patternMatcher,
            patternValidator: patternValidator,
            patternDefinitions: patternDefinitions,
            payslipBuilder: builder
        )
    }

    // MARK: - PDF Loading

    /// Load a PDF document from a URL
    func loadPDF(from url: URL) {
        isLoading = true

        guard let document = PDFDocument(url: url) else {
            showError(message: "Could not load PDF document")
            isLoading = false
            return
        }

        pdfDocument = document
        isLoading = false
    }

    // MARK: - Pattern Testing

    /// Test a pattern against the loaded PDF document
    @MainActor
    func testPattern(pattern: PatternDefinition, document: PDFDocument) async -> String? {
        isLoading = true
        isTestSuccessful = false

        // Extract text from the PDF document
        let pdfText = await textExtractor.extractText(from: document)

        // Extract value using pattern
        let extractedValue = await extractValueWithPattern(pattern: pattern, from: pdfText)

        isLoading = false
        isTestSuccessful = extractedValue != nil && !extractedValue!.isEmpty

        return extractedValue
    }

    /// Save test results for pattern analytics
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

    /// Extract a value using a specific pattern
    private func extractValueWithPattern(pattern: PatternDefinition, from text: String) async -> String? {
        // First, add this pattern temporarily to the pattern provider
        patternManager.addPattern(key: pattern.key, pattern: pattern.patterns.first?.pattern ?? "")

        // Create a specialized extractor for testing this pattern
        let patternTester = PatternTester(
            pattern: pattern,
            patternManager: patternManager
        )
        return patternTester.findValue(in: text)
    }

    // MARK: - Error Handling

    /// Show an error message
    func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

/// A specialized extractor for testing individual patterns
fileprivate class PatternTester {
    // The pattern to test
    private let pattern: PatternDefinition
    private let patternManager: PayslipPatternManager

    /// Initializes a new PatternTester with the specified pattern definition and pattern manager.
    /// - Parameters:
    ///   - pattern: The pattern definition to test against text data.
    ///   - patternManager: The pattern manager that provides pattern registration and extraction capabilities.
    init(pattern: PatternDefinition, patternManager: PayslipPatternManager) {
        self.pattern = pattern
        self.patternManager = patternManager
    }

    /// Finds a value in the provided text that matches the pattern definition.
    /// Attempts all patterns within the pattern definition in order of priority until a match is found.
    /// - Parameter text: The text to search for pattern matches.
    /// - Returns: The extracted value if a match is found, otherwise nil.
    func findValue(in text: String) -> String? {
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

    /// Applies a specific extractor pattern to extract a value from the text.
    /// This method handles text preprocessing, pattern application, and postprocessing of extracted values.
    /// - Parameters:
    ///   - pattern: The specific extractor pattern containing pattern definition and processing steps.
    ///   - text: The text to process and extract values from.
    /// - Returns: The extracted and processed value if successful, otherwise nil.
    private func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Apply text preprocessing
        var processedText = text
        for step in pattern.preprocessing {
            processedText = applyPreprocessing(step, to: processedText)
        }

        // Apply the pattern based on its type
        var extractedValue: String?

        switch pattern.type {
        case .regex:
            // Use the pattern manager's extract data functionality for regex patterns
            let extractedData = patternManager.extractData(from: processedText)
            extractedValue = extractedData[self.pattern.key]

            // If the pattern manager couldn't extract it, fall back to direct regex
            if extractedValue == nil {
                extractedValue = applyRegexPattern(pattern, to: processedText)
            }

        case .keyword:
            extractedValue = applyKeywordPattern(pattern, to: processedText)

        case .positionBased:
            extractedValue = applyPositionBasedPattern(pattern, to: processedText)
        }

        // Apply postprocessing to the extracted value
        if var value = extractedValue {
            for step in pattern.postprocessing {
                value = applyPostprocessing(step, to: value)
            }

            return value
        }

        return nil
    }

    /// Applies a regular expression pattern to extract a value from text.
    /// Attempts to match the regular expression against the text and returns either
    /// the first capture group or the entire match if no capture groups are defined.
    /// - Parameters:
    ///   - pattern: The extractor pattern containing the regex pattern string.
    ///   - text: The text to apply the regex pattern to.
    /// - Returns: The matched text if a match is found, otherwise nil.
    private func applyRegexPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern.pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            // Return the first capture group or the entire match if no groups
            if let match = matches.first {
                if match.numberOfRanges > 1 {
                    return nsString.substring(with: match.range(at: 1))
                } else {
                    return nsString.substring(with: match.range)
                }
            }
        } catch {
            print("Pattern testing: Regex error - \(error.localizedDescription)")
        }

        return nil
    }

    /// Applies a keyword-based pattern to extract a value from text.
    /// This pattern type looks for a keyword and extracts the text following it,
    /// optionally bounded by a context delimiter.
    /// - Parameters:
    ///   - pattern: The extractor pattern containing the keyword pattern string.
    ///   - text: The text to search for keywords in.
    /// - Returns: The text that follows the keyword, optionally bounded by context, or nil if not found.
    private func applyKeywordPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Split the pattern into before and after keywords
        let components = pattern.pattern.split(separator: "|")

        // Need at least the keyword
        guard !components.isEmpty else { return nil }

        // Extract the parts
        let _ = components.count > 1 ? String(components[0]) : nil
        let keyword = components.count == 1 ? String(components[0]) : String(components[1])
        let contextAfter = components.count > 2 ? String(components[2]) : nil

        // Find the position of the keyword
        guard let keywordRange = text.range(of: keyword, options: .caseInsensitive) else {
            return nil
        }

        // Get the text after the keyword
        let afterKeywordText = text[keywordRange.upperBound...]

        // If there's a contextAfter, extract between the keyword and contextAfter
        if let contextAfter = contextAfter, !contextAfter.isEmpty,
           let afterRange = afterKeywordText.range(of: contextAfter, options: .caseInsensitive) {
            // Extract the value between the keyword and contextAfter
            let extractedValue = afterKeywordText[..<afterRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            return extractedValue
        } else {
            // If no contextAfter, take a reasonable amount of text after the keyword
            let endIndex = afterKeywordText.index(afterKeywordText.startIndex, offsetBy: min(30, afterKeywordText.count))
            let extractedValue = afterKeywordText[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            return extractedValue
        }
    }

    /// Applies a position-based pattern to extract a value from text.
    /// This pattern type extracts text based on line offsets and character positions within lines.
    /// - Parameters:
    ///   - pattern: The extractor pattern containing position parameters as a comma-separated string.
    ///   - text: The text to extract from based on position.
    /// - Returns: The text at the specified position, or nil if the position is invalid.
    private func applyPositionBasedPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse position info from the pattern
        let components = pattern.pattern.split(separator: ",")

        // Extract line offset
        var lineOffset = 0
        var startPosition: Int?
        var endPosition: Int?

        for component in components {
            let parts = component.split(separator: ":")
            if parts.count == 2 {
                let key = String(parts[0])
                if let value = Int(parts[1]) {
                    if key == "lineOffset" {
                        lineOffset = value
                    } else if key == "start" {
                        startPosition = value
                    } else if key == "end" {
                        endPosition = value
                    }
                }
            }
        }

        // Split the text into lines
        let lines = text.split(separator: "\n")

        // Calculate the target line
        let targetLineIndex = lineOffset

        // Ensure the target line is within bounds
        guard targetLineIndex >= 0, targetLineIndex < lines.count else {
            return nil
        }

        // Get the target line
        let line = String(lines[targetLineIndex])

        // If we have both start and end positions, extract that substring
        if let start = startPosition, let end = endPosition, start < end, start < line.count, end <= line.count {
            let startIndex = line.index(line.startIndex, offsetBy: start)
            let endIndex = line.index(line.startIndex, offsetBy: end)
            return String(line[startIndex..<endIndex])
        }

        // Otherwise return the whole line
        return line
    }

    /// Applies preprocessing steps to the input text to standardize it for pattern matching.
    /// - Parameters:
    ///   - step: The preprocessing step to apply.
    ///   - text: The text to preprocess.
    /// - Returns: The preprocessed text with the specified transformations applied.
    private func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        case .normalizeCase:
            return text.lowercased()

        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\\r\\n|\\r", with: "\n", options: .regularExpression)

        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        case .trimLines:
            return text.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }

    /// Applies postprocessing steps to an extracted value to refine and format it.
    /// - Parameters:
    ///   - step: The postprocessing step to apply.
    ///   - value: The extracted value to process.
    /// - Returns: The value after applying the specified postprocessing transformation.
    private func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)

        case .removeNonNumeric:
            return value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        case .uppercase:
            return value.uppercased()

        case .lowercase:
            return value.lowercased()

        case .formatAsCurrency:
            // Remove non-numeric characters except for decimal point and commas
            var numericValue = value.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)

            // Standardize to period as decimal separator
            numericValue = numericValue.replacingOccurrences(of: ",", with: ".")

            // If there are multiple periods, keep only the last one
            let components = numericValue.components(separatedBy: ".")
            if components.count > 2 {
                let integerPart = components.dropLast().joined()
                let decimalPart = components.last ?? ""
                numericValue = integerPart + "." + decimalPart
            }

            return numericValue
        }
    }
}

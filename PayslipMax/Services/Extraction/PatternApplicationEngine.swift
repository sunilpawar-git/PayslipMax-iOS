import Foundation

/// Protocol defining pattern application capabilities for PDF extraction.
///
/// This service handles the core pattern matching and value extraction logic,
/// applying different types of patterns (regex, keyword, position-based) to
/// extract structured data from text content.
protocol PatternApplicationEngineProtocol {
    /// Attempts to find a value in the given text using the patterns defined in a PatternDefinition.
    /// - Parameters:
    ///   - patternDef: The pattern definition containing extraction patterns to try
    ///   - text: The text to search for matches
    /// - Returns: The extracted value if any pattern matches, otherwise nil
    func findValue(for patternDef: PatternDefinition, in text: String) -> String?

    /// Applies a single extractor pattern to the text to extract a value.
    /// - Parameters:
    ///   - pattern: The extraction pattern to apply
    ///   - text: The text to extract from
    /// - Returns: The extracted value if the pattern matches, otherwise nil
    func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String?
}

/// Service responsible for applying extraction patterns to text content.
///
/// This service provides the core pattern matching functionality for the modular PDF extractor.
/// It supports multiple pattern types (regex, keyword, position-based) and handles the complete
/// pattern application pipeline including preprocessing, pattern matching, and postprocessing.
class PatternApplicationEngine: PatternApplicationEngineProtocol {

    /// The preprocessing service used for text transformations
    private let preprocessingService: TextPreprocessingServiceProtocol

    /// Initializes a new pattern application engine with the specified preprocessing service.
    /// - Parameter preprocessingService: The service to handle text preprocessing and postprocessing
    init(preprocessingService: TextPreprocessingServiceProtocol) {
        self.preprocessingService = preprocessingService
    }

    /// Attempts to find a value in the given text using the patterns defined in a PatternDefinition.
    /// It iterates through the patterns in the definition until a match is found.
    /// - Parameters:
    ///   - patternDef: The pattern definition containing extraction patterns to try.
    ///   - text: The text to search for matches.
    /// - Returns: The extracted value if any pattern matches, otherwise nil.
    func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        // Try each pattern in the definition until a match is found
        for pattern in patternDef.patterns {
            if let value = applyPattern(pattern, to: text) {
                return value
            }
        }
        return nil
    }

    /// Applies a single extractor pattern to the text to extract a value.
    ///
    /// This orchestrates the pattern application process:
    /// 1. Applies all defined preprocessing steps to the input text.
    /// 2. Delegates to the appropriate pattern application method based on `pattern.type` (`applyRegexPattern`, `applyKeywordPattern`, `applyPositionBasedPattern`).
    /// 3. Applies all defined postprocessing steps to the extracted value (if any).
    ///
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` containing the extraction rules (type, pattern string, pre/postprocessing steps).
    ///   - text: The raw text content to extract the value from.
    /// - Returns: The extracted and processed string value, or `nil` if the pattern doesn't match or processing fails at any step.
    func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Preprocess text
        var processedText = text
        for step in pattern.preprocessing {
            processedText = preprocessingService.applyPreprocessing(step, to: processedText)
        }

        // Apply the pattern based on type
        var result: String? = nil

        switch pattern.type {
        case .regex:
            result = applyRegexPattern(pattern, to: processedText)
        case .keyword:
            result = applyKeywordPattern(pattern, to: processedText)
        case .positionBased:
            result = applyPositionBasedPattern(pattern, to: processedText)
        }

        // Postprocess the result
        if let extractedValue = result {
            var processedValue = extractedValue
            for step in pattern.postprocessing {
                processedValue = preprocessingService.applyPostprocessing(step, to: processedValue)
            }
            return processedValue
        }

        return result
    }

    /// Applies a regular expression pattern to extract text content.
    ///
    /// Attempts to match the `pattern.pattern` (which is a regex string) against the input `text`.
    /// If the regex matches and contains at least one capture group, the content of the *first* capture group is returned.
    /// If the regex matches but has no capture groups, the entire matched string is returned.
    /// If the regex pattern is invalid or no match is found, `nil` is returned.
    ///
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` of type `.regex` containing the regex definition in `pattern.pattern`.
    ///   - text: The preprocessed text to search within.
    /// - Returns: The content of the first capture group or the entire matched string, trimmed. Returns `nil` if no match is found or if the regex is invalid.
    private func applyRegexPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        let regexPattern = pattern.pattern

        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            // Get the first match with at least one capture group
            if let match = matches.first, match.numberOfRanges > 1 {
                let range = match.range(at: 1) // First capture group
                if range.location != NSNotFound {
                    return nsString.substring(with: range)
                } else if match.numberOfRanges > 0 {
                    // If no capture group, return the entire match
                    return nsString.substring(with: match.range)
                }
            }
        } catch {
            print("PatternApplicationEngine: Regex error - \(error.localizedDescription)")
        }

        return nil
    }

    /// Applies a keyword-based pattern to extract text content.
    ///
    /// The `pattern.pattern` string can be in the format "contextBefore|keyword|contextAfter" or just "keyword".
    /// This method searches the input `text` line by line for a line containing the specified `keyword`.
    /// If `contextBefore` or `contextAfter` are provided in the pattern string, the line must also contain these contexts.
    /// If a matching line is found, the text *after* the keyword on that line is extracted and returned.
    ///
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` of type `.keyword` containing the keyword definition (and optional context) in `pattern.pattern`.
    ///   - text: The preprocessed text, typically split into lines, to search within.
    /// - Returns: The extracted value found immediately after the keyword on a matching line (trimmed), or `nil` if no matching line is found.
    private func applyKeywordPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the pattern to extract keyword and context
        let components = pattern.pattern.split(separator: "|").map(String.init)
        guard !components.isEmpty else { return nil }

        let keyword = components.count > 1 ? components[1] : components[0]
        let contextBefore = components.count > 2 ? components[0] : nil
        let contextAfter = components.count > 2 ? components[2] : nil

        // Split text into lines
        let lines = text.components(separatedBy: .newlines)

        // Find lines containing the keyword
        for line in lines {
            if line.contains(keyword) {
                // Check context if needed
                if let beforeCtx = contextBefore, !line.contains(beforeCtx) {
                    continue
                }
                if let afterCtx = contextAfter, !line.contains(afterCtx) {
                    continue
                }

                // Extract the value after the keyword
                if let range = line.range(of: keyword), range.upperBound < line.endIndex {
                    let afterText = String(line[range.upperBound...])
                    return afterText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
        }

        return nil
    }

    /// Applies a position-based pattern to extract text based on line and character positions.
    ///
    /// Parses the `pattern.pattern` string which should contain comma-separated directives like "lineOffset:N", "start:M", "end:P".
    /// It locates the target line in the input `text` based on the `lineOffset` relative to the current line being processed (implementation detail depends on caller, often assumes iteration over lines).
    /// If `start` and `end` positions are provided, it extracts the substring within those character indices (0-based) from the target line.
    /// If only `lineOffset` is given, the entire trimmed target line is returned.
    ///
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` of type `.positionBased` containing the position information (e.g., "lineOffset:1,start:10,end:25") in `pattern.pattern`.
    ///   - text: The preprocessed text (usually multi-line) to extract from.
    /// - Returns: The extracted text substring at the specified position, or the entire line if only offset is given. Returns `nil` if the target line or character positions are out of bounds.
    private func applyPositionBasedPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the position info from the pattern
        let posInfoComponents = pattern.pattern.split(separator: ",").map(String.init)

        var lineOffset = 0
        var startPos: Int? = nil
        var endPos: Int? = nil

        for component in posInfoComponents {
            if component.starts(with: "lineOffset:") {
                lineOffset = Int(component.dropFirst("lineOffset:".count)) ?? 0
            } else if component.starts(with: "start:") {
                startPos = Int(component.dropFirst("start:".count))
            } else if component.starts(with: "end:") {
                endPos = Int(component.dropFirst("end:".count))
            }
        }

        // Split text into lines
        let lines = text.components(separatedBy: .newlines)

        // Find the relevant line based on offset
        for (i, _) in lines.enumerated() {
            if i + lineOffset < lines.count && i + lineOffset >= 0 {
                let targetLine = lines[i + lineOffset]

                // Extract substring if positions are provided
                if let start = startPos, let end = endPos,
                   start < targetLine.count, end <= targetLine.count, start <= end {
                    let startIndex = targetLine.index(targetLine.startIndex, offsetBy: start)
                    let endIndex = targetLine.index(targetLine.startIndex, offsetBy: end)
                    return String(targetLine[startIndex..<endIndex])
                } else {
                    return targetLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
        }

        return nil
    }
}

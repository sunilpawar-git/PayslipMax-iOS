import Foundation

// MARK: - Placeholder Types (Ensure these match actual definitions or remove if defined elsewhere)
// These might need to be defined properly or imported if they exist in other files.
/* COMMENTED OUT
enum ExtractionError: Error {
    case pdfTextExtractionFailed
    case patternNotFound
    case valueExtractionFailed
    // Add other extraction-related errors if needed
}
*/

// Assuming ExtractorPattern is defined elsewhere with these nested types
/*
// ... ExtractorPattern placeholder ...
*/

/// A helper struct responsible for applying a single `ExtractorPattern` to text content.
///
/// This includes handling different pattern types (regex, keyword, position),
/// applying preprocessing steps to the input text, and applying postprocessing
/// steps to the extracted value.
struct PatternApplier {

    /// Applies a specific pattern to extract a value from the given text.
    /// - Parameters:
    ///   - pattern: The `ExtractorPattern` defining the extraction logic.
    ///   - text: The text content to extract from.
    /// - Returns: The extracted and postprocessed string value, or `nil` if extraction fails.
    func apply(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Apply preprocessing to the text
        var processedText = text
        for step in pattern.preprocessing {
            processedText = applyPreprocessing(step, to: processedText)
        }
        
        // Extract value based on pattern type
        var extractedValue: String? = nil
        
        switch pattern.type {
        case .regex:
            extractedValue = applyRegexPattern(pattern, to: processedText)
        case .keyword:
            extractedValue = applyKeywordPattern(pattern, to: processedText)
        case .positionBased:
            extractedValue = applyPositionBasedPattern(pattern, to: processedText)
        }
        
        // Apply postprocessing if a value was found
        if var value = extractedValue {
            for step in pattern.postprocessing {
                value = applyPostprocessing(step, to: value)
            }
            // Final trim after all post-processing
            let finalValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return finalValue.isEmpty ? nil : finalValue
        }
        
        return nil
    }

    // MARK: - Pattern Type Handlers (Private)

    /// Applies a regular expression pattern to the text to extract a value.
    private func applyRegexPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern.pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if match.numberOfRanges > 1, let matchRange = Range(match.range(at: 1), in: text) {
                    return String(text[matchRange])
                } else if let matchRange = Range(match.range, in: text) {
                    return String(text[matchRange])
                }
            }
        } catch {
            // Consider logging the error instead of just printing
            Logger.error("Regex error applying pattern '\\(pattern.pattern)': \\(error.localizedDescription)", category: "PatternExtraction")
        }
        return nil
    }

    /// Applies a keyword-based pattern to the text to extract a value.
    private func applyKeywordPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        let parts = pattern.pattern.split(separator: "|", omittingEmptySubsequences: false).map(String.init) // Keep empty parts
        
        guard !parts.isEmpty else {
             Logger.warning("Keyword pattern string is empty.", category: "PatternExtraction")
             return nil
        }

        let keywordIndex = parts.count > 1 ? 1 : 0 // Keyword is first if no delimiters, second otherwise
        let keyword = parts[keywordIndex]
        let contextBefore = parts.count > 1 ? parts[0] : nil // Can be empty string
        let contextAfter = parts.count > 2 ? parts[2] : nil // Can be empty string

        guard !keyword.isEmpty else {
             Logger.warning("Keyword itself is empty in pattern string: '\\(pattern.pattern)'", category: "PatternExtraction")
             return nil
        }

        var searchRange = text.startIndex..<text.endIndex
        
        while let keywordRange = text.range(of: keyword, options: .caseInsensitive, range: searchRange) {
            
            // --- Start Boundary Logic ---
            var effectiveStartIndex = text.startIndex
            if let cb = contextBefore, !cb.isEmpty {
                 // Search backwards from the start of the keyword match
                 if let beforeRange = text[..<keywordRange.lowerBound].range(of: cb, options: [.backwards, .caseInsensitive]) {
                      effectiveStartIndex = beforeRange.upperBound
                 } else {
                      // ContextBefore not found, this isn't the right match, continue searching
                      searchRange = keywordRange.upperBound..<text.endIndex
                      continue
                 }
            } else {
                 // No ContextBefore, start immediately after the keyword
                 effectiveStartIndex = keywordRange.upperBound
            }

            // --- End Boundary Logic ---
            var effectiveEndIndex = text.endIndex
             if let ca = contextAfter, !ca.isEmpty {
                  // Search forwards from the end of the keyword match
                  if let afterRange = text[keywordRange.upperBound...].range(of: ca, options: .caseInsensitive) {
                      effectiveEndIndex = afterRange.lowerBound
                  } else {
                      // ContextAfter not found, this might be okay if it's the end of the text, or wrong match
                      // For simplicity, let's assume it's the end if contextAfter is required but not found
                      // A more robust implementation might require contextAfter if specified.
                      // If contextAfter wasn't found, this keyword instance might be wrong.
                      // Let's continue searching for other keyword instances.
                      searchRange = keywordRange.upperBound..<text.endIndex
                      continue
                  }
             } else {
                 // No ContextAfter, try to find the end of the line or reasonable boundary
                 if let lineEndRange = text.rangeOfCharacter(from: .newlines, options: [], range: keywordRange.upperBound..<text.endIndex) {
                    effectiveEndIndex = lineEndRange.lowerBound
                 } else {
                    // No newline found, extends to end of text
                    effectiveEndIndex = text.endIndex
                 }
             }
            
             // Ensure start is before end
             guard effectiveStartIndex < effectiveEndIndex else {
                 // This can happen if contexts overlap or keyword is at the very end. Continue searching.
                 searchRange = keywordRange.upperBound..<text.endIndex
                 continue
             }

             // Extract the value
             let extracted = String(text[effectiveStartIndex..<effectiveEndIndex])
             return extracted // Found a valid match, return it

        } // end while

        return nil // Keyword or required context not found
    }

    /// Applies a position-based pattern to the text to extract a value.
    private func applyPositionBasedPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        let parts = pattern.pattern.split(separator: ",")
        var lineOffset: Int?
        var startPosition: Int?
        var endPosition: Int?
        var baseLineKeyword: String? // Optional keyword to find the base line

        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespaces)
            if trimmedPart.starts(with: "lineOffset:"), let offset = Int(trimmedPart.dropFirst("lineOffset:".count)) {
                lineOffset = offset
            } else if trimmedPart.starts(with: "start:"), let start = Int(trimmedPart.dropFirst("start:".count)) {
                startPosition = start
            } else if trimmedPart.starts(with: "end:"), let end = Int(trimmedPart.dropFirst("end:".count)) {
                endPosition = end
            } else if trimmedPart.starts(with: "baseLineKeyword:"), !trimmedPart.dropFirst("baseLineKeyword:".count).isEmpty {
                baseLineKeyword = String(trimmedPart.dropFirst("baseLineKeyword:".count))
            }
        }

        guard let lo = lineOffset else {
            Logger.warning("Position pattern missing 'lineOffset': \(pattern.pattern)", category: "PatternExtraction")
            return nil
        }

        let lines = text.components(separatedBy: .newlines)
        var baseLineIndex = -1 // Default to -1, meaning no specific base line found yet

        if let keyword = baseLineKeyword {
            // Find the first line containing the keyword
            baseLineIndex = lines.firstIndex { $0.localizedCaseInsensitiveContains(keyword) } ?? -1
             if baseLineIndex == -1 {
                 // Keyword not found, cannot apply relative offset
                 Logger.debug("Base line keyword '\\(keyword)' not found for position pattern.", category: "PatternExtraction")
                 return nil
             }
        } else {
             // If no keyword, should we default to line 0? Or is pattern invalid?
             // Assuming for now we *might* allow absolute positioning from start (baseLineIndex=0)
             // Let's assume the pattern applies relative to the *first* line if no keyword given.
             // This behaviour might need clarification based on requirements.
             baseLineIndex = 0 // Default base index if no keyword specified
        }
        
        let targetIndex = baseLineIndex + lo

        guard targetIndex >= 0 && targetIndex < lines.count else {
            Logger.debug("Target line index \(targetIndex) out of bounds (0..<\(lines.count)) for position pattern.", category: "PatternExtraction")
            return nil // Target line index is out of bounds
        }

        let targetLine = lines[targetIndex]

        // If no specific positions, return the entire line (trimmed)
        guard let start = startPosition, let end = endPosition else {
            return targetLine.trimmingCharacters(in: .whitespaces)
        }

        // Validate positions
        guard start >= 0, end > start, end <= targetLine.count else {
             Logger.warning("Invalid start/end positions (\(start)..<\(end)) for line length \(targetLine.count). Line: '\\(targetLine)'", category: "PatternExtraction")
             return nil // Invalid range
        }

        let startIndex = targetLine.index(targetLine.startIndex, offsetBy: start)
        let endIndex = targetLine.index(targetLine.startIndex, offsetBy: end)
        return String(targetLine[startIndex..<endIndex])
    }

    // MARK: - Preprocessing Methods (Private)

    /// Applies a specific preprocessing step to the text.
    private func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
         // Logger.debug("Applying preprocessing: \(step)", category: "PatternExtraction")
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n")
                       .replacingOccurrences(of: "\r", with: "\n")
        case .normalizeCase:
            return text.lowercased()
        case .removeWhitespace: // Removes ALL whitespace
            return text.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        case .normalizeSpaces: // Replaces multiple spaces/newlines with a single space
            return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        case .trimLines:
            return text.components(separatedBy: .newlines)
                       .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                       .joined(separator: "\n")
        }
    }

    // MARK: - Postprocessing Methods (Private)

    /// Applies a specific postprocessing step to the extracted value.
    private func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        // Logger.debug("Applying postprocessing: \(step) to value: '\(value)'", category: "PatternExtraction")
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            return formatAsCurrency(value) ?? value // Return original if formatting fails
        case .removeNonNumeric:
            // Keep decimal points and potential negative sign at the start
            let sign = value.starts(with: "-") ? "-" : ""
            let numericPart = value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            // Avoid multiple decimal points if possible (simple approach)
            let components = numericPart.split(separator: ".")
            let processedNumeric = components.prefix(2).joined(separator: ".")
            return sign + processedNumeric
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }

    /// Format a string potentially representing a number as currency (INR).
    private func formatAsCurrency(_ value: String) -> String? {
        // Enhanced cleaning: Remove currency symbols, commas, spaces first
        let cleanedValue = value
            .replacingOccurrences(of: "[₹, ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for negative sign
        let isNegative = cleanedValue.starts(with: "-")
        let absoluteValueString = isNegative ? String(cleanedValue.dropFirst()) : cleanedValue
        
        // Validate if it's a number after cleaning
        guard let number = Double(absoluteValueString), number >= 0 else {
            // If it's not a valid positive number after cleaning, return nil
             Logger.warning("Could not format '\\(value)' as currency.", category: "PatternExtraction")
            return nil
        }

        let actualNumber = isNegative ? -number : number
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹" // Assuming INR
        formatter.locale = Locale(identifier: "en_IN") // Use locale for appropriate formatting
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2 // Ensure two decimal places

        return formatter.string(from: NSNumber(value: actualNumber))
    }
}

// Logger placeholder if not globally available
/* COMMENTED OUT
#if DEBUG
struct Logger {
    static func debug(_ message: String, category: String?) { print("[DEBUG][\(category ?? "")] \(message)") }
    static func warning(_ message: String, category: String?) { print("[WARN][\(category ?? "")] \(message)") }
    static func error(_ message: String, category: String?) { print("[ERROR][\(category ?? "")] \(message)") }
}
#else
struct Logger {
    static func debug(_ message: String, category: String?) {}
    static func warning(_ message: String, category: String?) {}
    static func error(_ message: String, category: String?) {}
}
#endif
*/ 
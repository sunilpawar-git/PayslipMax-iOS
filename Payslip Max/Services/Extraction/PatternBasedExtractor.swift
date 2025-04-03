import Foundation
import PDFKit

/// A service for extracting data from PDFs using pattern definitions
class PatternBasedExtractor {
    
    // MARK: - Properties
    
    private let patternRepository: PatternRepositoryProtocol
    
    // MARK: - Initialization
    
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
    }
    
    // MARK: - Extraction Methods
    
    /// Extract all data from PDF document using patterns
    func extractData(from pdfDocument: PDFDocument) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Get all patterns to use for extraction
        let patterns = await patternRepository.getAllPatterns()
        
        // Create a dictionary to store the extracted values
        var extractedData: [String: String] = [:]
        
        // Process each pattern and extract values
        for pattern in patterns {
            if let extractedValue = findValue(for: pattern, in: pdfText) {
                extractedData[pattern.key] = extractedValue
            }
        }
        
        return extractedData
    }
    
    /// Extract data for specific categories from PDF
    func extractData(from pdfDocument: PDFDocument, for categories: [PatternCategory]) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Create a dictionary to store the extracted values
        var extractedData: [String: String] = [:]
        
        // Process each category
        for category in categories {
            let patterns = await patternRepository.getPatternsForCategory(category)
            
            // Process each pattern in the category
            for pattern in patterns {
                if let extractedValue = findValue(for: pattern, in: pdfText) {
                    extractedData[pattern.key] = extractedValue
                }
            }
        }
        
        return extractedData
    }
    
    /// Extract text content from PDF document
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var pdfText = ""
        
        // Iterate through each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                pdfText += pageText + "\n"
            }
        }
        
        return pdfText.isEmpty ? nil : pdfText
    }
    
    // MARK: - Pattern Processing
    
    /// Find a value in the text using the given pattern
    private func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        // Sort patterns by priority (highest first)
        let sortedPatterns = patternDef.patterns.sorted { $0.priority > $1.priority }
        
        // Try each pattern in order of priority
        for pattern in sortedPatterns {
            if let extractedValue = applyPattern(pattern, to: text) {
                return extractedValue
            }
        }
        
        return nil
    }
    
    /// Apply a specific pattern to extract a value
    private func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
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
            return value
        }
        
        return nil
    }
    
    // MARK: - Pattern Type Handlers
    
    /// Apply a regex pattern to extract a value
    private func applyRegexPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Create a regular expression
        do {
            let regex = try NSRegularExpression(pattern: pattern.pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            // Look for the first match
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                // Use capture group 1 if available
                if match.numberOfRanges > 1, let matchRange = Range(match.range(at: 1), in: text) {
                    return String(text[matchRange])
                }
                // If no capture group, use the entire match
                else if let matchRange = Range(match.range, in: text) {
                    return String(text[matchRange])
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return nil
    }
    
    /// Apply a keyword pattern to extract a value
    private func applyKeywordPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the pattern
        let parts = pattern.pattern.split(separator: "|")
        
        // Need at least the keyword
        guard parts.count >= 1 else { return nil }
        
        // Extract the parts
        let contextBefore = parts.count > 1 ? String(parts[0]) : nil
        let keyword = parts.count == 1 ? String(parts[0]) : String(parts[1])
        let contextAfter = parts.count > 2 ? String(parts[2]) : nil
        
        // Look for the keyword
        if let keywordRange = text.range(of: keyword, options: .caseInsensitive) {
            // Define the range to extract
            var startIndex = keywordRange.upperBound
            var endIndex = text.endIndex
            
            // If contextAfter is specified, use it to find the end
            if let contextAfter = contextAfter, 
               let endRange = text[startIndex...].range(of: contextAfter) {
                endIndex = endRange.lowerBound
            }
            
            // If contextBefore is specified, use it to find the start
            if let contextBefore = contextBefore,
               let startRange = text[..<keywordRange.lowerBound].range(of: contextBefore, options: .backwards) {
                startIndex = startRange.upperBound
            }
            
            // Extract the value
            if startIndex < endIndex {
                return String(text[startIndex..<endIndex])
            }
        }
        
        return nil
    }
    
    /// Apply a position-based pattern to extract a value
    private func applyPositionBasedPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the pattern
        let parts = pattern.pattern.split(separator: ",")
        
        // Need at least the line offset
        guard let lineOffsetPart = parts.first,
              lineOffsetPart.starts(with: "lineOffset:"),
              let lineOffset = Int(lineOffsetPart.dropFirst("lineOffset:".count)) else {
            return nil
        }
        
        // Extract start and end positions if available
        var startPosition: Int? = nil
        var endPosition: Int? = nil
        
        for part in parts.dropFirst() {
            if part.starts(with: "start:"),
               let start = Int(part.dropFirst("start:".count)) {
                startPosition = start
            } else if part.starts(with: "end:"),
                      let end = Int(part.dropFirst("end:".count)) {
                endPosition = end
            }
        }
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        // Find line with pattern
        for i in 0..<lines.count {
            // Apply the line offset if within bounds
            let targetIndex = i + lineOffset
            if targetIndex >= 0 && targetIndex < lines.count {
                let targetLine = lines[targetIndex]
                
                // Extract value based on positions
                if let start = startPosition, let end = endPosition,
                   start < targetLine.count, end <= targetLine.count, start < end {
                    let startIndex = targetLine.index(targetLine.startIndex, offsetBy: start)
                    let endIndex = targetLine.index(targetLine.startIndex, offsetBy: end)
                    return String(targetLine[startIndex..<endIndex])
                }
                
                // If no specific positions, return the entire line
                return targetLine
            }
        }
        
        return nil
    }
    
    // MARK: - Preprocessing Methods
    
    /// Apply a preprocessing step to the text
    private func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        case .normalizeCase:
            return text.lowercased()
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        case .trimLines:
            return text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }
    
    // MARK: - Postprocessing Methods
    
    /// Apply a postprocessing step to the extracted value
    private func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            return formatAsCurrency(value)
        case .removeNonNumeric:
            return value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }
    
    /// Format a value as currency
    private func formatAsCurrency(_ value: String) -> String {
        // Remove non-numeric characters except for decimal point
        let numericString = value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Try to convert to a number
        if let number = Double(numericString) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.maximumFractionDigits = 2
            
            if let formattedValue = formatter.string(from: NSNumber(value: number)) {
                return formattedValue
            }
        }
        
        // If conversion fails, return the original value
        return value
    }
}

/// Extraction errors
enum ExtractionError: Error {
    case pdfTextExtractionFailed
    case patternNotFound
    case valueExtractionFailed
} 
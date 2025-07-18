import Foundation
import PDFKit

/// A modular implementation of the PDF extractor that breaks the extraction process into discrete stages.
///
/// The ModularPDFExtractor employs a pattern-based approach to extract structured data from PDF documents,
/// with each pattern defined in a repository and applied systematically through a pipeline architecture.
/// This approach offers several advantages over monolithic extraction:
///
/// - **Modularity**: Each extraction pattern can be defined, tested, and maintained independently
/// - **Flexibility**: New patterns can be added without modifying the core extraction logic
/// - **Prioritization**: Patterns can be prioritized to ensure the most reliable patterns are tried first
/// - **Pre/Post-processing**: Each pattern can specify custom text preprocessing and result postprocessing steps
/// - **Category-based extraction**: Patterns are grouped by category (e.g., personal info, financial data) for organized extraction
///
/// The extraction process follows these stages:
/// 1. Text extraction: Convert PDF to text representation
/// 2. Pattern retrieval: Load all patterns from the repository
/// 3. Pattern application: Apply patterns by category, respecting priority
/// 4. Result assembly: Combine extracted values into a structured PayslipItem
/// 5. Validation: Ensure essential data was extracted successfully
///
/// This extractor is designed to handle diverse payslip formats by relying on flexible pattern definitions
/// rather than hardcoded parsing logic.
class ModularPDFExtractor: PDFExtractorProtocol {
    
    /// The repository that stores and provides all extraction patterns.
    ///
    /// This repository is responsible for:
    /// - Storing pattern definitions (regex, keyword, position-based)
    /// - Organizing patterns by category (e.g., personal info, financial data)
    /// - Assigning and tracking pattern priorities
    /// - Providing patterns on demand for the extraction process
    private let patternRepository: PatternRepositoryProtocol
    
    /// Initializes a new modular PDF extractor with the specified pattern repository.
    ///
    /// - Parameter patternRepository: The repository containing all pattern definitions used for extraction.
    ///   This repository provides the patterns that define what data to extract and how to extract it.
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
    }
    
    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        guard let pdfData = pdfDocument.dataRepresentation() else {
            print("ModularPDFExtractor: Failed to get PDF data representation")
            return nil
        }
        
        // ✅ CLEAN: Eliminated DispatchSemaphore - using DispatchGroup for cleaner concurrency
        var result: PayslipItem? = nil
        let group = DispatchGroup()
        
        group.enter()
        Task {
            do {
                result = try await extractData(from: pdfDocument, pdfData: pdfData)
                group.leave()
            } catch {
                print("ModularPDFExtractor: Error extracting payslip data - \(error.localizedDescription)")
                group.leave()
            }
        }
        
        // Wait for result (with timeout to prevent deadlock)
        _ = group.wait(timeout: .now() + 30)
        return result
    }
    
    /// Extracts payslip data from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        // This implementation is a simplified version as we don't have the original PDF data
        print("ModularPDFExtractor: Attempting to extract data from text only")
        
        // Create a dummy PDF document to satisfy the protocol
        let dummyPDF = PDFDocument()
        let dummyPage = PDFPage(image: UIImage())
        if let page = dummyPage {
            dummyPDF.insert(page, at: 0)
        }
        
        // ✅ CLEAN: Eliminated DispatchSemaphore - using DispatchGroup for cleaner concurrency  
        var patterns: [PatternDefinition] = []
        let group = DispatchGroup()
        
        group.enter()
        Task {
            patterns = await patternRepository.getAllPatterns()
            group.leave()
        }
        
        // Wait with timeout
        _ = group.wait(timeout: .now() + 10)
        
        if patterns.isEmpty {
            print("ModularPDFExtractor: Error - No patterns loaded")
            return nil
        }
        
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority (using a simple method, not the SortComparator which is causing issues)
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: text) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Extract and convert numeric values
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("ModularPDFExtractor: Insufficient data extracted from text")
            return nil
        }
        
        // Create a dummy PDF data for the payslip
        let dummyData = Data()
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: dummyData
        )
        
        return payslip
    }
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        return extractTextFromPDF(pdfDocument) ?? ""
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return ["ModularParser"]
    }
    
    /// Extract data from a PDF document and return a PayslipItem
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract data from
    ///   - pdfData: The raw data representation of the PDF document
    /// - Returns: A PayslipItem containing the extracted data
    /// - Throws: A ModularExtractionError if extraction fails at any stage
    func extractData(from pdfDocument: PDFDocument, pdfData: Data) async throws -> PayslipItem {
        // Log PDF details for debugging
        logPdfDetails(pdfDocument)
        
        // Extract text from the PDF document
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            print("ModularPDFExtractor: Failed to extract text from PDF")
            throw ModularExtractionError.pdfTextExtractionFailed
        }
        
        print("ModularPDFExtractor: Extracted \(pdfText.count) characters from PDF")
        
        // Stage 1: Get all patterns from the repository
        let patterns = await patternRepository.getAllPatterns()
        print("ModularPDFExtractor: Loaded \(patterns.count) patterns")
        
        // Stage 2: Process patterns against the PDF text
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        print("ModularPDFExtractor: Processing patterns by category")
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: pdfText) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Stage 3: Create a PayslipItem from the extracted data
        print("ModularPDFExtractor: Creating PayslipItem from extracted data")
        
        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Extract and convert numeric values
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("ModularPDFExtractor: Insufficient data extracted")
            throw ModularExtractionError.insufficientData
        }
        
        // Extract earnings and deductions if available
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Add entries with "earning_" or "deduction_" prefix
        for (key, value) in data {
            if key.starts(with: "earning_") {
                let amount = extractDouble(from: value)
                let earningName = String(key.dropFirst("earning_".count))
                earnings[earningName] = amount
            } else if key.starts(with: "deduction_") {
                let amount = extractDouble(from: value)
                let deductionName = String(key.dropFirst("deduction_".count))
                deductions[deductionName] = amount
            }
        }
        
        // If no detailed earnings, add a total
        if earnings.isEmpty && credits > 0 {
            earnings["Total Earnings"] = credits
        }
        
        // If no detailed deductions, add defaults
        if deductions.isEmpty && (debits > 0 || tax > 0 || dsop > 0) {
            if tax > 0 {
                deductions["Tax"] = tax
            }
            if dsop > 0 {
                deductions["DSOP"] = dsop
            }
            if debits > 0 && debits > (tax + dsop) {
                deductions["Other Deductions"] = debits - (tax + dsop)
            }
        }
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData
        )
        
        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("ModularPDFExtractor: Successfully created PayslipItem")
        return payslip
    }
    
    /// Retrieves the priority value of a pattern definition.
    /// Higher values indicate higher priority.
    /// - Parameter pattern: The pattern definition to get the priority from.
    /// - Returns: The priority value of the first pattern in the definition, or 0 if none exists.
    private func getPatternPriority(_ pattern: PatternDefinition) -> Int {
        // Return the priority of the first pattern, or a default value
        return pattern.patterns.first?.priority ?? 0
    }
    
    /// Extracts all text content from a PDF document, concatenating text from all pages.
    /// - Parameter pdfDocument: The PDF document to extract text from.
    /// - Returns: A string containing all text from the document, or nil if no text could be extracted.
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var allText = ""
        
        // Iterate through all pages
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                allText += pageText + "\n"
            }
        }
        
        return allText.isEmpty ? nil : allText
    }
    
    /// Attempts to find a value in the given text using the patterns defined in a PatternDefinition.
    /// It iterates through the patterns in the definition until a match is found.
    /// - Parameters:
    ///   - patternDef: The pattern definition containing extraction patterns to try.
    ///   - text: The text to search for matches.
    /// - Returns: The extracted value if any pattern matches, otherwise nil.
    private func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
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
    private func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Preprocess text
        var processedText = text
        for step in pattern.preprocessing {
            processedText = applyPreprocessing(step, to: processedText)
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
                processedValue = applyPostprocessing(step, to: processedValue)
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
            print("ModularPDFExtractor: Regex error - \(error.localizedDescription)")
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
        guard components.count > 0 else { return nil }
        
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
    
    /// Applies a specific preprocessing step to the input text.
    ///
    /// This method transforms the input text based on the specified `step`. Supported transformations include:
    /// - `normalizeNewlines`: Standardizes all newline characters (\r\n, \r) to \n.
    /// - `normalizeCase`: Converts the entire text to lowercase.
    /// - `removeWhitespace`: Removes all whitespace characters (spaces, tabs, newlines).
    /// - `normalizeSpaces`: Replaces sequences of multiple whitespace characters with a single space.
    /// - `trimLines`: Trims leading/trailing whitespace from each line individually.
    ///
    /// This preprocessing pipeline ensures consistent text formatting before pattern application,
    /// increasing the reliability of extraction patterns across different document formats.
    ///
    /// - Parameters:
    ///   - step: The `ExtractorPattern.PreprocessingStep` enum case specifying the transformation to apply.
    ///   - text: The text to preprocess.
    /// - Returns: The text after applying the specified preprocessing step.
    private func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        case .normalizeCase:
            return text.lowercased()
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        case .trimLines:
            return text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }
    
    /// Applies a specific postprocessing step to the extracted value.
    ///
    /// This method transforms the extracted string value based on the specified `step`. Supported transformations include:
    /// - `trim`: Removes leading and trailing whitespace and newlines.
    /// - `formatAsCurrency`: Attempts to parse the string as a Double (after removing non-numeric characters except '.') and formats it using the current locale's currency style. If parsing fails, returns the original string.
    /// - `removeNonNumeric`: Removes all characters except digits (0-9) and the period (.).
    /// - `uppercase`: Converts the string to uppercase.
    /// - `lowercase`: Converts the string to lowercase.
    ///
    /// The postprocessing pipeline enables the refinement of extracted values, ensuring they are
    /// properly formatted for use in the PayslipItem model. This improves data consistency
    /// and reduces the need for downstream processing/formatting.
    ///
    /// - Parameters:
    ///   - step: The `ExtractorPattern.PostprocessingStep` enum case specifying the transformation to apply.
    ///   - value: The extracted string value to postprocess.
    /// - Returns: The value after applying the specified postprocessing step.
    private func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            if let amount = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: NSNumber(value: amount)) ?? value
            }
            return value
        case .removeNonNumeric:
            return value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }
    
    /// Extracts a numerical (Double) value from a string.
    ///
    /// This utility function attempts to convert a string into a Double representation.
    /// It first cleans the string by removing any characters that are not digits (0-9) or a period (.) using a regular expression.
    /// Then, it attempts to initialize a Double from the cleaned string.
    ///
    /// - Parameter string: The string possibly containing a numerical value (e.g., "Rs. 1,234.56", "$5000").
    /// - Returns: The extracted Double value if the cleaned string is a valid number, otherwise `0.0`.
    private func extractDouble(from string: String) -> Double {
        // Remove currency symbols, commas, spaces
        let cleaned = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0.0
    }
    
    /// Logs detailed information about the provided PDF document for debugging purposes.
    ///
    /// This function prints diagnostic information to the console, including:
    /// - The size of the PDF data in bytes.
    /// - The total number of pages in the document.
    /// - For each page: its dimensions (width x height) based on the media box.
    /// - For each page: the number of characters extracted or a message indicating no text content was found.
    ///
    /// This is useful for understanding the structure and content characteristics of a PDF during development or troubleshooting.
    ///
    /// - Parameter pdfDocument: The `PDFDocument` instance to analyze and log details for.
    private func logPdfDetails(_ pdfDocument: PDFDocument) {
        let pdfData = pdfDocument.dataRepresentation()
        print("ModularPDFExtractor: PDF data size: \(pdfData?.count ?? 0) bytes")
        print("ModularPDFExtractor: PDF has \(pdfDocument.pageCount) pages")
        
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                print("ModularPDFExtractor: Page \(i+1) size: \(pageRect.size.width) x \(pageRect.size.height)")
                
                if let text = page.string, !text.isEmpty {
                    print("ModularPDFExtractor: Page \(i+1) has \(text.count) characters of text")
                } else {
                    print("ModularPDFExtractor: Page \(i+1) has no text content")
                }
            }
        }
    }
}

/// Custom error types encountered during the modular PDF extraction process.
enum ModularExtractionError: Error {
    /// Indicates that the provided PDF data is invalid, corrupted, or cannot be opened.
    case invalidPdf
    /// Indicates that text content could not be successfully extracted from the PDF document.
    case pdfTextExtractionFailed
    /// Indicates that despite successful text extraction, no defined patterns matched the content.
    case patternMatchingFailed
    /// Indicates that essential data fields (like month, year, credits) could not be extracted, 
    /// making the resulting PayslipItem invalid.
    case insufficientData
}